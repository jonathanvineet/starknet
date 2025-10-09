import UIKit
// If you've added the MetaMask iOS SDK via SPM or CocoaPods, import it here:
import metamask_ios_sdk

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    // Handle deeplink callbacks from MetaMask mobile when using deeplinking transport
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Ensure this is a MetaMask SDK callback (host "mmsdk") then forward to SDK
        if URLComponents(url: url, resolvingAgainstBaseURL: true)?.host == "mmsdk" {
            MetaMaskSDK.sharedInstance?.handleUrl(url)
        } else {
            // handle other deeplinks if any
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}