import Foundation
import WalletConnectSign

class SimpleWalletConnectManager {
    static let shared = SimpleWalletConnectManager()
    private let projectId = "b53b0c4260d98f4e715ef413ad1fafe5" // Your WalletConnect Project ID
    
    private init() {
        setupWalletConnect()
    }
    
    private func setupWalletConnect() {
        // Basic configuration without App Groups
        let metadata = AppMetadata(
            name: "QR Payment Scanner",
            description: "Starknet Payment Scanner",
            url: "https://qrpaymentscanner.com",
            icons: ["https://qrpaymentscanner.com/icon.png"]
        )
        
        Networking.configure(
            projectId: projectId,
            socketFactory: SocketFactory()
        )
        
        Sign.configure(metadata: metadata)
    }
}