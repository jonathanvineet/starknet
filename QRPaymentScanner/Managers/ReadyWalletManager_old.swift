//
//  ReadyWalletManager.swift
//  QRPaymentScanner
//
//  Ready Wallet integration for Starknet on iOS with fixed URL schemes
//

import Foundation
import UIKit
import Combine

@MainActor
public class ReadyWalletManager: ObservableObject {
    public static let shared = ReadyWalletManager()
    
    @Published public var isConnected = false
    @Published public var connectedAddress = ""
    @Published public var isConnecting = false
    @Published public var errorMessage = ""
    @Published public var publicKey = ""
    @Published public var walletName = ""
    
    private var connectionContinuation: CheckedContinuation<Bool, Never>?
    private var connectionTimer: Timer?
    
    // Ready Wallet detection with updated schemes for new Ready Wallet app
    private let walletProviders = [
        WalletProvider(id: "argentX", name: "Argent X", schemes: ["argentx://", "argent://"]),
        WalletProvider(id: "ready", name: "Ready Wallet", schemes: ["ready://", "readywallet://", "argentmobile://", "argent://"]),
        WalletProvider(id: "braavos", name: "Braavos", schemes: ["braavos://"])
    ]
    
    // Wallet Provider structure
    public struct WalletProvider {
        let id: String
        let name: String
        let schemes: [String]
        
        @MainActor
        func isInstalled() -> Bool {
            return schemes.contains { scheme in
                if let url = URL(string: scheme) {
                    return UIApplication.shared.canOpenURL(url)
                }
                return false
            }
        }
        
        @MainActor
        func getAvailableScheme() -> String? {
            return schemes.first { scheme in
                if let url = URL(string: scheme) {
                    return UIApplication.shared.canOpenURL(url)
                }
                return false
            }
        }
    }
    
    init() {
        setupNotifications()
        debugAvailableWallets()
    }
    
    deinit {
        connectionTimer?.invalidate()
    }
    
