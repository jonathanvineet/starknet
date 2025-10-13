//
//  ReadyWalletTestView.swift
//  QRPaymentScanner
//
//  Test view for Ready Wallet integration with Sepolia network
//

import SwiftUI

struct ReadyWalletTestView: View {
    @StateObject private var walletManager = ReadyWalletManager.shared
    @State private var selectedNetwork = "sepolia"
    
    let availableNetworks = ["sepolia", "mainnet", "goerli"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Ready Wallet Integration Test")
                .font(.title)
                .padding()
            
            // Connection Status
            VStack {
                Text("Status: \(walletManager.connectionStatus)")
                    .font(.headline)
                    .foregroundColor(walletManager.isConnected ? .green : .red)
                
                if !walletManager.connectedAddress.isEmpty {
                    Text("Address: \(walletManager.shortAddress)")
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                if !walletManager.errorMessage.isEmpty {
                    Text("Error: \(walletManager.errorMessage)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // Network Selection
            VStack {
                Text("Select Network:")
                    .font(.headline)
                
                Picker("Network", selection: $selectedNetwork) {
                    ForEach(availableNetworks, id: \.self) { network in
                        Text(network.capitalized).tag(network)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Connection Controls
            VStack(spacing: 15) {
                Button(action: {
                    Task {
                        await connectToWallet()
                    }
                }) {
                    HStack {
                        if walletManager.isConnecting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(walletManager.isConnecting ? "Connecting..." : "Connect to Ready Wallet")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(walletManager.isConnecting ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(walletManager.isConnecting || walletManager.isConnected)
                
                if walletManager.isConnected {
                    Button("Disconnect") {
                        walletManager.disconnect()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button("Check if Ready Wallet is Installed") {
                    let isInstalled = walletManager.isReadyWalletInstalled()
                    walletManager.errorMessage = isInstalled ? "✅ Ready Wallet is installed" : "❌ Ready Wallet not found"
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Open App Store") {
                    walletManager.openAppStore()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            // Transaction Test (only if connected)
            if walletManager.isConnected {
                Divider()
                
                VStack(spacing: 10) {
                    Text("Transaction Testing")
                        .font(.headline)
                    
                    Button("Test Transaction Signing") {
                        Task {
                            await testTransactionSigning()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func connectToWallet() async {
        print("🚀 Attempting to connect to Ready Wallet on \(selectedNetwork) network")
        
        let success = await walletManager.connectWallet(network: selectedNetwork)
        
        if success {
            print("✅ Successfully connected to Ready Wallet!")
        } else {
            print("❌ Failed to connect to Ready Wallet")
        }
    }
    
    private func testTransactionSigning() async {
        let mockTransaction: [String: Any] = [
            "to": "0x1234567890123456789012345678901234567890",
            "value": "0x1",
            "data": "0x",
            "gasLimit": "0x5208"
        ]
        
        do {
            let signature = try await walletManager.signTransaction(mockTransaction)
            walletManager.errorMessage = "✅ Transaction signed: \(signature)"
        } catch {
            walletManager.errorMessage = "❌ Signing failed: \(error.localizedDescription)"
        }
    }
}

struct ReadyWalletTestView_Previews: PreviewProvider {
    static var previews: some View {
        ReadyWalletTestView()
    }
}