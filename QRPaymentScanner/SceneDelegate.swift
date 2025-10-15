//
//  SceneDelegate.swift
//  QRPaymentScanner
//

import UIKit
import SwiftUI
import ReownAppKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView()

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView.preferredColorScheme(.dark))
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    // Handle deeplink return from wallets (iOS 13+ scene-based apps)
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        
        print("🔗 SceneDelegate received URL: \(url.absoluteString)")
        
        // First, let AppKit handle WalletConnect deep links
        // This is important for Braavos and other WalletConnect-based wallet callbacks
        AppKit.instance.handleDeeplink(url)
        
        // Handle wallet callback responses
        if url.scheme == "starknet" || url.scheme == "qrpaymentscanner" {
            // Check if it's a Braavos callback
            if url.host == "starknet-callback" {
                handleBraavosCallback(url: url)
            } else {
                // Ready wallet callback
                ReadyWalletManager.shared.handleReadyCallback(url: url)
            }
        }
    }
    
    private func handleBraavosCallback(url: URL) {
        print("🦁 Braavos callback received")
        
        // Parse URL components
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            print("❌ Failed to parse Braavos callback URL")
            return
        }
        
        // Extract address from callback
        var address: String?
        var publicKey: String?
        
        for item in queryItems {
            switch item.name {
            case "address":
                address = item.value
                print("📍 Braavos address: \(item.value ?? "nil")")
            case "publicKey":
                publicKey = item.value
                print("🔑 Braavos publicKey: \(item.value ?? "nil")")
            default:
                print("ℹ️ Braavos param: \(item.name) = \(item.value ?? "nil")")
            }
        }
        
        // Connect to wallet with received credentials
        if let address = address {
            // Braavos doesn't return private key, use read-only connection
            StarknetManager.shared.connectReadOnlyWallet(address: address, publicKey: publicKey)
            print("✅ Braavos wallet connected in read-only mode")
        } else {
            print("❌ No address in Braavos callback")
        }
    }
}
