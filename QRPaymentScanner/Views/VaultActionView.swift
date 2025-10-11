//
//  VaultActionView.swift
//  QRPaymentScanner
//
//  Vault actions: Deposit, Withdraw, Transfer
//

import SwiftUI

public struct VaultActionView: View {
    public enum ActionType {
        case deposit, withdraw, transfer
        
        var title: String {
            switch self {
            case .deposit: return "Deposit STRK"
            case .withdraw: return "Withdraw STRK"
            case .transfer: return "Transfer STRK"
            }
        }
        
        var icon: String {
            switch self {
            case .deposit: return "plus.circle.fill"
            case .withdraw: return "minus.circle.fill"
            case .transfer: return "arrow.right.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .deposit: return .green
            case .withdraw: return .orange
            case .transfer: return .blue
            }
        }
    }
    
    public let actionType: ActionType
    @StateObject private var starknet = StarknetManager.shared
    @State private var amount = ""
    @State private var recipientAddress = ""
    @State private var showingSuccess = false
    @State private var showingError = false
    @Environment(\.dismiss) private var dismiss
    
    public init(actionType: ActionType) {
        self.actionType = actionType
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: actionType.icon)
                        .font(.system(size: 50))
                        .foregroundColor(actionType.color)
                    
                    Text(actionType.title)
                        .font(.system(size: 24, weight: .bold))
                    
                    // Balance Display
                    VStack(spacing: 4) {
                        Text("Available Balances")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 20) {
                            VStack(spacing: 2) {
                                Text("Wallet")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                Text("\(String(format: "%.4f", starknet.strkBalance)) STRK")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            
                            VStack(spacing: 2) {
                                Text("Vault")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                Text("\(String(format: "%.4f", starknet.vaultBalance)) STRK")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(actionType.color)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.top, 20)
                
                // Amount Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount (STRK)")
                        .font(.system(size: 16, weight: .medium))
                    
                    HStack {
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 20, weight: .semibold))
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        
                        Button("Max") {
                            amount = String(format: "%.6f", maxAmount)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(actionType.color.opacity(0.1))
                        .foregroundColor(actionType.color)
                        .cornerRadius(8)
                    }
                }
                
                // Quick Amount Buttons
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach([0.1, 0.5, 1.0, 5.0], id: \.self) { value in
                        Button("\(value, specifier: "%.1f")") {
                            amount = String(format: "%.1f", value)
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // Recipient Address (for withdraw and transfer)
                if actionType == .withdraw || actionType == .transfer {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(actionType == .withdraw ? "Withdraw To Address" : "Recipient Address")
                            .font(.system(size: 16, weight: .medium))
                        
                        TextField("0x...", text: $recipientAddress)
                            .font(.system(size: 14, design: .monospaced))
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        
                        if actionType == .withdraw {
                            Button("Use My Address") {
                                recipientAddress = starknet.userAddress
                            }
                            .font(.system(size: 14))
                            .foregroundColor(actionType.color)
                        }
                    }
                }
                
                Spacer()
                
                // Action Button
                Button(action: performAction) {
                    HStack {
                        if starknet.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: actionType.icon)
                        }
                        
                        Text(starknet.isLoading ? "Processing..." : actionType.title)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? actionType.color : Color.gray)
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
            }
            .padding(.horizontal, 20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Success!", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("\(actionType.title) completed successfully!")
        }
        .onAppear {
            // Load fresh balances when view appears
            Task {
                await starknet.loadBalances()
            }
        }
    }
    
    private var maxAmount: Double {
        switch actionType {
        case .deposit:
            return starknet.strkBalance
        case .withdraw, .transfer:
            return starknet.vaultBalance
        }
    }
    
    private var isFormValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else {
            return false
        }
        
        if actionType == .withdraw || actionType == .transfer {
            return !recipientAddress.isEmpty && recipientAddress.hasPrefix("0x")
        }
        
        return true
    }
    
    private func performAction() {
        guard let amountValue = Double(amount) else { return }
        
        Task {
            var success = false
            
            switch actionType {
            case .deposit:
                success = await starknet.depositToVault(amount: amountValue)
            case .withdraw:
                success = await starknet.withdrawFromVault(amount: amountValue, toAddress: recipientAddress)
            case .transfer:
                success = await starknet.transferToUser(toAddress: recipientAddress, amount: amountValue)
            }
            
            await MainActor.run {
                if success {
                    showingSuccess = true
                }
            }
        }
    }
}

struct VaultActionView_Previews: PreviewProvider {
    static var previews: some View {
        VaultActionView(actionType: .deposit)
    }
}