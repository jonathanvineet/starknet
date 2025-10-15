//
//  ReadyWalletManager.swift
//  QRPaymentScanner
//
//  Enhanced Ready Wallet integration with universal links and direct app opening
//

import Foundation
import UIKit
import Combine

public enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    case failed
}

@MainActor
public class ReadyWalletManager: ObservableObject {
    public static let shared = ReadyWalletManager()
    
    @Published public var isConnected = false
    @Published public var connectedAddress = ""
    @Published public var isConnecting = false
    @Published public var errorMessage = ""
    @Published public var publicKey = ""
    @Published public var walletName = ""
    @Published public var connectionStatus: ConnectionStatus = .disconnected
    
    private var connectionContinuation: CheckedContinuation<Bool, Never>?
    private var connectionTimer: Timer?
    
    private init() {}
    
    // MARK: - Wallet Detection
    
    public func isReadyWalletInstalled() -> Bool {
        print("🔍 Checking Ready Wallet installation...")
        
        // Check if Ready Wallet URL scheme can be opened
        guard let url = URL(string: "ready://") else {
            print("❌ Invalid URL scheme")
            return false
        }
        
        let canOpen = UIApplication.shared.canOpenURL(url)
        print(canOpen ? "✅ Ready Wallet detected" : "⚠️ Ready Wallet not detected")
        
        return canOpen
    }
    
    // MARK: - Connection Management
    
    public func connectWallet(network: String = "sepolia") async -> Bool {
        print("🚀 Starting Ready Wallet connection with network: \(network)")
        
        // Check if wallet is installed first
        guard isReadyWalletInstalled() else {
            print("❌ Ready Wallet not installed")
            errorMessage = "Ready Wallet is not installed"
            await promptInstallation()
            return false
        }
        
        // Set status to connecting
        connectionStatus = .connecting
        isConnecting = true
        errorMessage = ""
        
        defer {
            if connectionStatus == .connecting {
                connectionStatus = .disconnected
            }
            isConnecting = false
        }
        
        do {
            // Try to open Ready Wallet with network parameter
            if await tryReadyWalletConnection(network: network) {
                return await waitForConnection()
            }
            
            // If direct connection fails, try app store
            if await tryAppStoreConnection() {
                return false // User needs to install first
            }
            
            throw WalletError.connectionFailed
            
        } catch {
            print("❌ Connection error: \(error)")
            errorMessage = "Failed to connect: \(error.localizedDescription)"
            connectionStatus = .failed
            return false
        }
    }
    
    // MARK: - Connection Methods
    