    // MARK: - Setup
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleReadyCallbackNotification),
            name: NSNotification.Name("ReadyWalletCallback"),
            object: nil
        )
    }
    
    // Debug helper to see which wallets are detected
    private func debugAvailableWallets() {
        print("🔍 Checking for installed wallets:")
        for provider in walletProviders {
            let installed = provider.isInstalled()
            print("  \(provider.name): \(installed ? "✅ Installed" : "❌ Not Installed")")
            
            // Debug each scheme individually
            for scheme in provider.schemes {
                if let url = URL(string: scheme) {
                    let canOpen = UIApplication.shared.canOpenURL(url)
                    print("    \(scheme) -> \(canOpen ? "✅ Available" : "❌ Not Available")")
                } else {
                    print("    \(scheme) -> ❌ Invalid URL")
                }
            }
            
            if installed, let scheme = provider.getAvailableScheme() {
                print("    Best available scheme: \(scheme)")
            }
        }
        
        // Test specific Ready Wallet schemes directly
        let readySchemes = ["ready://", "readywallet://", "argentmobile://", "argent://"]
        print("🔍 Direct Ready Wallet scheme tests:")
        for scheme in readySchemes {
            if let url = URL(string: scheme) {
                let canOpen = UIApplication.shared.canOpenURL(url)
                print("  \(scheme) -> \(canOpen ? "✅ Can Open" : "❌ Cannot Open")")
            }
        }
    }
    
    // MARK: - Connection Methods
    
    /// Connect to Ready Wallet or available Starknet wallet
    public func connectToReadyWallet() async -> Bool {
        guard !isConnecting else { return false }
        
        DispatchQueue.main.async {
            self.isConnecting = true
            self.errorMessage = ""
        }
        
        // Debug available wallets before connecting
        debugAvailableWallets()
        
        // Get available wallet
        guard let wallet = getAvailableWallet() else {
            completeConnection(success: false, address: nil, error: "No Starknet wallet installed. Please install Ready Wallet or Argent X.")
            return false
        }
        
        // Update wallet name
        DispatchQueue.main.async {
            self.walletName = wallet.name
        }
        
        return await withCheckedContinuation { continuation in
            connectionContinuation = continuation
            
            // Start connection timeout
            startConnectionTimeout()
            
            // Open wallet with connection request
            openWalletWithConnectionRequest(wallet: wallet)
        }
    }
    
    /// Start connection timeout
    private func startConnectionTimeout() {
        connectionTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.completeConnection(success: false, address: nil, error: "Connection timeout")
            }
        }
    }
    
    /// Check if Ready Wallet is installed
    public func isReadyWalletInstalled() -> Bool {
        return getAvailableWallet() != nil
    }
    
    /// Force assume Ready Wallet is installed (since we know it is from device scan)
    public func forceDetectReadyWallet() -> Bool {
        // Since we confirmed Ready Wallet is installed via ideviceinstaller,
        // let's bypass the URL scheme detection and assume it's available
        print("🔧 Force detecting Ready Wallet as available")
        return true
    }
    
    /// Get the available wallet provider
    public func getAvailableWallet() -> WalletProvider? {
        // Since we know Ready Wallet is installed from our device scan,
        // prioritize it even if URL scheme detection fails
        if let readyWallet = walletProviders.first(where: { $0.id == "ready" }) {
            // Try URL scheme detection first
            if readyWallet.isInstalled() {
                print("✅ Ready Wallet detected via URL scheme")
                return readyWallet
            } else {
                // Force detection since we know it's installed
                print("🔧 Ready Wallet found via device scan - bypassing URL scheme detection")
                return readyWallet
            }
        }
        
        // Check Argent X
        if let argentWallet = walletProviders.first(where: { $0.id == "argentX" && $0.isInstalled() }) {
            return argentWallet
        }
        
        // Fallback to any available wallet
        return walletProviders.first { $0.isInstalled() }
    }
    
    /// Get wallet name for display
    public func getWalletDisplayName() -> String {
        return getAvailableWallet()?.name ?? "Starknet Wallet"
    }
    
    /// Test specific URL scheme manually
    public func testScheme(_ scheme: String) -> Bool {
        guard let url = URL(string: scheme) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    /// Get detailed wallet detection info for debugging
    public func getWalletDetectionInfo() -> [String: Any] {
        var info: [String: Any] = [:]
        
        for provider in walletProviders {
            var providerInfo: [String: Any] = [:]
            providerInfo["installed"] = provider.isInstalled()
            
            var schemeTests: [String: Bool] = [:]
            for scheme in provider.schemes {
                if let url = URL(string: scheme) {
                    schemeTests[scheme] = UIApplication.shared.canOpenURL(url)
                }
            }
            providerInfo["schemes"] = schemeTests
            providerInfo["availableScheme"] = provider.getAvailableScheme()
            
            info[provider.name] = providerInfo
        }
        
        return info
    }
    
    /// Generate connection ID
    private func generateConnectionId() -> String {
        return UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "")
    }
    

    
    /// Open wallet with connection request
    private func openWalletWithConnectionRequest(wallet: WalletProvider) {
        var scheme: String?
        
        // Try to get available scheme, or use the first one for Ready Wallet
        if let availableScheme = wallet.getAvailableScheme() {
            scheme = availableScheme
        } else if wallet.id == "ready" {
            // Force use ready:// scheme since we know Ready Wallet is installed
            scheme = "ready://"
            print("🔧 Using forced ready:// scheme for Ready Wallet")
        }
        
        guard let finalScheme = scheme else {
            completeConnection(success: false, address: nil, error: "Wallet scheme not available")
            return
        }
        
        // Generate connection request
        let connectionId = generateConnectionId()
        let dappName = "QR Payment Scanner"
        
        // Your app's URL scheme for callbacks (make sure this is configured in Info.plist)
        let callbackScheme = "qrpaymentscanner" // Change this to your app's scheme
        let callbackUrl = "\(callbackScheme)://wallet-callback"
        
        // Build connection URL
        let connectionUrl: String
        
        if wallet.id == "argentX" || wallet.id == "ready" {
            // Ready Wallet / Argent connection format
            connectionUrl = "\(finalScheme)app/wc?uri=wc:connect&dappName=\(dappName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&callback=\(callbackUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        } else {
            // Generic wallet connection format
            connectionUrl = "\(finalScheme)connect?name=\(dappName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&callback=\(callbackUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        
        print("🔗 Opening wallet with URL: \(connectionUrl)")
        
        guard let url = URL(string: connectionUrl) else {
            completeConnection(success: false, address: nil, error: "Invalid connection URL")
            return
        }
        
        UIApplication.shared.open(url, options: [:]) { success in
            DispatchQueue.main.async {
                if success {
                    print("✅ Successfully opened \(wallet.name)")
                } else {
                    self.completeConnection(success: false, address: nil, error: "Failed to open \(wallet.name). The wallet app may not be installed or the URL scheme is incorrect.")
                }
            }
        }
    }
    
    // MARK: - Callback Handling
    
    /// Handle deep link callback from Ready Wallet
    public func handleReadyCallback(url: URL) {
        print("📱 Received callback URL: \(url.absoluteString)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            completeConnection(success: false, address: nil, error: "Invalid callback URL")
            return
        }
        
        let queryItems = components.queryItems ?? []
        
        // Check for connection approval
        if let approved = queryItems.first(where: { $0.name == "approved" })?.value,
           approved == "true" {
            
            // Extract wallet address
            if let address = queryItems.first(where: { $0.name == "address" })?.value {
                let publicKey = queryItems.first(where: { $0.name == "publicKey" })?.value ?? ""
                completeConnection(success: true, address: address, publicKey: publicKey, error: nil)
            } else {
                completeConnection(success: false, address: nil, error: "Address not found in callback")
            }
            
        } else if let error = queryItems.first(where: { $0.name == "error" })?.value {
            completeConnection(success: false, address: nil, error: "Connection rejected: \(error)")
        } else {
            completeConnection(success: false, address: nil, error: "Connection was cancelled or no approval received")
        }
    }
    
    /// Handle notification-based callback
    @objc private func handleReadyCallbackNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        if let address = userInfo["address"] as? String {
            let publicKey = userInfo["publicKey"] as? String ?? ""
            completeConnection(success: true, address: address, publicKey: publicKey, error: nil)
        } else if let error = userInfo["error"] as? String {
            completeConnection(success: false, address: nil, error: error)
        }
    }
    
    /// Complete connection process
    private func completeConnection(success: Bool, address: String?, publicKey: String? = nil, error: String?) {
        connectionTimer?.invalidate()
        connectionTimer = nil
        
        isConnecting = false
        
        if success, let address = address {
            isConnected = true
            connectedAddress = address
            self.publicKey = publicKey ?? ""
            errorMessage = ""
            
            print("✅ Connected to Ready Wallet: \(address)")
            
            // Notify StarknetManager
            StarknetManager.shared.connectWallet(
                address: address,
                privateKey: "", // Ready Wallet handles signing
                publicKey: publicKey ?? ""
            )
            
            connectionContinuation?.resume(returning: true)
        } else {
            isConnected = false
            connectedAddress = ""
            self.publicKey = ""
            errorMessage = error ?? "Connection failed"
            
            print("❌ Ready Wallet connection failed: \(error ?? "unknown")")
            
            connectionContinuation?.resume(returning: false)
        }
        
        connectionContinuation = nil
    }
    
    // MARK: - Disconnect
    
    /// Disconnect from Ready Wallet
    public func disconnect() {
        isConnected = false
        connectedAddress = ""
        publicKey = ""
        errorMessage = ""
        
        connectionTimer?.invalidate()
        connectionTimer = nil
        
        StarknetManager.shared.disconnectWallet()
        
        print("🔌 Disconnected from Ready Wallet")
    }
    
    // MARK: - App Store
    
    /// Open App Store to install Ready Wallet
    public func openAppStore() {
        // Use the correct Ready Wallet App Store URL - this was causing region availability issues
        let appStoreURL = "https://apps.apple.com/app/argent-wallet-starknet-wallet/id1358741926"
        if let url = URL(string: appStoreURL) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Transaction Signing
    
    /// Request transaction signature from Ready Wallet
    public func signTransaction(calls: [[String: Any]]) async -> String? {
        guard isConnected else {
            errorMessage = "Wallet not connected"
            return nil
        }
        
        // Create transaction request
        let txRequest: [String: Any] = [
            "method": "starknet_signTransaction",
            "params": [
                "calls": calls,
                "address": connectedAddress
            ]
        ]
        
        // Encode to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: txRequest),
              let jsonString = String(data: jsonData, encoding: .utf8),
              let encodedRequest = jsonString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            errorMessage = "Failed to encode transaction"
            return nil
        }
        
        // Open Ready Wallet for signing
        let signURL = "readywallet://sign?request=\(encodedRequest)&callback=starknet://signature"
        
        if let url = URL(string: signURL) {
            await UIApplication.shared.open(url)
        }
        
        // In a real implementation, you'd wait for the callback
        return nil
    }
}