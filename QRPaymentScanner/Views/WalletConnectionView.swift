//
//  WalletConnectionView.swift
//  QRPaymentScanner
//
//  Simple wallet connection with Braavos and Ready Wallet
//

import SwiftUI
import ReownAppKit
import Combine

struct WalletConnectionView: View {
    @StateObject private var connectionManager = WalletConnectionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if connectionManager.isConnected {
                    // Connected State
                    connectedView
                } else {
                    // Disconnected State
                    disconnectedView
                }
            }
            .padding()
            .navigationTitle("Connect Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var disconnectedView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 12) {
                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("Connect Your Wallet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Choose a wallet to connect to Starknet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Wallet Buttons
            VStack(spacing: 16) {
                // Ready Wallet Button
                Button(action: {
                    Task {
                        await connectionManager.connectReadyWallet()
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ready Wallet")
                                .font(.headline)
                            Text("Recommended")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.3), radius: 10)
                }
                
                // Braavos Button
                Button(action: {
                    Task {
                        await connectionManager.connectBraavos()
                    }
                }) {
                    HStack {
                        Image(systemName: "shield.fill")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Braavos")
                                .font(.headline)
                            Text("Smart Wallet")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: .orange.opacity(0.3), radius: 10)
                }
            }
            .padding(.horizontal)
            
            if connectionManager.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }
            
            if let error = connectionManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Spacer()
        }
    }
    
    private var connectedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Wallet Connected!")
                .font(.title2)
                .fontWeight(.bold)
            
            // Address Display
            VStack(spacing: 8) {
                Text("Address")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatAddress(connectionManager.connectedAddress))
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            // Disconnect Button
            Button(action: {
                Task {
                    await connectionManager.disconnect()
                }
            }) {
                Text("Disconnect")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private func formatAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        return "\(address.prefix(6))...\(address.suffix(4))"
    }
}

// MARK: - Wallet Connection Manager
class WalletConnectionManager: ObservableObject {
    static let shared = WalletConnectionManager()
    
    @Published var isConnected = false
    @Published var connectedAddress = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var availableWallets: [Wallet] = []
    
    private let readyWalletId = "bc949c5d968ae81310268bf9193f9c9fb7bb4e1283e1284af8f2bd4992535fd6"
    private let braavosId = "braavos"
    
