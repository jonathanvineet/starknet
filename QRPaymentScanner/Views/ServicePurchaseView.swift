import SwiftUI

struct ServicePurchaseView: View {
    let service: ChippiService
    @ObservedObject var chippiPayManager: ChippiPayManager
    @ObservedObject var starknetManager: StarknetManager
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var referenceInput = ""
    @State private var customAmount = ""
    @State private var isPurchasing = false
    @State private var showConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var purchaseResult: ChippiPurchaseResult?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Service Header
                    serviceHeader
                    
                    // Purchase Form
                    purchaseForm
                    
                    // Cost Breakdown
                    costBreakdown
                    
                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Purchase Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Purchase Successful!", isPresented: $showConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                if let result = purchaseResult {
                    Text("Transaction ID: \(result.transactionId ?? "Unknown")\n\nYour service has been processed successfully!")
                }
            }
        }
    }
    
    // MARK: - Service Header
    private var serviceHeader: some View {
        VStack(spacing: 16) {
            // Service Icon
            Image(systemName: iconForCategory(service.category))
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .padding()
                .background(Circle().fill(Color.blue.opacity(0.1)))
            
            // Service Details
            VStack(spacing: 8) {
                Text(service.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                if let description = service.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Category Badge
                Text(service.category)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Purchase Form
    private var purchaseForm: some View {
        VStack(spacing: 20) {
            Text("Purchase Details")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Reference Input
            VStack(alignment: .leading, spacing: 8) {
                Text(service.referenceLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Enter \(service.referenceLabel.lowercased())", text: $referenceInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(service.referenceLabel.contains("Email") ? .none : .words)
                    .keyboardType(service.referenceLabel.contains("Phone") ? .phonePad : .default)
                
                if service.canCheckSkuReference {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                        Text("This reference will be validated")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Amount Input
            VStack(alignment: .leading, spacing: 8) {
                Text(service.amountLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let fixedAmount = service.fixedAmount {
                    HStack {
                        Text("$\(fixedAmount, specifier: "%.2f") MXN")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        Spacer()
                        Text("Fixed Amount")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    TextField("Enter amount", text: $customAmount)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Cost Breakdown
    private var costBreakdown: some View {
        VStack(spacing: 16) {
            Text("Cost Breakdown")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                // Service Cost
                HStack {
                    Text("Service Cost:")
                    Spacer()
                    Text("$\(totalMXNAmount, specifier: "%.2f") MXN")
                        .fontWeight(.semibold)
                }
                
                // STRK Equivalent
                HStack {
                    Text("STRK Equivalent:")
                    Spacer()
                    Text("\(strkAmount, specifier: "%.4f") STRK")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                Divider()
                
                // Fees
                HStack {
                    Text("ChippiPay Fee:")
                    Spacer()
                    HStack {
                        Text("FREE")
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
                
                HStack {
                    Text("Gas Fee:")
                    Spacer()
                    HStack {
                        Text("FREE")
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
                
                Divider()
                
                // Total
                HStack {
                    Text("Total Cost:")
                        .font(.headline)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("\(strkAmount, specifier: "%.4f") STRK")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("$\(totalMXNAmount, specifier: "%.2f") MXN")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Savings Highlight
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gasless Transaction")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Save ~$0.50 in gas fees with ChippiPay")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: purchaseService) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "bolt.fill")
                    }
                    Text(isPurchasing ? "Processing..." : "Purchase with ChippiPay")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canPurchase || isPurchasing)
            .frame(maxWidth: .infinity)
            
            // Wallet Status Check
            if !chippiPayManager.isConnected {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("ChippiPay wallet required")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal)
            }
            
            // Vault Balance Check
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Funds will be deducted from your vault balance")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Computed Properties
    private var totalMXNAmount: Double {
        if let fixedAmount = service.fixedAmount {
            return fixedAmount
        } else {
            return Double(customAmount) ?? 0.0
        }
    }
    
    private var strkAmount: Double {
        chippiPayManager.calculateSTRKAmount(for: totalMXNAmount)
    }
    
    private var canPurchase: Bool {
        guard chippiPayManager.isConnected else { return false }
        guard !referenceInput.isEmpty else { return false }
        
        if service.fixedAmount == nil {
            guard !customAmount.isEmpty, Double(customAmount) != nil, Double(customAmount)! > 0 else {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Helper Methods
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "TELEFONIA":
            return "phone.fill"
        case "LUZ":
            return "lightbulb.fill"
        case "INTERNET":
            return "wifi"
        case "GIFT_CARDS":
            return "gift.fill"
        case "GAMING":
            return "gamecontroller.fill"
        case "STREAMING":
            return "play.tv.fill"
        default:
            return "rectangle.grid.2x2.fill"
        }
    }
    
    private func purchaseService() {
        isPurchasing = true
        
        Task {
            do {
                // First, simulate withdrawing STRK from vault for the purchase
                let mockTxHash = "0x" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
                
                // Purchase through ChippiPay
                let result = try await chippiPayManager.purchaseService(
                    skuId: service.id,
                    amount: totalMXNAmount,
                    reference: referenceInput,
                    vaultTransactionHash: mockTxHash
                )
                
                await MainActor.run {
                    isPurchasing = false
                    purchaseResult = result
                    showConfirmation = true
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Preview
struct ServicePurchaseView_Previews: PreviewProvider {
    static var previews: some View {
        ServicePurchaseView(
            service: ChippiService(
                id: "telcel_50",
                providerId: "telcel",
                name: "Telcel 50 MXN Top-up",
                description: "Mobile phone credit for Telcel network",
                category: "TELEFONIA",
                fixedAmount: 50.0,
                logoUrl: nil,
                referenceLabel: "Phone Number",
                amountLabel: "Amount (MXN)",
                canCheckSkuReference: true
            ),
            chippiPayManager: ChippiPayManager(),
            starknetManager: StarknetManager.shared
        )
    }
}