import SwiftUI
import metamask_ios_sdk

struct ConnectWalletButton: View {
    @State private var isConnecting = false
    @State private var isConnected = false
    @State private var account: String = ""

    private let sdk: MetaMaskSDK = {
        let appMetadata = AppMetadata(name: "StarknetQR", url: "https://starknet.example")
        return MetaMaskSDK.shared(
            appMetadata,
            transport: .deeplinking(dappScheme: "starknet"),
            sdkOptions: SDKOptions(infuraAPIKey: "")
        )
    }()

    var body: some View {
        Button(action: connect) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                Text(buttonTitle)
            }
        }
        .disabled(isConnecting)
        .foregroundColor(isConnected ? .green : .red)
        .accessibilityLabel(isConnected ? "Wallet connected" : "Connect wallet")
        .accessibilityHint("Connect to MetaMask wallet")
        .onAppear {
            // If SDK already connected earlier in the session, reflect that
            if !sdk.account.isEmpty {
                isConnected = true
                account = sdk.account
            }
        }
    }

    private var buttonTitle: String {
        if isConnected { return "Connected" }
        if isConnecting { return "Connecting…" }
        return "Connect"
    }

    private var iconName: String {
        if isConnected { return "checkmark.seal.fill" }
        if isConnecting { return "hourglass" }
        return "link.circle.fill"
    }

    private func connect() {
        isConnecting = true
        Task {
            let result = await sdk.connect()
            await MainActor.run {
                switch result {
                case .success:
                    isConnected = true
                    account = sdk.account
                case .failure(let error):
                    isConnected = false
                    // Optional: surface the error via a toast/snackbar
                    print("MetaMask connect failed: \(error.localizedDescription)")
                }
                isConnecting = false
            }
        }
    }
}
