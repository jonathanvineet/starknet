import SwiftUI

public struct ChippiPayServicesView: View {
    @StateObject private var chippiPayManager = ChippiPayManager()
    @StateObject private var starknetManager = StarknetManager.shared
    
    @State private var selectedService: ChippiService?
    @State private var referenceInput = ""
    @State private var customAmount = ""
    @State private var showingPurchaseConfirmation = false
    @State private var showingWalletCreation = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    headerSection
                    
                    // Wallet Status
                    walletStatusSection
                    
                    // Services Grid
                    if !chippiPayManager.availableServices.isEmpty {
                        servicesSection
                    }
                    
                    // Recent Transactions
                    if !chippiPayManager.recentTransactions.isEmpty {
                        recentTransactionsSection
                    }
                }
                .padding()
            }
            .navigationTitle("ChippiPay Services")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await loadServices()
                }
            }
            .sheet(isPresented: $showingWalletCreation) {
                ChippiWalletCreationView(chippiPayManager: chippiPayManager)
            }
            .sheet(item: $selectedService) { service in
                ServicePurchaseView(
                    service: service,
                    chippiPayManager: chippiPayManager,
                    starknetManager: starknetManager
                )
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "bolt.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Gasless Payments")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Pay for services without gas fees using ChippiPay")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Wallet Status Section
    private var walletStatusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("ChippiPay Wallet")
                    .font(.headline)
                Spacer()
                
                if chippiPayManager.isConnected {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Connected")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("Not Connected")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            if chippiPayManager.isConnected {
                if let wallet = chippiPayManager.currentWallet {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Wallet Address:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        Text(wallet.publicKey)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(2)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            } else {
                Button("Create Gasless Wallet") {
                    showingWalletCreation = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Services Section
    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Services")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(chippiPayManager.availableServices) { service in
                    ServiceCard(service: service) {
                        selectedService = service
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Transactions Section
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transactions")
                .font(.headline)
            
            ForEach(chippiPayManager.recentTransactions, id: \.id) { transaction in
                TransactionRow(transaction: transaction)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadServices() async {
        do {
            try await chippiPayManager.fetchAvailableServices()
        } catch {
            print("Error loading services: \(error)")
        }
    }
}

// MARK: - Service Card Component
struct ServiceCard: View {
    let service: ChippiService
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Service Icon
            Image(systemName: iconForCategory(service.category))
                .font(.system(size: 30))
                .foregroundColor(.blue)
            
            // Service Name
            Text(service.name)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Fixed Amount or Variable
            if let fixedAmount = service.fixedAmount {
                Text("$\(fixedAmount, specifier: "%.0f") MXN")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            } else {
                Text("Variable Amount")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Category Badge
            Text(service.category)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onTapGesture {
            onSelect()
        }
    }
    
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
}

// MARK: - Transaction Row Component
struct TransactionRow: View {
    let transaction: ChippiTransactionStatus
    
    var body: some View {
        HStack {
            // Status Icon
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.service)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(transaction.id)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(transaction.amount, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(transaction.status.capitalized)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch transaction.status {
        case "completed":
            return .green
        case "pending":
            return .orange
        case "failed":
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - Preview
struct ChippiPayServicesView_Previews: PreviewProvider {
    static var previews: some View {
        ChippiPayServicesView()
    }
}