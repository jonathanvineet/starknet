import SwiftUI

struct KeplrConnectView: View {
    @StateObject private var walletManager = KeplrWalletManager()
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            if walletManager.isConnected {
                connectedView
            } else {
                connectButton
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var connectedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 50))
            
            Text("Connected to Keplr")
                .font(.headline)
            
            if let address = walletManager.connectedAddress {
                Text(address)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button(action: disconnect) {
                Text("Disconnect")
                    .foregroundColor(.red)
            }
        }
    }
    
    private var connectButton: some View {
        Button(action: connect) {
            HStack {
                Image(systemName: "link.circle.fill")
                Text("Connect Keplr Wallet")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
        }
    }
    
    private func connect() {
        Task {
            do {
                try await walletManager.connect()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func disconnect() {
        Task {
            do {
                try await walletManager.disconnect()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}