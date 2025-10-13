//
//  StarknetConnectView.swift
//  QRPaymentScanner
//
//  Starknet wallet connection interface with Argent X integration
//

import SwiftUI

public struct StarknetConnectView: View {
    @StateObject private var starknet = StarknetManager.shared
    @StateObject private var readyWallet = ReadyWalletManager.shared
    @State private var showingManualEntry = false
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
            
            // Connection Status
            if readyWallet.isConnected {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    
                    Text("Connected to Ready Wallet")
                        .font(.system(size: 18, weight: .medium))
                    
                    Text(readyWallet.connectedAddress)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            
            // Wallet Connection Options
            if !readyWallet.isConnected {
                VStack(spacing: 16) {
                    // Argent X Wallet Connection (Primary Option)
                    VStack(spacing: 12) {
                        Text("Recommended")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                        
                        Button(action: connectToReadyWallet) {
                            HStack(spacing: 12) {
                                if readyWallet.isConnecting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "wallet.pass.fill")
                                        .font(.system(size: 20))
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Connect with \(readyWallet.getWalletDisplayName())")
                                        .font(.system(size: 16, weight: .medium))
                                    if readyWallet.isReadyWalletInstalled() {
                                        Text("Open your \(readyWallet.getWalletDisplayName())")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    } else {
                                        Text("Install Starknet Wallet first")
                                            .font(.system(size: 12))
                                            .foregroundColor(.orange)
                                    }
                                }
                                
                                Spacer()
                                
                                if readyWallet.isReadyWalletInstalled() {
                                    Image(systemName: "arrow.right.circle")
                                        .font(.system(size: 16))
                                } else {
                                    Text("Install")
                                        .font(.system(size: 12, weight: .medium))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.2))
                                        .cornerRadius(8)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(red: 0.8, green: 0.3, blue: 0.3).opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.8, green: 0.3, blue: 0.3), lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                        .disabled(readyWallet.isConnecting)
                        .foregroundColor(.primary)
                        
                        // Show error message if any
                        if !readyWallet.errorMessage.isEmpty {
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text(readyWallet.errorMessage)
                                        .font(.system(size: 12))
                                        .foregroundColor(.orange)
                                    Spacer()
                                }
                                
                                // Show suggestion based on error type
                                if readyWallet.errorMessage.contains("not installed") {
                                    Button("Install Ready Wallet") {
                                        readyWallet.openAppStore()
                                    }
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.blue)
                                } else {
                                    Button("Try Manual Entry Instead") {
                                        showingManualEntry = true
                                    }
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    
                    // Manual Entry Option
                    Button(action: {
                        showingManualEntry = true
                    }) {
                        HStack {
                            Image(systemName: "key.fill")
                            Text("Manual Key Entry")
                                .font(.system(size: 14))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .foregroundColor(.gray)
                }
                .padding(.horizontal, 20)
            }
            
            // Error Message
            if !readyWallet.errorMessage.isEmpty {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(readyWallet.errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                    
                    if !readyWallet.isReadyWalletInstalled() {
                        Button("Install Ready Wallet") {
                            readyWallet.openAppStore()
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                if readyWallet.isConnected {
                    // Disconnect Button
                    Button(action: {
                        readyWallet.disconnect()
                    }) {
                        HStack {
                            Image(systemName: "link.badge.minus")
                            Text("Disconnect Wallet")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }
                    
                    // Done Button
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Done")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                } else {
                    // Cancel Button
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingManualEntry) {
            ManualWalletEntryView()
        }
    }
    
    private func connectToReadyWallet() {
        // If Ready Wallet is not installed, redirect to App Store
        if !readyWallet.isReadyWalletInstalled() {
            readyWallet.openAppStore()
            return
        }
        
        Task {
            let success = await readyWallet.connectWallet()
            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Manual Wallet Entry View
struct ManualWalletEntryView: View {
    @StateObject private var starknet = StarknetManager.shared
    @State private var address = ""
    @State private var privateKey = ""
    @State private var publicKey = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Manual Wallet Entry")
                    .font(.system(size: 20, weight: .bold))
                    .padding(.top)
                
                Text("Enter your Starknet wallet credentials manually")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
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
                .padding(.horizontal)
                
                // Quick Connect Buttons
                VStack(spacing: 12) {
                    Text("Quick Fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Button(action: {
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
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Connect Button
                Button(action: connectManualWallet) {
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
                .padding(.horizontal)
                
                if !starknet.errorMessage.isEmpty {
                    Text(starknet.errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
        }
    }
    
    private var isFormValid: Bool {
        !address.isEmpty && !privateKey.isEmpty && !publicKey.isEmpty &&
        address.hasPrefix("0x") && privateKey.hasPrefix("0x") && publicKey.hasPrefix("0x")
    }
    
    private func connectManualWallet() {
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