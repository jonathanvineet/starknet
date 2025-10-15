//
//  AppDelegate.swift
//  QRPaymentScanner
//

import UIKit
import Foundation
import WalletConnectSign
import ReownAppKit
import WalletConnectNetworking
import WalletConnectRelay
import WalletConnectSigner
import Combine
import CryptoKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // CRITICAL: Configure Reown AppKit FIRST before any other initialization
        configureReownAppKit()

        // Configure ChippiPay API keys
        configureChippiPay()
        
        // Configure WalletConnect
        configureWalletConnect()

        return true
    }
    
    // MARK: - Reown AppKit Configuration
    
    private func configureReownAppKit() {
        print("🔧 Configuring Reown AppKit...")
        
        let projectId = "18b7d657eedae828d0e6d780a80eded9" // Your Reown Project ID
        
        let metadata = AppMetadata(
            name: "QRPaymentScanner",
            description: "Starknet Payment Scanner with Braavos wallet integration",
            url: "https://qrpaymentscanner.app",
            icons: ["https://qrpaymentscanner.app/icon.png"],
            redirect: try! AppMetadata.Redirect(native: "qrpaymentscanner://", universal: nil)
        )
        
        // IMPORTANT: Configure Networking BEFORE AppKit
        // This is required for WalletConnect protocol communication
        Networking.configure(
            groupIdentifier: "group.com.qrpaymentscanner.walletconnect",
            projectId: projectId,
            socketFactory: SocketFactory()
        )
        
        // Define Starknet networks and methods
        let starknetMethods: Set<String> = [
            "starknet_requestAccounts",
            "starknet_signTypedData",
            "starknet_sendTransaction"
        ]
        
        let starknetEvents: Set<String> = ["accountsChanged", "chainChanged"]
        
        let starknetChains = [
            Blockchain("starknet:SN_MAIN")!,
            Blockchain("starknet:SN_SEPOLIA")!
        ]
        
        let starknetNamespace = ProposalNamespace(
            chains: starknetChains,
            methods: starknetMethods,
            events: starknetEvents
        )
        
        let sessionParams = SessionParams(
            namespaces: ["starknet": starknetNamespace],
            sessionProperties: nil
        )
        
        // Create crypto provider for Starknet
        let cryptoProvider = StarknetCryptoProvider()
        
        // Configure custom wallets for Starknet
        let customWallets = [
            // Argent X - Has best WalletConnect support
            Wallet(
                id: "argentx",
                name: "Argent X",
                homepage: "https://www.argent.xyz/argent-x/",
                imageUrl: "https://www.argent.xyz/logo.png",
                order: 1,
                mobileLink: "argentx://",
                linkMode: nil
            ),
            // Braavos Wallet - Limited WC support
            Wallet(
                id: "braavos",
                name: "Braavos",
                homepage: "https://braavos.app/",
                imageUrl: "https://braavos.app/icon.png",
                order: 2,
                mobileLink: "braavos://",
                linkMode: nil
            ),
            // Ready Wallet - iOS app doesn't support external WC yet
            Wallet(
                id: "bc949c5d968ae81310268bf9193f9c9fb7bb4e1283e1284af8f2bd4992535fd6",
                name: "Ready Wallet",
                homepage: "https://readywallet.app/",
                imageUrl: "https://readywallet.app/icon.png",
                order: 3,
                mobileLink: "readywallet://",
                linkMode: nil
            )
        ]
        
        // Recommended wallet IDs (Ready Wallet from WalletGuide)
        let recommendedWalletIds = [
            "bc949c5d968ae81310268bf9193f9c9fb7bb4e1283e1284af8f2bd4992535fd6" // Ready Wallet
        ]
        
        // Configure AppKit with Starknet support and custom wallets
        AppKit.configure(
            projectId: projectId,
            metadata: metadata,
            crypto: cryptoProvider,
            sessionParams: sessionParams,
            authRequestParams: nil,
            recommendedWalletIds: recommendedWalletIds,
            customWallets: customWallets
        )
        
        print("✅ Reown AppKit configured successfully")
        print("   Project ID: \(projectId)")
        print("   Starknet networks: SN_MAIN, SN_SEPOLIA")
        print("   Supported methods: \(starknetMethods)")
        print("   Custom wallets: Braavos, Ready Wallet")
        print("   Recommended: Ready Wallet")
    }
    
    // MARK: - ChippiPay Configuration

    private func configureChippiPay() {
        let keychain = KeychainHelper.shared

        // Check if already configured
        if let existingKey = keychain.getChippiPayAPIKey(),
           let existingSecret = keychain.getChippiPaySecretKey(),
           !existingKey.isEmpty, !existingSecret.isEmpty {
            print("✅ ChippiPay already configured")
            print("   Public Key: \(existingKey.prefix(20))...")
            print("   Secret Key: \(existingSecret.prefix(20))...")
        } else {
            print("📱 Configuring ChippiPay for first time...")

            // Your ChippiPay API credentials
            let publicKey = "pk_prod_0f67a3155f8d994796b3ecdb50b8db67"
            let secretKey = "sk_prod_c035c91fcc9ac3ac6cf7b8a3c2d88bb3c428eecf75d11b18f0006d8b9e84599b"

            // Save to secure keychain
            let publicKeySaved = keychain.saveChippiPayAPIKey(publicKey)
            let secretKeySaved = keychain.saveChippiPaySecretKey(secretKey)

            if publicKeySaved && secretKeySaved {
                print("✅ ChippiPay API keys configured successfully")
                print("   Public Key: \(publicKey.prefix(20))...")
                print("   Secret Key: \(secretKey.prefix(20))...")
            } else {
                print("❌ Failed to save ChippiPay API keys to keychain")
            }
        }

        // Optional: Test connection on app launch (useful for debugging)
        #if DEBUG
        Task {
            await testChippiPayConnection()
        }
        #endif
    }

    @MainActor
    private func testChippiPayConnection() async {
        print("🔄 Testing ChippiPay API connection...")

        let manager = ChippiPayManager(environment: .production)

        do {
            try await manager.fetchAvailableServices()

            if manager.availableServices.isEmpty {
                print("⚠️  Connection successful but no services returned")
                print("   This might be normal if no services are configured in your ChippiPay account")
            } else {
                print("✅ Connection successful!")
                print("   Found \(manager.availableServices.count) available services:")
                for (index, service) in manager.availableServices.prefix(3).enumerated() {
                    print("   \(index + 1). \(service.name) (\(service.category))")
                }
            }
            print("🎉 ChippiPay is ready to use!")
        } catch {
            print("❌ Connection failed: \(error.localizedDescription)")
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - WalletConnect Configuration
    
    private func configureWalletConnect() {
        Networking.configure(
            projectId: WalletConnectConfiguration.projectId,
            socketFactory: SocketFactory()
        )
        
        Sign.configure(metadata: WalletConnectConfiguration.metadata)
    }
    
    // Forward deeplink callbacks (fallback path; primary handling happens in SceneDelegate on iOS 13+)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("🔗 AppDelegate handling URL: \(url.absoluteString)")
        
        // First, let AppKit handle WalletConnect deep links
        // This is important for Braavos and other WalletConnect-based wallet callbacks
        AppKit.instance.handleDeeplink(url)
        
        // Handle Ready Wallet callbacks
        if url.scheme == "starknet" || 
           url.scheme == "qrpaymentscanner" ||
           (url.scheme == "com" && url.host == "vj" && url.path.hasPrefix("/QRPaymentScanner")) {
            ReadyWalletManager.shared.handleReadyCallback(url: url)
            return true
        }
        
        // Handle WalletConnect URLs
        if url.scheme == "wc" || url.absoluteString.contains("wc?") {
            return true // WalletConnect SDK handles this automatically
        }
        
        return false
    }
}
