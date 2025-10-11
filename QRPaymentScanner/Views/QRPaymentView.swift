//
//  QRPaymentView.swift
//  QRPaymentScanner
//
//  QR Code payment processing with Starknet vault integration
//

import SwiftUI
import AVFoundation

public struct QRPaymentView: View {
    @StateObject private var starknet = StarknetManager.shared
    @State private var scannedData = ""
    @State private var paymentAmount: Double = 0.0
    @State private var recipientAddress = ""
    @State private var merchantName = ""
    @State private var paymentDescription = ""
    @State private var showingPaymentConfirmation = false
    @State private var showingPaymentSuccess = false
    @State private var isProcessingPayment = false
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 50))
                        .foregroundColor(Color(red: 0.8, green: 0.3, blue: 0.3))
                    
                    Text("QR Payment")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Scan QR code to make instant payments")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // QR Scanner Area
                ZStack {
                    Rectangle()
                        .fill(Color.black.opacity(0.1))
                        .frame(height: 250)
                        .cornerRadius(20)
                    
                    VStack(spacing: 16) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Position QR code in the frame")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        
                        Button("Scan QR Code") {
                            // In a real implementation, this would open the camera
                            simulateQRScan()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.8, green: 0.3, blue: 0.3))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
                
                // Manual Entry Option
                VStack(alignment: .leading, spacing: 16) {
                    Text("Or enter payment details manually:")
                        .font(.system(size: 16, weight: .medium))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recipient Address")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        TextField("0x...", text: $recipientAddress)
                            .font(.system(size: 14, design: .monospaced))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amount (STRK)")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            TextField("0.00", value: $paymentAmount, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Merchant")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            TextField("Store name", text: $merchantName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        TextField("Payment for...", text: $paymentDescription)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Payment Button
                Button(action: {
                    if starknet.isConnected {
                        showingPaymentConfirmation = true
                    } else {
                        // Show connect wallet message
                    }
                }) {
                    HStack {
                        if isProcessingPayment {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "creditcard.fill")
                        }
                        
                        Text(isProcessingPayment ? "Processing..." : "Pay with Vault")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canMakePayment ? Color(red: 0.8, green: 0.3, blue: 0.3) : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!canMakePayment || isProcessingPayment)
                .padding(.horizontal, 20)
                
                // Balance Info
                if starknet.isConnected {
                    HStack {
                        Text("Vault Balance:")
                        Spacer()
                        Text("\(String(format: "%.4f", starknet.vaultBalance)) STRK")
                            .fontWeight(.semibold)
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .confirmationDialog("Confirm Payment", isPresented: $showingPaymentConfirmation, titleVisibility: .visible) {
            Button("Pay \(String(format: "%.4f", paymentAmount)) STRK") {
                processPayment()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Send \(String(format: "%.4f", paymentAmount)) STRK to \(merchantName.isEmpty ? "recipient" : merchantName)?")
        }
        .alert("Payment Successful!", isPresented: $showingPaymentSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your payment has been processed successfully.")
        }
    }
    
    private var canMakePayment: Bool {
        !recipientAddress.isEmpty &&
        recipientAddress.hasPrefix("0x") &&
        paymentAmount > 0 &&
        paymentAmount <= starknet.vaultBalance &&
        starknet.isConnected
    }
    
    private func simulateQRScan() {
        // Simulate scanning a QR code with payment data
        let mockQRData = """
        {
            "type": "starknet_payment",
            "recipient": "0x057d0fb86ba9a76d97d00bcd5b61379773070f7451a2ddb4ccb0d04d71586473",
            "amount": "0.1",
            "merchant": "Coffee Shop",
            "description": "Cappuccino"
        }
        """
        
        parseQRData(mockQRData)
    }
    
    private func parseQRData(_ data: String) {
        // In a real implementation, this would parse the QR code data
        // For demo purposes, we'll use mock data
        recipientAddress = "0x057d0fb86ba9a76d97d00bcd5b61379773070f7451a2ddb4ccb0d04d71586473"
        paymentAmount = 0.1
        merchantName = "Coffee Shop"
        paymentDescription = "Cappuccino"
        
        showingPaymentConfirmation = true
    }
    
    private func processPayment() {
        isProcessingPayment = true
        
        Task {
            let success = await starknet.transferToUser(
                toAddress: recipientAddress,
                amount: paymentAmount
            )
            
            await MainActor.run {
                isProcessingPayment = false
                if success {
                    showingPaymentSuccess = true
                }
            }
        }
    }
}

struct QRPaymentView_Previews: PreviewProvider {
    static var previews: some View {
        QRPaymentView()
    }
}