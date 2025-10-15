//
//  BraavosConnectionManager.swift
//  QRPaymentScanner
//
//  Reown AppKit integration for Braavos wallet
//

import SwiftUI
import Combine
import ReownAppKit

// MARK: - Braavos Error Types
enum BraavosError: Error {
    case notConnected
    case connectionFailed
    case invalidResponse
    case walletNotInstalled
    case userRejected
    case pairingFailed
    
    var localizedDescription: String {
        switch self {
        case .notConnected:
            return "Braavos wallet is not connected"
        case .connectionFailed:
            return "Failed to connect to Braavos wallet"
        case .invalidResponse:
            return "Invalid response from Braavos wallet"
        case .walletNotInstalled:
            return "Braavos wallet is not installed"
        case .userRejected:
            return "User rejected the connection"
        case .pairingFailed:
            return "Failed to create pairing"
        }
    }
}

// MARK: - Braavos Connection Manager
class BraavosConnectionManager: ObservableObject {
    static let shared = BraavosConnectionManager()
    
    @Published var isConnected = false
    @Published var userAddress = ""
    @Published var connectionURI = ""
    @Published var showConnectionSheet = false
    
    private let projectId = "573da76e91a5a1c5c6d81566acfd4c31" // Reown Cloud Project ID
    private var cancellables = Set<AnyCancellable>()
    private var currentPairingTopic: String?
    
    private init() {
        setupConnection()
    }
    
    private func setupConnection() {
        print("✅ BraavosConnectionManager initialized")
        print("🦾 Ready for Braavos wallet connection with WalletConnect")
        
        // Subscribe to session events
        subscribeToSessionEvents()
    }
    
    private func subscribeToSessionEvents() {
        // Listen for new sessions
        AppKit.instance.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.handleSessionSettled(session)
            }
            .store(in: &cancellables)
        
