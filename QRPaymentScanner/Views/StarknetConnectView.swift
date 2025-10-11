//
//  StarknetConnectView.swift
//  QRPaymentScanner
//
//  Starknet wallet connection interface
//

import SwiftUI

public struct StarknetConnectView: View {
    @StateObject private var starknet = StarknetManager.shared
    @State private var showingConnectionSheet = false
    @State private var address = ""
    @State private var privateKey = ""
    @State private var publicKey = ""
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 0.8, green: 0.3, blue: 0.3))
                
                Text("Connect to Starknet")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Connect your Starknet wallet to access the vault")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            // Connection Form
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wallet Address")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    TextField("0x...", text: $address)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 14, design: .monospaced))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Private Key")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    SecureField("0x...", text: $privateKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 14, design: .monospaced))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Public Key")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    TextField("0x...", text: $publicKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 14, design: .monospaced))
                }
            }
            .padding(.horizontal, 20)
            
            // Quick Connect Buttons
            VStack(spacing: 12) {
                Text("Quick Connect")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                
                Button(action: {
                    // Pre-fill with your deployed account credentials
                    address = "0x0736bf796e70dad68a103682720dafb090f50065821971b33cbeeb3e3ff5af9f"
                    privateKey = "0x04097f4f606ccf39f9c27c01acc14bb99679de225c86795ae811b46fa96b3390"
                    publicKey = "0xb2eba21301a43862b7b25e1d7e3f5d27ce57a5075c89e6aa490c33dc3e33cb"
                }) {
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text("Use Demo Account")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    // Pre-fill with the other wallet address you mentioned
                    address = "0x057d0fb86ba9a76d97d00bcd5b61379773070f7451a2ddb4ccb0d04d71586473"
                    privateKey = "" // User needs to fill this
                    publicKey = ""  // User needs to fill this
                }) {
                    HStack {
                        Image(systemName: "wallet.pass.fill")
                        Text("Use Other Wallet")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Connect Button
            Button(action: connectWallet) {
                HStack {
                    if starknet.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "link.circle.fill")
                    }
                    
                    Text(starknet.isLoading ? "Connecting..." : "Connect Wallet")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color(red: 0.8, green: 0.3, blue: 0.3) : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!isFormValid || starknet.isLoading)
            .padding(.horizontal, 20)
            
            // Error Message
            if !starknet.errorMessage.isEmpty {
                Text(starknet.errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
            }
            
            // Cancel Button
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.gray)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
    }
    
    private var isFormValid: Bool {
        !address.isEmpty && !privateKey.isEmpty && !publicKey.isEmpty &&
        address.hasPrefix("0x") && privateKey.hasPrefix("0x") && publicKey.hasPrefix("0x")
    }
    
    private func connectWallet() {
        starknet.connectWallet(
            address: address,
            privateKey: privateKey,
            publicKey: publicKey
        )
        dismiss()
    }
}

struct StarknetConnectView_Previews: PreviewProvider {
    static var previews: some View {
        StarknetConnectView()
    }
}