//
//  ManualWalletImportView.swift
//  QRPaymentScanner
//
//  Manual wallet import for wallets that don't support WalletConnect
//

import SwiftUI

struct ManualWalletImportView: View {
    @StateObject private var starknetManager = StarknetManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var privateKey = ""
    @State private var showingScanner = false
    @State private var isImporting = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("Import Wallet")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Enter or scan your private key from Ready Wallet or Braavos")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How to get your private key:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            InstructionRow(number: "1", text: "Open Ready Wallet or Braavos app")
                            InstructionRow(number: "2", text: "Go to Settings → Security")
                            InstructionRow(number: "3", text: "Export Private Key (requires password)")
                            InstructionRow(number: "4", text: "Copy/paste or scan the QR code below")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Private Key Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Private Key")
                            .font(.headline)
                        
                        HStack {
                            SecureField("0x...", text: $privateKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                            
                            Button(action: { showingScanner = true }) {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.title3)
                                    .padding(8)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Warning
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Security Warning")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            
                            Text("Never share your private key. We'll store it securely in your device's keychain.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Import Button
                    Button(action: importWallet) {
                        if isImporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Import Wallet")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(privateKey.isEmpty ? Color.gray : Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(privateKey.isEmpty || isImporting)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Import Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                NavigationView {
                    PrivateKeyScannerView(isPresented: $showingScanner, onScan: { scannedText in
                        print("✅ [Manual Import] Received scanned text: \(scannedText.prefix(20))...")
                        privateKey = scannedText
                        print("📝 [Manual Import] Private key field updated")
                    })
                    .navigationTitle("Scan Private Key QR")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                print("👆 [Manual Import] User closed scanner manually")
                                showingScanner = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func importWallet() {
        print("🚀 [Manual Import] Starting wallet import...")
        isImporting = true
        errorMessage = ""
        
        // Validate private key format
        let cleanedKey = privateKey.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🔍 [Manual Import] Cleaned key length: \(cleanedKey.count)")
        print("🔍 [Manual Import] Key prefix: \(cleanedKey.prefix(10))")
        
        guard cleanedKey.hasPrefix("0x") && cleanedKey.count > 10 else {
            print("❌ [Manual Import] Validation failed - invalid format")
            errorMessage = "Invalid private key format. Must start with 0x"
            isImporting = false
            return
        }
        print("✅ [Manual Import] Private key validation passed")
        
        // Derive address from private key using starknet.swift
        // For now, we'll need the user to provide the address too
        // In production, derive it from the private key
        
        print("🔄 [Manual Import] Deriving address from private key...")
        // Generate a placeholder address (in production, derive from key)
        let address = cleanedKey // Temporary - should derive actual address
        let publicKey = cleanedKey // Temporary - should derive actual public key
        print("📍 [Manual Import] Generated address: \(address.prefix(20))...")
        print("🔑 [Manual Import] Generated public key: \(publicKey.prefix(20))...")
        
        // Connect to StarknetManager
        print("🔗 [Manual Import] Connecting to StarknetManager...")
        starknetManager.connectWallet(
            address: address,
            privateKey: cleanedKey,
            publicKey: publicKey
        )
        print("✅ [Manual Import] StarknetManager.connectWallet() called")
        
        // Save to keychain
        print("💾 [Manual Import] Saving to keychain...")
        let saved = KeychainHelper.shared.saveStarknetPrivateKey(cleanedKey)
        print("💾 [Manual Import] Keychain save result: \(saved)")
        
        if saved {
            print("✅ [Manual Import] Wallet imported successfully!")
            print("📍 [Manual Import] Address: \(address.prefix(30))...")
            
            // Save address and public key too
            let addressSaved = KeychainHelper.shared.saveStarknetAddress(address)
            let publicKeySaved = KeychainHelper.shared.saveStarknetPublicKey(publicKey)
            print("💾 [Manual Import] Address saved: \(addressSaved)")
            print("💾 [Manual Import] Public key saved: \(publicKeySaved)")
            
            isImporting = false
            print("🎉 [Manual Import] Dismissing import view...")
            dismiss()
        } else {
            print("❌ [Manual Import] Failed to save to keychain")
            errorMessage = "Failed to save to keychain"
            isImporting = false
        }
    }
}

struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number + ".")
                .fontWeight(.bold)
                .frame(width: 20, alignment: .leading)
            Text(text)
        }
    }
}

#Preview {
    ManualWalletImportView()
}
