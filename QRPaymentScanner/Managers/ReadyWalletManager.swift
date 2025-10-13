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
        
        isConnecting = true
        errorMessage = ""
        
        defer {
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
        for _ in 0..<30 {
            if connectionStatus == .connected {
                print("✅ Connection successful!")
                return true
            } else if connectionStatus == .disconnected {
                print("❌ Connection failed or rejected")
                return false
            }
            
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        print("⏰ Connection timeout")
        await MainActor.run {
            connectionStatus = .disconnected
            errorMessage = "Connection timeout. Please try again."
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
    
    private func simulateConnection() async -> Bool {
        print("🎭 Simulating connection for demo...")
        
        // Simulate connection delay
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await MainActor.run {
            isConnected = true
            connectedAddress = "0x1234567890abcdef1234567890abcdef12345678"
            publicKey = "0xpublic_key_example"
            walletName = "Ready Wallet"
            errorMessage = ""
        }
        
        print("✅ Simulated connection successful")
        return true
    }
    
    // MARK: - Disconnect
    
    public func disconnect() {
        print("🔌 Disconnecting Ready Wallet...")
        
        isConnected = false
        connectedAddress = ""
        publicKey = ""
        walletName = ""
        errorMessage = ""
        
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
        
        // Parse the URL for wallet response data
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("❌ Invalid URL components")
            return
        }
        
        // Handle different callback types
        if let host = components.host {
            switch host {
            case "connect":
                handleConnectCallback(components: components)
            case "sign":
                handleSignCallback(components: components)
            case "send":
                handleSendCallback(components: components)
            default:
                print("⚠️ Unknown callback type: \(host)")
            }
        }
    }
    
    private func handleConnectCallback(components: URLComponents) {
        guard let queryItems = components.queryItems else {
            print("❌ No query items in connect callback")
            return
        }
        
        var address = ""
        var publicKey = ""
        var name = ""
        
        for item in queryItems {
            switch item.name {
            case "address":
                address = item.value ?? ""
            case "publicKey":
                publicKey = item.value ?? ""
            case "name":
                name = item.value ?? ""
            default:
                break
            }
        }
        
        if !address.isEmpty {
            print("✅ Connection successful!")
            DispatchQueue.main.async {
                self.connectedAddress = address
                self.publicKey = publicKey
                self.walletName = name.isEmpty ? "Ready Wallet" : name
                self.isConnected = true
                self.isConnecting = false
                self.errorMessage = ""
                
                // Resume any waiting connection
                self.connectionContinuation?.resume(returning: true)
                self.connectionContinuation = nil
                self.connectionTimer?.invalidate()
                self.connectionTimer = nil
            }
        } else {
            print("❌ Connection failed - no address provided")
            DispatchQueue.main.async {
                self.errorMessage = "Connection failed"
                self.isConnecting = false
                
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