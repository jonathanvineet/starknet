//
//  ReadyWalletManager.swift
//  QRPaymentScanner
//
//  Enhanced Ready Wallet integration with multiple scheme detection
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
    
    // Try multiple possible URL schemes for Ready/Argent (Ready is formerly Argent)
    // Note: canOpenURL requires these schemes in Info.plist LSApplicationQueriesSchemes (already configured)
    private let possibleSchemes = [
        // Ready (new) app
        "readywallet",
        "ready",
        // Argent (legacy naming but still used by Ready app)
        "argent",
        "argentx",
        "argentmobile",
        // Less-likely/legacy variants as fallback
        "ready-wallet",
        "rwallet"
    ]
    
    private var detectedScheme: String?
    
    private init() {}
    
    // MARK: - Wallet Detection
    
    public func isReadyWalletInstalled() -> Bool {
    print("🔍 Checking Ready/Argent wallet installation...")
        print("   Testing multiple URL schemes...")
        
        // Test all possible schemes
        for scheme in possibleSchemes {
            guard let url = URL(string: "\(scheme)://") else { continue }
            
            if UIApplication.shared.canOpenURL(url) {
                print("✅ Ready Wallet detected with scheme: \(scheme)://")
                detectedScheme = scheme
                return true
            } else {
                print("   ❌ Scheme not available: \(scheme)://")
            }
        }
        
    print("⚠️ No URL scheme detected for Ready/Argent")
        print("💡 This doesn't mean the app isn't installed!")
        print("💡 The app might not register a custom URL scheme")
        
        // Ready Wallet might be installed but not expose a URL scheme
        // We'll try to open it anyway using the universal link
        return false
    }
    
    public func forceDetectWallet() async -> Bool {
        print("🔍 Force detecting Ready Wallet by attempting to open...")
        
        // Try each scheme and see if any successfully opens
        for scheme in possibleSchemes {
            guard let url = URL(string: "\(scheme)://") else { continue }
            
            let opened = await withCheckedContinuation { continuation in
                DispatchQueue.main.async {
                    UIApplication.shared.open(url, options: [:]) { success in
                        if success {
                            print("✅ Successfully opened with scheme: \(scheme)://")
                            self.detectedScheme = scheme
                        }
                        continuation.resume(returning: success)
                    }
                }
            }
            
            if opened {
                return true
            }
        }
        
        print("⚠️ Could not open with any known URL scheme")
        return false
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
        connectionStatus = .connecting
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
        
        // Strategy 1: Try detected scheme
        if let scheme = detectedScheme {
            print("   Trying detected scheme: \(scheme)://")
            if await tryOpenWithScheme(scheme, network: network) {
                return true
            }
        }
        
        // Strategy 2: Try all possible schemes
        print("   Trying all possible schemes...")
        for scheme in possibleSchemes {
            if await tryOpenWithScheme(scheme, network: network) {
                detectedScheme = scheme
                return true
            }
        }
        
        // Strategy 3: Try universal link (most reliable for apps without URL schemes)
        print("   Trying universal link...")
        if await tryUniversalLink() {
            return true
        }
        
        // Strategy 4: Direct App Store link (will open the app if installed)
        print("   Trying App Store link (may open installed app)...")
        if await tryAppStoreLink() {
            return true
        }
        
        return false
    }
    
    private func tryOpenWithScheme(_ scheme: String, network: String) async -> Bool {
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
        }
        
        print("⏰ Connection timeout after 30 seconds")
        await MainActor.run {
            connectionStatus = .failed
            errorMessage = "Connection timeout. Please make sure you approved the connection in Ready Wallet."
        }
        return false
    }
    
    private func tryUniversalLink() async -> Bool {
        // Try universal links for Ready/Argent (opens the app if associated domains configured)
        let urls = [
            // Ready links
            "https://ready.co/app/connect",
            "https://ready.co/connect",
            "https://ready.co",
            // Argent links (legacy)
            "https://argent.link/app",
            "https://argent.link/app/wc"
        ]
        
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            
            let success = await withCheckedContinuation { continuation in
                DispatchQueue.main.async {
                    UIApplication.shared.open(url, options: [.universalLinksOnly: true]) { result in
                        continuation.resume(returning: result)
                    }
                }
            }
            
            if success {
                print("   ✅ Opened with universal link: \(urlString)")
                return true
            }
        }
        
        return false
    }
    
    private func tryAppStoreLink() async -> Bool {
        // App Store links will open the app if it's installed
        guard let url = URL(string: "https://apps.apple.com/app/ready-wallet/id6504062205") else {
            return false
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                UIApplication.shared.open(url, options: [:]) { result in
                    continuation.resume(returning: result)
                }
            }
        }
    }
    
    private func showManualConnectionInstructions() async {
        let message = """
        Ready Wallet Manual Connection:
        
        1. Open Ready Wallet app manually
        2. Ensure Sepolia network is selected
        3. Go to Settings or DApp connections
        4. Approve the connection request
        5. Return to this app
        
        Or tap 'I Connected Manually' below
        """
        
        await MainActor.run {
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
        connectionStatus = .disconnected
        
        print("✅ Disconnected successfully")
    }
    
    // MARK: - Manual import from private key
    public func importFromPrivateKey(address: String?, publicKey: String?, privateKey: String) {
        // This manager is UI state only; actual Starknet operations are on StarknetManager
        // We mark as connected to indicate the app has a wallet imported
        DispatchQueue.main.async {
            self.connectedAddress = address ?? self.connectedAddress
            self.publicKey = publicKey ?? self.publicKey
            self.walletName = self.walletName.isEmpty ? "Imported Wallet" : self.walletName
            self.isConnected = true
            self.connectionStatus = .connected
            self.errorMessage = ""
        }
    }
    
    // MARK: - App Store helper
    /// Open the Ready Wallet App Store page (will foreground the app if installed)
    public func openAppStore() {
        guard let url = URL(string: "https://apps.apple.com/app/ready-wallet/id6504062205") else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Debug Methods
    
    public func debugCheckSchemes() {
        print("\n🔍 DEBUG: Checking all possible schemes for Ready Wallet:")
        print("   App is installed as: com.ready.wallet\n")
        
        for scheme in possibleSchemes {
            guard let url = URL(string: "\(scheme)://") else { continue }
            let canOpen = UIApplication.shared.canOpenURL(url)
            print("   \(canOpen ? "✅" : "❌") \(scheme)://")
        }
        
        print("\n💡 Note: Even if all show ❌, the app might still open via universal links or App Store links")
        print("")
    }
    
    public func testAllOpenMethods() async {
        print("\n🧪 Testing all methods to open Ready Wallet...\n")
        
        print("1️⃣ Testing URL schemes:")
        for scheme in possibleSchemes {
            _ = await tryOpenWithScheme(scheme, network: "sepolia")
            try? await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second between attempts
        }
        
        print("\n2️⃣ Testing universal links:")
        _ = await tryUniversalLink()
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        print("\n3️⃣ Testing App Store link:")
        _ = await tryAppStoreLink()
        
        print("\n✅ Test complete. Check console for results.\n")
    }
    
    // MARK: - Transaction Methods
    
    public func signTransaction(_ transaction: [String: Any]) async throws -> String {
        guard isConnected else {
            throw ReadyWalletError.notConnected
        }
        
        // Mock implementation
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return "0xsignature_mock_\(Date().timeIntervalSince1970)"
    }
    
    public func sendTransaction(_ transaction: [String: Any]) async throws -> String {
        guard isConnected else {
            throw ReadyWalletError.notConnected
        }
        
        _ = try await signTransaction(transaction)
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        return "0x\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())"
    }
    
    // MARK: - URL Callback Handling
    
    public func handleReadyCallback(url: URL) {
        print("🔗 ReadyWalletManager handling callback URL: \(url.absoluteString)")
        print("   Scheme: \(url.scheme ?? "none")")
        print("   Host: \(url.host ?? "none")")
        print("   Path: \(url.path)")
        print("   Query: \(url.query ?? "none")")
        
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
            }
        } else if !address.isEmpty {
            print("✅ Connection successful!")
            completeManualConnection(address: address, publicKey: publicKey, name: name.isEmpty ? "Ready Wallet" : name)
        }
    }
    
    // MARK: - Display Methods
    
    public func getWalletDisplayName() -> String {
        return walletName.isEmpty ? "Ready Wallet" : walletName
    }
    
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

// MARK: - Errors

public enum ReadyWalletError: LocalizedError {
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