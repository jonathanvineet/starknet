//
//  BraavosConnectView.swift
//  QRPaymentScanner
//
//  WalletConnect v2 UI for Braavos wallet
//

import SwiftUI

public struct BraavosConnectView: View {
    @ObservedObject var manager = BraavosConnectionManager.shared
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) var dismiss
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 24) {
            if manager.isConnected {
                connectedView
            } else {
                disconnectedView
            }
        }
        .padding()
        .sheet(isPresented: $manager.showConnectionSheet) {
            ConnectionSheet(
                uri: manager.connectionURI,
                onOpenBraavos: {
                    manager.openBraavos()
                }
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var disconnectedView: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.secondary)
            }
            
            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            Text("Connect Braavos Wallet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Secure connection via WalletConnect v2")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: connectWallet) {
                HStack {
                    Image(systemName: "link.circle.fill")
                    Text("Connect Braavos")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Spacer()
        }
    }
    
    private var connectedView: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("Connected")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Address")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatAddress(manager.userAddress))
                    .font(.system(.body, design: .monospaced))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            Text("✅ Wallet connected in read-only mode")
                .font(.caption)
                .foregroundColor(.green)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            
            Button("Disconnect") {
                Task {
                    await manager.disconnect()
                }
            }
            .buttonStyle(.bordered)
            .tint(.red)
            
            Spacer()
        }
    }
    
    private func connectWallet() {
        Task {
            do {
                try await manager.connect()
                // After generating the WalletConnect URI, immediately open Braavos to request connection
                await MainActor.run {
                    manager.openBraavos()
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func formatAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        return "\(address.prefix(6))...\(address.suffix(4))"
    }
}

// MARK: - Connection Sheet with QR Code

struct ConnectionSheet: View {
    let uri: String
    let onOpenBraavos: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button("Close") { 
                    dismiss() 
                }
                .padding()
            }
            
            Text("Connect to Braavos")
                .font(.title2)
                .fontWeight(.bold)
            
            if let qrImage = generateQRCode(from: uri) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 280, height: 280)
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding()
            }
            
            Text("Scan with Braavos app")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("OR")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 4)
            
            Button(action: onOpenBraavos) {
                HStack {
                    Image(systemName: "arrow.up.forward.app.fill")
                    Text("Open Braavos")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .utf8)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let ciImage = filter.outputImage else { return nil }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = ciImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}

struct BraavosConnectView_Previews: PreviewProvider {
    static var previews: some View {
        BraavosConnectView()
    }
}
