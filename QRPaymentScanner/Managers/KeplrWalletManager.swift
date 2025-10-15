import Foundation
import WalletConnectSign
import UIKit
import Combine

@MainActor
class KeplrWalletManager: ObservableObject {
    // MARK: - Properties
    
    private var signClient: SignClient?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isConnected = false
    @Published var connectedAddress: String?
    @Published var activeSessions: [Session] = []
    
    // MARK: - Initialization
    
    init() {
        setupSignClient()
        subscribeToSessionEvents()
    }
    
    private func setupSignClient() {
        // Use Sign.instance instead of creating a new SignClient
        signClient = Sign.instance
    }
    
    // MARK: - Session Management
    
    private func subscribeToSessionEvents() {
        signClient?.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.handleSessionSettle(session)
            }
            .store(in: &cancellables)
        
        signClient?.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.handleSessionDelete(session)
            }
            .store(in: &cancellables)
    }
    
    private func handleSessionSettle(_ session: Session) {
        isConnected = true
        activeSessions.append(session)
        if let address = session.namespaces.values.first?.accounts.first?.address {
            connectedAddress = address
        }
    }
    
    private func handleSessionDelete(_ session: Session) {
        activeSessions.removeAll { $0.topic == session.topic }
        if activeSessions.isEmpty {
            isConnected = false
            connectedAddress = nil
        }
    }
    
    // MARK: - Connection
    
    func connect() async throws {
        let namespace = ProposalNamespace(
            chains: ["starknet:SN_SEPOLIA"], // Use SN_MAIN for mainnet
            methods: [
                "starknet_requestAccounts",
                "starknet_signMessage",
                "starknet_signTransaction"
            ],
            events: ["accountsChanged", "chainChanged"]
        )
        
        let connectParams = ConnectParams(
            namespaces: ["starknet": namespace]
        )
        
        guard let uri = try await signClient?.connect(params: connectParams) else {
            throw WalletError.failedToGenerateURI
        }
        
        // Create Keplr deep link with WalletConnect URI
        let keplrURL = "keplrwallet://wcV2?uri=\(uri.absoluteString)"
        guard let url = URL(string: keplrURL) else {
            throw WalletError.invalidURL
        }
        
        // Open Keplr wallet
        if await UIApplication.shared.canOpenURL(url) {
            await UIApplication.shared.open(url)
        } else {
            throw WalletError.walletNotInstalled
        }
    }
    
    // MARK: - Signing
    
    func signTransaction(_ transaction: StarknetTransaction) async throws -> String {
        guard let session = activeSessions.first else {
            throw WalletError.noActiveSession
        }
        
        let request = Request(
            topic: session.topic,
            method: "starknet_signTransaction",
            params: transaction.params,
            chainId: Blockchain("starknet:SN_SEPOLIA")!
        )
        
        let response = try await signClient?.request(params: request)
        return response?.result as? String ?? ""
    }
    
    func disconnect() async throws {
        guard let session = activeSessions.first else { return }
        try await signClient?.disconnect(topic: session.topic, reason: .userDisconnected)
    }
}

// MARK: - Supporting Types

enum WalletError: Error {
    case failedToGenerateURI
    case invalidURL
    case walletNotInstalled
    case noActiveSession
}

struct StarknetTransaction {
    let params: [String: Any]
}