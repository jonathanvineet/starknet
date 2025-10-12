//
//  AppDelegate.swift
//  QRPaymentScanner
//

import UIKit
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
        // Check if already configured
        let config = ChippiPayConfiguration.shared

        if !config.isConfigured() {
            print("📱 Configuring ChippiPay for first time...")
            config.configure()

            // Mark as configured
            UserDefaults.standard.set(true, forKey: "chippiPayConfigured")
        } else {
            print("✅ ChippiPay already configured")
            print(config.getStatus())
        }

        // Optional: Test connection on app launch (useful for debugging)
        #if DEBUG
        Task {
            let success = await config.testConnection()
            if success {
                print("🎉 ChippiPay is ready to use!")
            } else {
                print("⚠️  ChippiPay connection test failed - check credentials")
            }
        }
        #endif
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
