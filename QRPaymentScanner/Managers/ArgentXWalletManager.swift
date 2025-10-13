//
//  ArgentXWalletManager.swift (Renamed from BraavosWalletManager.swift)
//  QRPaymentScanner
//
//  Argent X wallet integration for Starknet on iOS using WalletConnect v2
//

import Foundation
import UIKit
import Combine

@MainActor
public class ArgentXWalletManager: ObservableObject {
    public static let shared = ArgentXWalletManager()
    
    @Published public var isConnected = false
    @Published public var connectedAddress = ""
    @Published public var isConnecting = false
    @Published public var errorMessage = ""
    @Published public var publicKey = ""
    
    private var wcUri: String?
    private var connectionContinuation: CheckedContinuation<Bool, Never>?
    private var connectionTimer: Timer?
    
    // Argent X URL schemes
    private let argentSchemes = ["argent://", "argentx://", "argentmobile://"]
    
    init() {
        setupNotifications()
    }
    
    deinit {
        connectionTimer?.invalidate()
    }
    
    // MARK: - Setup
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleArgentCallbackNotification),
            name: NSNotification.Name("ArgentWalletCallback"),
            object: nil
        )
    }
    
    // MARK: - Connection Methods
    
    /// Connect to Argent X wallet
    public func connectToArgentX() async -> Bool {
        return await withCheckedContinuation { continuation in
            connectionContinuation = continuation
            
            isConnecting = true
            errorMessage = ""
            
            // Check if Argent is installed
            guard isArgentInstalled() else {
                errorMessage = "Argent wallet is not installed"
                isConnecting = false
                openAppStore()
                continuation.resume(returning: false)
                return
            }
            
            // Generate WalletConnect URI
            let wcUri = generateWalletConnectURI()
            self.wcUri = wcUri
            
            // Try to open Argent with WalletConnect
            openArgentWithWalletConnect(uri: wcUri)
            
            // Set timeout (60 seconds)
            connectionTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    if self.connectionContinuation != nil {
                        self.completeConnection(success: false, address: nil, error: "Connection timeout")
                    }
                }
            }
        }
    }
    
    /// Check if Argent wallet is installed
    public func isArgentInstalled() -> Bool {
        for scheme in argentSchemes {
            if let url = URL(string: scheme),
               UIApplication.shared.canOpenURL(url) {
                return true
            }
        }
        return false
    }
    
    /// Generate WalletConnect v2 URI
    private func generateWalletConnectURI() -> String {
        // Generate unique session topic
        let topic = generateRandomHex(length: 64)
        let symKey = generateRandomHex(length: 64)
        
        // WalletConnect v2 URI format
        // wc:topic@2?relay-protocol=irn&symKey=key
        return "wc:\(topic)@2?relay-protocol=irn&symKey=\(symKey)"
    }
    
    /// Generate random hex string
    private func generateRandomHex(length: Int) -> String {
        let bytes = (0..<length/2).map { _ in UInt8.random(in: 0...255) }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Open Argent with WalletConnect URI
    private func openArgentWithWalletConnect(uri: String) {
        guard let encodedUri = uri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            completeConnection(success: false, address: nil, error: "Failed to encode WalletConnect URI")
            return
        }
        
        // Try multiple deep link formats for Argent
        let deepLinkAttempts = [
            "argentx://wc?uri=\(encodedUri)",
            "argent://wc?uri=\(encodedUri)",
            "argentmobile://wc?uri=\(encodedUri)",
            // Universal link fallback
            "https://argent.link/app/wc?uri=\(encodedUri)"
        ]
        
        var connectionOpened = false
        
        for deepLink in deepLinkAttempts {
            if let url = URL(string: deepLink) {
                UIApplication.shared.open(url) { success in
                    if success {
                        connectionOpened = true
                        print("✅ Successfully opened Argent with: \(deepLink)")
                    }
                }
                
                if connectionOpened {
                    break
                }
            }
        }
        
        if !connectionOpened {
            completeConnection(success: false, address: nil, error: "Failed to open Argent wallet")
        }
    }
    
    // MARK: - Callback Handling
    
    /// Handle deep link callback from Argent
    public func handleArgentCallback(url: URL) {
        print("📱 Received callback URL: \(url.absoluteString)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            completeConnection(success: false, address: nil, error: "Invalid callback URL")
            return
        }
        
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
            completeConnection(success: false, address: nil, error: "Connection was cancelled")
        }
    }
    
    /// Handle notification-based callback
    @objc private func handleArgentCallbackNotification(_ notification: Notification) {
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
            
            print("✅ Connected to Argent X: \(address)")
            
            // Notify StarknetManager
            StarknetManager.shared.connectWallet(
                address: address,
                privateKey: "", // Argent handles signing
                publicKey: publicKey ?? ""
            )
            
            connectionContinuation?.resume(returning: true)
        } else {
            isConnected = false
            connectedAddress = ""
            self.publicKey = ""
            errorMessage = error ?? "Connection failed"
            
            print("❌ Argent connection failed: \(error ?? "unknown")")
            
            connectionContinuation?.resume(returning: false)
        }
        
        connectionContinuation = nil
    }
    
    // MARK: - Disconnect
    
    /// Disconnect from Argent wallet
    public func disconnect() {
        isConnected = false
        connectedAddress = ""
        publicKey = ""
        errorMessage = ""
        wcUri = nil
        
        connectionTimer?.invalidate()
        connectionTimer = nil
        
        StarknetManager.shared.disconnectWallet()
        
        print("🔌 Disconnected from Argent X")
    }
    
    // MARK: - App Store
    
    /// Open App Store to install Argent
    public func openAppStore() {
        let appStoreURL = "https://apps.apple.com/app/argent-starknet-wallet/id1358741926"
        if let url = URL(string: appStoreURL) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Transaction Signing
    
    /// Request transaction signature from Argent
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
        
        // Open Argent for signing
        let signURL = "argentx://sign?request=\(encodedRequest)&callback=starknet://signature"
        
        if let url = URL(string: signURL) {
            await UIApplication.shared.open(url)
        }
        
        // In a real implementation, you'd wait for the callback
        return nil
    }
}