    private var sessionTopic: String?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        subscribeToSessions()
        loadAvailableWallets()
    }
    
    private func loadAvailableWallets() {
        // Get wallets from AppKit
        Task { @MainActor in
            // This will show us which wallets AppKit knows about
            print("🔍 DEBUG: Checking available wallets from AppKit...")
            
            // Try to get wallet configurations from AppKit
            // Note: We'll need to check the actual available wallets
            self.debugPrintWalletInfo()
        }
    }
    
    @MainActor
    private func debugPrintWalletInfo() {
        print(String(repeating: "=", count: 60))
        print("📱 WALLET DEBUG INFO")
        print(String(repeating: "=", count: 60))
        
        // Check if we can access wallet list from AppKit's configuration
        // This will help us see what wallets are configured
        print("Ready Wallet ID: \(readyWalletId)")
        print("Braavos ID: \(braavosId)")
        print(String(repeating: "=", count: 60))
    }
    
    private func subscribeToSessions() {
        // Listen for session settlements
        AppKit.instance.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                Task { @MainActor in
                    self?.handleSessionSettled(session)
                }
            }
            .store(in: &cancellables)
        
        // Listen for session deletions
        AppKit.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (topic, _) in
                Task { @MainActor in
                    if topic == self?.sessionTopic {
                        self?.handleDisconnection()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func connectReadyWallet() async {
        await connectWallet(walletId: readyWalletId, name: "Ready Wallet")
    }
    
    @MainActor
    func connectBraavos() async {
        await connectWallet(walletId: braavosId, name: "Braavos")
    }
    
    @MainActor
    private func connectWallet(walletId: String, name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔗 Connecting to \(name)...")
            
            // Determine the universal link for the wallet
            let universalLink: String?
            if walletId == readyWalletId {
                // Ready Wallet uses its own universal link
                universalLink = "https://walletconnect.ready.io"
            } else if walletId == braavosId {
                // Braavos uses starknet.app.link universal link
                universalLink = "https://braavos.app"
            } else {
                universalLink = nil
            }
            
            print("🌐 Using universal link: \(universalLink ?? "none")")
            
            // Use AppKit's connect with the universal link
            let uri = try await AppKit.instance.connect(walletUniversalLink: universalLink)
            
            if let pairingURI = uri {
                print("✅ Pairing URI: \(pairingURI.absoluteString)")
                print("📱 Topic: \(pairingURI.topic)")
                print("🔗 Deeplink URI: \(pairingURI.deeplinkUri)")
                
                // Build the proper deeplink for each wallet
                var walletURL: URL?
                
                if walletId == readyWalletId {
                    // Try Ready Wallet's custom scheme
                    let schemes = [
                        "readywallet://wc?uri=\(pairingURI.deeplinkUri)",
                        "ready-wallet://wc?uri=\(pairingURI.deeplinkUri)",
                        "https://ready.io/wc?uri=\(pairingURI.deeplinkUri)"
                    ]
                    
                    for scheme in schemes {
                        if let url = URL(string: scheme) {
                            let canOpen = UIApplication.shared.canOpenURL(url)
                            print(canOpen ? "✅ Can open: \(scheme)" : "❌ Cannot open: \(scheme)")
                            if canOpen {
                                walletURL = url
                                break
                            }
                        }
                    }
                    
                    // Fallback to direct scheme
                    if walletURL == nil {
                        print("⚠️ Using fallback URL for Ready Wallet")
                        walletURL = URL(string: schemes[0])
                    }
                    
                } else if walletId == braavosId {
                    // Braavos uses starknet: URLs or universal links
                    let schemes = [
                        "https://braavos.app/wc?uri=\(pairingURI.deeplinkUri)",
                        "braavos://wc?uri=\(pairingURI.deeplinkUri)",
                        "https://starknet.app.link/wc?uri=\(pairingURI.deeplinkUri)"
                    ]
                    
                    for scheme in schemes {
                        if let url = URL(string: scheme) {
                            let canOpen = UIApplication.shared.canOpenURL(url)
                            print(canOpen ? "✅ Can open: \(scheme)" : "❌ Cannot open: \(scheme)")
                            if canOpen {
                                walletURL = url
                                break
                            }
                        }
                    }
                    
                    // Fallback
                    if walletURL == nil {
                        print("⚠️ Using fallback URL for Braavos")
                        walletURL = URL(string: schemes[0])
                    }
                }
                
                // Open the wallet
                if let url = walletURL {
                    print("📱 Opening wallet with: \(url.absoluteString)")
                    let opened = await UIApplication.shared.open(url)
                    print(opened ? "✅ Successfully opened wallet" : "❌ Failed to open wallet")
                    sessionTopic = pairingURI.topic
                } else {
                    throw NSError(domain: "WalletConnection", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "Could not create wallet URL"
                    ])
                }
            } else {
                // If URI is nil, AppKit might be using link mode
                print("⚠️ No URI returned - might be using link mode")
                // Try to launch the wallet anyway
                AppKit.instance.launchCurrentWallet()
            }
            
            isLoading = false
        } catch {
            print("❌ Connection failed: \(error.localizedDescription)")
            errorMessage = "Failed to connect: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    @MainActor
    func disconnect() async {
        guard let topic = sessionTopic else {
            isConnected = false
            connectedAddress = ""
            return
        }
        
        do {
            try await AppKit.instance.disconnect(topic: topic)
            handleDisconnection()
        } catch {
            print("❌ Disconnect failed: \(error.localizedDescription)")
            errorMessage = "Failed to disconnect: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func handleSessionSettled(_ session: Session) {
        print("✅ Session settled!")
        
        // Extract Starknet address from session
        if let starknetNamespace = session.namespaces["starknet"],
           let firstAccount = starknetNamespace.accounts.first {
            let address = firstAccount.address
            
            connectedAddress = address
            isConnected = true
            sessionTopic = session.topic
            errorMessage = nil
            
            // Update StarknetManager
            StarknetManager.shared.connectReadOnlyWallet(address: address)
            
            print("🎉 Connected to address: \(address)")
        }
    }
    
    @MainActor
    private func handleDisconnection() {
        print("🔌 Wallet disconnected")
        isConnected = false
        connectedAddress = ""
        sessionTopic = nil
        
        // Disconnect from StarknetManager
        StarknetManager.shared.disconnectWallet()
    }
}
