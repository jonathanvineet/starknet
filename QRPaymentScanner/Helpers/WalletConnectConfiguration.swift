import Foundation

struct WalletConnectConfiguration {
    static let projectId = "b53b0c4260d98f4e715ef413ad1fafe5"
    
    static let metadata = AppMetadata(
        name: "QR Payment Scanner",
        description: "Starknet Payment Scanner",
        url: "https://qrpaymentscanner.com", // Replace with your app's URL
        icons: ["https://qrpaymentscanner.com/icon.png"] // Replace with your app's icon URL
    )
}

struct AppMetadata {
    let name: String
    let description: String
    let url: String
    let icons: [String]
}