//
//  AppDelegate.swift
//  QRPaymentScanner
//

import UIKit
import Foundation
import metamask_ios_sdk

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // Configure ChippiPay API keys
        configureChippiPay()

        return true
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

    // Forward MetaMask deeplink callbacks (fallback path; primary handling happens in SceneDelegate on iOS 13+)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if URLComponents(url: url, resolvingAgainstBaseURL: true)?.host == "mmsdk" {
            MetaMaskSDK.sharedInstance?.handleUrl(url)
            return true
        }
        return false
    }
}