        // Listen for session deletion
        AppKit.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (topic, reason) in
                print("🔌 Session deleted: \(reason)")
                self?.handleDisconnection()
            }
            .store(in: &cancellables)
    }
    
    private func handleSessionSettled(_ session: Session) {
        print("✅ Braavos wallet session settled!")
        print("📋 Session details: \(session)")
        
        // Extract Starknet account from the session
        if let starknetNamespace = session.namespaces["starknet"],
           let firstAccount = starknetNamespace.accounts.first {
            let address = firstAccount.address
            print("📍 Braavos address: \(address)")
            
            self.userAddress = address
            self.isConnected = true
            self.showConnectionSheet = false
            
            // Connect to StarknetManager
            StarknetManager.shared.connectReadOnlyWallet(address: address)
        }
    }
    
    private func handleDisconnection() {
        print("🔌 Braavos wallet disconnected")
        self.isConnected = false
        self.userAddress = ""
        self.connectionURI = ""
        self.currentPairingTopic = nil
    }
    
    // MARK: - Braavos Connection Flow
    
    func connect() async throws {
        print("🦾 Starting Braavos wallet connection with WalletConnect...")
        
        do {
            // Create a pairing URI for WalletConnect
            let pairingURI = try await AppKit.instance.createPairing()
            
            await MainActor.run {
                self.connectionURI = pairingURI.absoluteString
                self.currentPairingTopic = pairingURI.topic
                self.showConnectionSheet = true
                print("✅ Pairing URI created: \(pairingURI.absoluteString)")
                print("📱 Topic: \(pairingURI.topic)")
                print("📱 Display QR code or use deep link to connect")
            }
            
            // The wallet will scan the QR code and establish the session
            // Session will be handled by sessionSettlePublisher
            print("⏳ Waiting for Braavos wallet to scan QR code...")
            
        } catch {
            print("❌ Connection failed: \(error.localizedDescription)")
            throw BraavosError.pairingFailed
        }
    }
    
    // MARK: - Braavos Specific Integration
    
    /// Open Braavos wallet using AppKit's built-in deep linking (RECOMMENDED)
    /// This method handles all the complex deep linking logic automatically
    func openBraavos() {
        print("🦾 Opening Braavos wallet with WalletConnect...")
        
        guard !connectionURI.isEmpty else {
            print("⚠️ No connection URI available - call connect() first")
            return
        }
        
        // Method 1: Use AppKit's built-in deep linking (BEST)
        // AppKit knows the correct format for each wallet and handles universal links
        print("📱 Using AppKit.launchCurrentWallet() - recommended method")
        AppKit.instance.launchCurrentWallet()
    }
    
    /// Alternative method: Manual deep linking using Starknet universal links
    /// Use this only if AppKit.launchCurrentWallet() doesn't work
    func openBraavosManually() {
        print("🦾 Opening Braavos with manual universal link...")
        
        guard !connectionURI.isEmpty else {
            print("⚠️ No connection URI available")
            return
        }
        
        // Use Starknet universal link format (from starknet-deeplink library)
        // This is more reliable than custom URL schemes
        if let encodedURI = connectionURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            let universalLink = "https://starknet.app.link/wc?uri=\(encodedURI)"
            
            if let url = URL(string: universalLink) {
                print("🔗 Opening universal link: \(universalLink)")
                UIApplication.shared.open(url) { success in
                    if success {
                        print("✅ Successfully opened Braavos via universal link")
                    } else {
                        print("❌ Failed to open universal link, trying App Store")
                        self.openAppStore()
                    }
                }
            }
        } else {
            print("❌ Failed to encode WalletConnect URI")
        }
    }
    
    /// Fallback: Try custom URL scheme (legacy method)
    /// This may show "unsupported link" error if not properly registered
    func openBraavosWithCustomScheme() {
        print("🦾 Opening Braavos with custom URL scheme (legacy)...")
        
        guard !connectionURI.isEmpty else {
            print("⚠️ No connection URI available")
            return
        }
        
        // Custom URL scheme format: braavos://wc?uri=<encoded_uri>
        if let encodedURI = connectionURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let braavosURL = URL(string: "braavos://wc?uri=\(encodedURI)") {
            
            if UIApplication.shared.canOpenURL(URL(string: "braavos://")!) {
                print("📱 Opening Braavos with custom scheme")
                UIApplication.shared.open(braavosURL) { success in
                    if success {
                        print("✅ Successfully opened Braavos with custom scheme")
                    } else {
                        print("❌ Custom scheme failed, falling back to universal link")
                        self.openBraavosManually()
                    }
                }
            } else {
                print("⚠️ Braavos not installed, showing App Store")
                openAppStore()
            }
        }
    }
    
    private func openAppStore() {
        // Redirect to Braavos on App Store
        if let url = URL(string: "https://apps.apple.com/app/braavos-starknet-wallet/id6444612175") {
            UIApplication.shared.open(url)
        }
    }
    
    // Get WalletConnect URI for QR code display
    func getWalletConnectURI() -> String {
        return connectionURI
    }
    
    // MARK: - Braavos Request Methods
    
    func requestAccounts() async throws -> [String] {
        guard isConnected else {
            throw BraavosError.notConnected
        }
        
        print("📝 Requesting accounts from Braavos...")
        
        // AppKit handles account requests automatically during connection
        // Return the current connected accounts
        return userAddress.isEmpty ? [] : [userAddress]
    }
    
    func signTransaction(calls: [[String: Any]]) async throws -> [String] {
        guard isConnected else {
            throw BraavosError.notConnected
        }
        
        print("📝 Requesting transaction signature from Braavos...")
        print("📦 Calls: \(calls)")
        
        // TODO: Implement actual signing via Reown AppKit when available
        // For now, return placeholder
        return ["0xmock_signature"]
    }
    
    func disconnect() async {
        print("🔌 Disconnecting from Braavos...")
        
        // Get active sessions and disconnect them
        let sessions = AppKit.instance.getSessions()
        
        for session in sessions {
            do {
                try await AppKit.instance.disconnect(topic: session.topic)
                print("✅ Disconnected session: \(session.topic)")
            } catch {
                print("❌ Failed to disconnect session: \(error)")
            }
        }
        
        await MainActor.run {
            self.handleDisconnection()
        }
    }
    
    // MARK: - QR Code Generation
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .utf8)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let ciImage = filter.outputImage else {
            return nil
        }
        
        // Scale up for better quality
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = ciImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - StarknetManager Integration Helper
extension BraavosConnectionManager {
    func connectToStarknetManager() {
        guard !userAddress.isEmpty else {
            print("⚠️ No address to connect with StarknetManager")
            return
        }
        
        print("🔗 Connecting address to StarknetManager: \(userAddress)")
        StarknetManager.shared.connectReadOnlyWallet(address: userAddress)
    }
}
