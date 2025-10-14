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
    print("🚀 Starting Ready/Argent wallet connection")
        print("   Network: \(network)")
        
        isConnecting = true
        connectionStatus = .connecting
        errorMessage = ""
        
        defer {
            if !isConnected {
                isConnecting = false
            }
        }
        
        // First, try to detect and open the wallet
        let walletOpened = await openReadyWallet(network: network)
        
        if !walletOpened {
            print("❌ Could not open Ready Wallet")
            errorMessage = "Could not open Ready Wallet. Please open it manually."
            connectionStatus = .failed
            
            // Show instructions for manual connection
            await showManualConnectionInstructions()
            
            // Still wait for potential callback
            return await waitForConnection(timeout: 120) // 2 minutes for manual
        }
        
        print("✅ Ready Wallet opened, waiting for connection callback...")
        return await waitForConnection(timeout: 60)
    }
    
    private func openReadyWallet(network: String) async -> Bool {
    print("📱 Attempting to open Ready/Argent wallet app...")
        
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
        let encodedCallback = callbackURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? callbackURL

        // Try multiple URL formats (most-to-least specific)
        // We avoid requiring a WalletConnect URI here to simply bring app to foreground
        var attempts: [String] = []

        // Common open intents
        attempts.append(contentsOf: [
            "\(scheme)://app",
            "\(scheme)://open",
            "\(scheme)://open?network=\(network)",
            "\(scheme)://connect?network=\(network)&callback=\(encodedCallback)",
            "\(scheme)://wc", // some wallets respond to wc without uri to open landing
            "\(scheme)://" // bare open
        ])

        // Argent-specific known patterns (Ready often still responds to these)
        if scheme.hasPrefix("argent") {
            attempts.insert("argent://app", at: 0)
            attempts.insert("argentx://app", at: 0)
        }

        for urlString in attempts {
            guard let url = URL(string: urlString) else { continue }

            let success = await withCheckedContinuation { continuation in
                DispatchQueue.main.async {
                    UIApplication.shared.open(url, options: [:]) { result in
                        continuation.resume(returning: result)
                    }
                }
            }

            if success {
                print("   ✅ Opened with: \(urlString)")
                return true
            } else {
                print("   ❌ Failed: \(urlString)")
            }
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
    
    private func waitForConnection(timeout: TimeInterval) async -> Bool {
        print("⏳ Waiting for connection callback (timeout: \(timeout)s)...")
        
        return await withCheckedContinuation { continuation in
            connectionContinuation = continuation
            
            connectionTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
                print("⏰ Connection timeout")
                Task { @MainActor in
                    if !self.isConnected {
                        self.connectionStatus = .failed
                        self.errorMessage = "Connection timeout. Try manual connection."
                        self.isConnecting = false
                    }
                    
                    self.connectionContinuation?.resume(returning: false)
                    self.connectionContinuation = nil
                    self.connectionTimer = nil
                }
            }
        }
    }
    
    // MARK: - Manual Connection Support
    
    public func completeManualConnection(address: String, publicKey: String = "", name: String = "Ready Wallet") {
        print("✅ Completing manual connection")
        print("   Address: \(address)")
        
        guard !address.isEmpty else {
            print("❌ Empty address provided")
            return
        }
        
        DispatchQueue.main.async {
            self.connectedAddress = address
            self.publicKey = publicKey
            self.walletName = name
            self.isConnected = true
            self.isConnecting = false
            self.connectionStatus = .connected
            self.errorMessage = ""
            
            self.connectionContinuation?.resume(returning: true)
            self.connectionContinuation = nil
            self.connectionTimer?.invalidate()
            self.connectionTimer = nil
        }
    }
    
    public func cancelConnection() {
        print("🚫 Connection cancelled by user")
        
        DispatchQueue.main.async {
            self.isConnecting = false
            self.connectionStatus = .disconnected
            self.errorMessage = ""
            
            self.connectionContinuation?.resume(returning: false)
            self.connectionContinuation = nil
            self.connectionTimer?.invalidate()
            self.connectionTimer = nil
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
        print("🔗 Handling callback: \(url.absoluteString)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("❌ Invalid URL components")
            return
        }
        
        handleConnectCallback(components: components)
    }
    
    private func handleConnectCallback(components: URLComponents) {
        guard let queryItems = components.queryItems else {
            print("❌ No query items")
            return
        }
        
        print("📝 Query items: \(queryItems.map { "\($0.name)=\($0.value ?? "nil")" }.joined(separator: ", "))")
        
    var address = ""
    var publicKey = ""
    var name = ""
    var error = ""
        
        for item in queryItems {
            switch item.name.lowercased() {
            case "address", "account", "wallet_address":
                address = item.value ?? ""
            case "publickey", "public_key", "pubkey":
                publicKey = item.value ?? ""
            case "name", "wallet_name":
                name = item.value ?? ""
            case "network", "chain":
                // Network value available but not used
                break
            case "error", "error_message":
                error = item.value ?? ""
            default:
                break
            }
        }
        
        if !error.isEmpty {
            print("❌ Callback error: \(error)")
            DispatchQueue.main.async {
                self.errorMessage = "Error: \(error)"
                self.connectionStatus = .failed
                self.isConnecting = false
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