    private func tryReadyWalletConnection(network: String) async -> Bool {
        print("🔗 Attempting Ready Wallet connection with network: \(network)")
        
        // Build proper deep link with network parameter
        let connectionURL = buildConnectionURL(network: network)
        
        print("📱 Opening Ready Wallet with URL: \(connectionURL.absoluteString)")
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                UIApplication.shared.open(connectionURL, options: [:]) { success in
                    if !success {
                        print("❌ Failed to open Ready Wallet")
                        self.errorMessage = "Could not open Ready Wallet"
                    } else {
                        print("✅ Ready Wallet opened successfully")
                    }
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    private func buildConnectionURL(network: String) -> URL {
        // Build proper deep link with network parameter
        var components = URLComponents()
        components.scheme = "ready"
        components.host = "connect"
        
        // Get your app's callback URL
        let callbackURL = "qrpaymentscanner://ready/callback"
        
        components.queryItems = [
            URLQueryItem(name: "network", value: network),
            URLQueryItem(name: "callback", value: callbackURL)
        ]
        
        return components.url ?? URL(string: "ready://connect?network=\(network)")!
    }
    
    private func promptInstallation() async {
        print("📋 Prompting user to install Ready Wallet")
        
        await MainActor.run {
            errorMessage = "Ready Wallet is required. Please install it from the App Store."
        }
        
        // Redirect to App Store
        _ = await tryAppStoreConnection()
    }
    
    private func waitForConnection() async -> Bool {
        print("⏳ Waiting for connection callback...")
        
        // Wait for up to 30 seconds for the connection callback
        for i in 0..<30 {
            if i % 5 == 0 {
                print("⏳ Still waiting... (\(i)s elapsed, status: \(connectionStatusString))")
            }
            
            if connectionStatus == .connected {
                print("✅ Connection successful!")
                return true
            } else if connectionStatus == .failed {
                print("❌ Connection failed or rejected")
                return false
            }
            
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        print("⏰ Connection timeout after 30 seconds")
        await MainActor.run {
            connectionStatus = .failed
            errorMessage = "Connection timeout. Please make sure you approved the connection in Ready Wallet."
        }
        return false
    }
    
    private func tryDirectAppConnection() async -> Bool {
        print("📱 Attempting direct app connection...")
        
        // Try Ready's custom scheme
        let schemes = ["ready://connect", "ready://", "readywallet://connect"]
        
        for scheme in schemes {
            guard let url = URL(string: scheme) else { continue }
            
            let success = await withCheckedContinuation { continuation in
                DispatchQueue.main.async {
                    if UIApplication.shared.canOpenURL(url) {
                        print("✅ Opening Ready Wallet via scheme: \(scheme)")
                        UIApplication.shared.open(url, options: [:]) { result in
                            continuation.resume(returning: result)
                        }
                    } else {
                        continuation.resume(returning: false)
                    }
                }
            }
            
            if success {
                print("✅ Successfully opened with scheme: \(scheme)")
                return true
            }
        }
        
        print("⚠️ Direct app connection failed")
        return false
    }
    
    private func tryAppStoreConnection() async -> Bool {
        print("🏪 Attempting App Store connection...")
        
        // Use Ready Wallet's actual App Store URL
        guard let url = URL(string: "https://apps.apple.com/app/ready-wallet/id6504062205") else {
            print("❌ Invalid App Store URL")
            return false
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                print("📲 Opening App Store for Ready Wallet")
                UIApplication.shared.open(url, options: [:]) { success in
                    print("App Store result: \(success)")
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    private func showManualConnectionInstructions() async {
        print("📋 Showing manual connection instructions")
        
        let message = """
        To connect Ready Wallet:
        
        1. Make sure Ready Wallet is installed
        2. Open Ready Wallet manually
        3. Navigate to DApp connections
        4. Scan the QR code or enter connection details
        5. Approve the connection
        """
        
        await MainActor.run {
            // You might want to show this in a proper alert or view
            errorMessage = message
        }
    }
    
    // MARK: - Disconnect
    
    public func disconnect() {
        print("🔌 Disconnecting Ready Wallet...")
        
        isConnected = false
        connectedAddress = ""
        publicKey = ""
        walletName = ""
        errorMessage = ""
        connectionStatus = .disconnected
        
        print("✅ Disconnected successfully")
    }
    
    // MARK: - Transaction Methods
    
    public func signTransaction(_ transaction: [String: Any]) async throws -> String {
        print("✍️ Signing transaction with Ready Wallet...")
        
        guard isConnected else {
            throw WalletError.notConnected
        }
        
        // In a real implementation, this would communicate with Ready Wallet
        // For now, return a mock signature
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let mockSignature = "0xsignature_mock_\(Date().timeIntervalSince1970)"
        print("✅ Transaction signed: \(mockSignature)")
        
        return mockSignature
    }
    
    public func sendTransaction(_ transaction: [String: Any]) async throws -> String {
        print("📤 Sending transaction via Ready Wallet...")
        
        guard isConnected else {
            throw WalletError.notConnected
        }
        
        // Sign first
        let signature = try await signTransaction(transaction)
        print("📝 Using signature: \(signature)")
        
        // Simulate sending
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        let mockTxHash = "0x\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())"
        print("✅ Transaction sent: \(mockTxHash)")
        
        return mockTxHash
    }
    
    // MARK: - Wallet Display Methods
    
    public func getWalletDisplayName() -> String {
        return walletName.isEmpty ? "Ready Wallet" : walletName
    }
    
    public func openAppStore() {
        Task {
            await tryAppStoreConnection()
        }
    }
    
    // MARK: - URL Callback Handling
    
    public func handleReadyCallback(url: URL) {
        print("🔗 ReadyWalletManager handling callback URL: \(url.absoluteString)")
        print("   Scheme: \(url.scheme ?? "none")")
        print("   Host: \(url.host ?? "none")")
        print("   Path: \(url.path)")
        print("   Query: \(url.query ?? "none")")
        
        // Parse the URL for wallet response data
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("❌ Invalid URL components")
            return
        }
        
        // Debug: Print all query items
        if let queryItems = components.queryItems {
            print("📋 Query items received:")
            for item in queryItems {
                print("   - \(item.name): \(item.value ?? "nil")")
            }
        }
        
        // Handle different callback types
        // Check path for callback type (e.g., /ready/callback)
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        if pathComponents.contains("callback") || url.host == "callback" || url.host == "ready" {
            handleConnectCallback(components: components)
        } else if pathComponents.contains("sign") || url.host == "sign" {
            handleSignCallback(components: components)
        } else if pathComponents.contains("send") || url.host == "send" {
            handleSendCallback(components: components)
        } else {
            print("⚠️ Unknown callback type, treating as connect callback")
            handleConnectCallback(components: components)
        }
    }
    
    private func handleConnectCallback(components: URLComponents) {
        print("🔌 Processing connect callback...")
        
        guard let queryItems = components.queryItems else {
            print("❌ No query items in connect callback")
            DispatchQueue.main.async {
                self.connectionStatus = .failed
                self.errorMessage = "Invalid callback format"
                self.isConnecting = false
            }
            return
        }
        
        var address = ""
        var publicKey = ""
        var name = ""
        var success = false
        
        for item in queryItems {
            switch item.name {
            case "address", "account":
                address = item.value ?? ""
                print("   ✓ Address: \(address)")
            case "publicKey", "public_key":
                publicKey = item.value ?? ""
                print("   ✓ Public Key: \(publicKey.prefix(20))...")
            case "name", "wallet_name":
                name = item.value ?? ""
                print("   ✓ Name: \(name)")
            case "success":
                success = (item.value == "true" || item.value == "1")
                print("   ✓ Success flag: \(success)")
            case "error":
                if let error = item.value {
                    print("   ✗ Error: \(error)")
                    DispatchQueue.main.async {
                        self.errorMessage = error
                    }
                }
            default:
                break
            }
        }
        
        // Check if we have a valid connection
        if !address.isEmpty || success {
            print("✅ Connection callback successful!")
            DispatchQueue.main.async {
                self.connectedAddress = address
                self.publicKey = publicKey
                self.walletName = name.isEmpty ? "Ready Wallet" : name
                self.isConnected = true
                self.isConnecting = false
                self.errorMessage = ""
                
                // 🔥 CRITICAL FIX: Set connectionStatus to .connected
                self.connectionStatus = .connected
                
                print("✅ Connection state updated:")
                print("   - Address: \(self.connectedAddress)")
                print("   - Name: \(self.walletName)")
                print("   - Status: \(self.connectionStatusString)")
                
                // Resume any waiting connection
                self.connectionContinuation?.resume(returning: true)
                self.connectionContinuation = nil
                self.connectionTimer?.invalidate()
                self.connectionTimer = nil
            }
        } else {
            print("❌ Connection callback failed - no address or success flag")
            DispatchQueue.main.async {
                self.errorMessage = self.errorMessage.isEmpty ? "Connection rejected" : self.errorMessage
                self.isConnecting = false
                
                // 🔥 CRITICAL FIX: Set connectionStatus to .failed
                self.connectionStatus = .failed
                
                // Resume any waiting connection
                self.connectionContinuation?.resume(returning: false)
                self.connectionContinuation = nil
                self.connectionTimer?.invalidate()
                self.connectionTimer = nil
            }
        }
    }
    
    private func handleSignCallback(components: URLComponents) {
        print("🖊️ Handling sign callback")
        // Handle signature response
        // This would be implemented based on the actual Ready Wallet callback format
    }
    
    private func handleSendCallback(components: URLComponents) {
        print("📤 Handling send callback")
        // Handle transaction response
        // This would be implemented based on the actual Ready Wallet callback format
    }
}

// MARK: - Wallet Errors

public enum WalletError: LocalizedError {
    case notInstalled
    case notConnected
    case connectionFailed
    case transactionFailed
    case userCancelled
    
    public var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "Ready Wallet is not installed"
        case .notConnected:
            return "Wallet is not connected"
        case .connectionFailed:
            return "Failed to connect to wallet"
        case .transactionFailed:
            return "Transaction failed"
        case .userCancelled:
            return "User cancelled the operation"
        }
    }
}

// MARK: - Extensions

extension ReadyWalletManager {
    public var connectionStatusString: String {
        switch connectionStatus {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected (\(walletName))"
        case .failed:
            return "Connection Failed"
        }
    }
    
    public var shortAddress: String {
        guard !connectedAddress.isEmpty else { return "" }
        let address = connectedAddress
        if address.count > 10 {
            return "\(address.prefix(6))...\(address.suffix(4))"
        }
        return address
    }
}