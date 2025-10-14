//
//  StarknetConnectView.swift
//  QRPaymentScanner
//
//  Starknet wallet connection interface with Argent X integration
//

import SwiftUI

public struct StarknetConnectView: View {
    @Environment(\.dismiss) private var dismiss
    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 0.8, green: 0.3, blue: 0.3))

                Text("Connect to Starknet")
                    .font(.system(size: 24, weight: .bold))

                Text("Enter your account keys or scan a QR to connect.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            ManualWalletEntryView()

            Button(action: { dismiss() }) {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Close")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Manual Wallet Entry View
struct ManualWalletEntryView: View {
    @StateObject private var starknet = StarknetManager.shared
    @State private var address = ""
    @State private var privateKey = ""
    @State private var publicKey = ""
    @State private var showAddressScanner = false
    @State private var showPrivateKeyScanner = false
    @State private var showPublicKeyScanner = false
    @State private var showBraavosConnect = false
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
                    // Address Field with Scan Button
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Wallet Address")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            Spacer()
                            Button(action: { showAddressScanner = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "qrcode.viewfinder")
                                    Text("Scan")
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                        }
                        
                        TextField("0x...", text: $address)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 14, design: .monospaced))
                        
                        if !address.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Address loaded")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    // Private Key Field with Scan Button
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Private Key")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            Spacer()
                            Button(action: { showPrivateKeyScanner = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "qrcode.viewfinder")
                                    Text("Scan")
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.1))
                                .foregroundColor(.orange)
                                .cornerRadius(8)
                            }
                        }
                        
                        SecureField("0x...", text: $privateKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 14, design: .monospaced))
                        
                        if !privateKey.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Private key loaded")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    // Public Key Field with Scan Button
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Public Key")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            Spacer()
                            Button(action: { showPublicKeyScanner = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "qrcode.viewfinder")
                                    Text("Scan")
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                            }
                        }
                        
                        TextField("0x...", text: $publicKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 14, design: .monospaced))
                        
                        if !publicKey.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Public key loaded")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Wallet Connection Buttons
                VStack(spacing: 12) {
                    Text("Connect via Wallet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Button(action: { showBraavosConnect = true }) {
                        HStack {
                            Image(systemName: "wallet.pass.fill")
                            Text("Connect to Braavos (WalletConnect)")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
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
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(12)
                    }
                    
                    // Instructions for Ready wallet users
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Ready Wallet Instructions:")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        Text("1️⃣ Tap 'Scan' next to Address → scan your Address QR")
                            .font(.caption)
                        Text("2️⃣ Tap 'Scan' next to Private Key → scan your Private Key QR")
                            .font(.caption)
                        Text("3️⃣ Tap 'Scan' next to Public Key → scan your Public Key QR")
                            .font(.caption)
                        Text("4️⃣ Tap 'Connect Wallet' when all 3 are filled ✅")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                

                PrivateKeyScannerView(isPresented: $showAddressScanner) { text in
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("� Scanned ADDRESS: \(trimmed)")
                    address = trimmed
                }
                .sheet(isPresented: $showPrivateKeyScanner) {
                    PrivateKeyScannerView(isPresented: $showPrivateKeyScanner) { text in
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("🔑 Scanned PRIVATE KEY: \(trimmed.prefix(10))...")
                        privateKey = trimmed
                    }
                }
                .sheet(isPresented: $showPublicKeyScanner) {
                    PrivateKeyScannerView(isPresented: $showPublicKeyScanner) { text in
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("� Scanned PUBLIC KEY: \(trimmed.prefix(10))...")
                        publicKey = trimmed
                    }
                }
                
                // Status Summary
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checklist")
                            .foregroundColor(.blue)
                        Text("Scan Progress")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Text("\(scanProgress)/3")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isFormValid ? .green : .orange)
                    }
                    
                    ProgressView(value: Double(scanProgress), total: 3.0)
                        .tint(isFormValid ? .green : .blue)
                    
                    if !isFormValid {
                        Text("Scan all 3 QR codes to enable connection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("✅ All fields ready! Tap Connect below")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // Connect Button
                Button(action: connectManualWallet) {
                    HStack {
                        if starknet.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: isFormValid ? "checkmark.circle.fill" : "lock.circle.fill")
                        }
                        
                        Text(starknet.isLoading ? "Connecting..." : (isFormValid ? "Connect Wallet" : "Scan All 3 QR Codes First"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color(red: 0.8, green: 0.3, blue: 0.3) : Color.gray.opacity(0.3))
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
            .sheet(isPresented: $showAddressScanner) {
                PrivateKeyScannerView(isPresented: $showAddressScanner) { text in
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("📍 Scanned ADDRESS: \(trimmed)")
                    address = trimmed
                }
            }
            .sheet(isPresented: $showPrivateKeyScanner) {
                PrivateKeyScannerView(isPresented: $showPrivateKeyScanner) { text in
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("🔑 Scanned PRIVATE KEY: \(trimmed.prefix(10))...")
                    privateKey = trimmed
                }
            }
            .sheet(isPresented: $showPublicKeyScanner) {
                PrivateKeyScannerView(isPresented: $showPublicKeyScanner) { text in
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("🔓 Scanned PUBLIC KEY: \(trimmed.prefix(10))...")
                    publicKey = trimmed
                }
            }
            .sheet(isPresented: $showBraavosConnect) {
                BraavosConnectView()
            }
        }
    }
    
    private var isFormValid: Bool {
        // Require all three fields to be filled
        return !address.isEmpty && address.hasPrefix("0x") &&
               !privateKey.isEmpty && privateKey.hasPrefix("0x") &&
               !publicKey.isEmpty && publicKey.hasPrefix("0x")
    }
    
    private var scanProgress: Int {
        var count = 0
        if !address.isEmpty && address.hasPrefix("0x") { count += 1 }
        if !privateKey.isEmpty && privateKey.hasPrefix("0x") { count += 1 }
        if !publicKey.isEmpty && publicKey.hasPrefix("0x") { count += 1 }
        return count
    }
    
    private func connectManualWallet() {
        print("\n🔌 ========== MANUAL WALLET CONNECTION ==========")
        print("📍 Address: \(address)")
        print("🔑 Private Key: \(privateKey.prefix(10))...\(privateKey.suffix(4))")
        print("🔓 Public Key: \(publicKey.prefix(10))...\(publicKey.suffix(4))")
        print("✅ All 3 fields present - proceeding with full connection")
        
        // Always use full connect since all fields are required
        starknet.connectWallet(
            address: address,
            privateKey: privateKey,
            publicKey: publicKey
        )
        
        ReadyWalletManager.shared.importFromPrivateKey(address: address, publicKey: publicKey, privateKey: privateKey)
        print("🔌 ========== CONNECTION COMPLETE ==========\n")
        dismiss()
    }
}

struct StarknetConnectView_Previews: PreviewProvider {
    static var previews: some View {
        StarknetConnectView()
    }
}
