import Foundation
import SwiftUI

// MARK: - ChippiPay Data Models
public struct ChippiWallet: Codable {
    public let publicKey: String
    public let encryptedPrivateKey: String
    
    public init(publicKey: String, encryptedPrivateKey: String) {
        self.publicKey = publicKey
        self.encryptedPrivateKey = encryptedPrivateKey
    }
}

public struct ChippiService: Codable, Identifiable {
    public let id: String
    public let providerId: String
    public let name: String
    public let description: String?
    public let category: String
    public let fixedAmount: Double?
    public let logoUrl: String?
    public let referenceLabel: String
    public let amountLabel: String
    public let canCheckSkuReference: Bool
    
    public init(id: String, providerId: String, name: String, description: String?, category: String, fixedAmount: Double?, logoUrl: String?, referenceLabel: String, amountLabel: String, canCheckSkuReference: Bool) {
        self.id = id
        self.providerId = providerId
        self.name = name
        self.description = description
        self.category = category
        self.fixedAmount = fixedAmount
        self.logoUrl = logoUrl
        self.referenceLabel = referenceLabel
        self.amountLabel = amountLabel
        self.canCheckSkuReference = canCheckSkuReference
    }
}

public struct ChippiPurchaseResult: Codable {
    public let success: Bool
    public let transactionId: String?
    public let status: String
    public let message: String?
    
    public init(success: Bool, transactionId: String?, status: String, message: String?) {
        self.success = success
        self.transactionId = transactionId
        self.status = status
        self.message = message
    }
}

public struct ChippiTransactionStatus: Codable {
    public let id: String
    public let status: String // "pending", "completed", "failed"
    public let service: String
    public let amount: Double
    public let createdAt: String
    
    public init(id: String, status: String, service: String, amount: Double, createdAt: String) {
        self.id = id
        self.status = status
        self.service = service
        self.amount = amount
        self.createdAt = createdAt
    }
}

// MARK: - ChippiPay Manager
@MainActor
public class ChippiPayManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var isConnected = false
    @Published public var currentWallet: ChippiWallet?
    @Published public var availableServices: [ChippiService] = []
    @Published public var recentTransactions: [ChippiTransactionStatus] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    // MARK: - Configuration
    private let apiKey = "pk_prod_your_api_key_here" // Replace with actual key
    private let secretKey = "sk_prod_your_secret_key_here" // Replace with actual key
    private let baseURL = "https://api.chipipay.com/v1"
    
    // MARK: - Wallet Management
    
    /// Creates a new ChippiPay gasless wallet for the user
    public func createGaslessWallet(userPassword: String, authToken: String, externalUserId: String) async throws -> ChippiWallet {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // For now, simulate the wallet creation process
        // In production, this would call the actual ChippiPay API
        
        try await Task.sleep(nanoseconds: 2_000_000_000) // Simulate network delay
        
        // Simulate successful wallet creation
        let mockWallet = ChippiWallet(
            publicKey: "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7",
            encryptedPrivateKey: "encrypted_private_key_here"
        )
        
        currentWallet = mockWallet
        isConnected = true
        
        return mockWallet
    }
    
    // MARK: - Service Discovery
    
    /// Fetches available services from ChippiPay
    public func fetchAvailableServices(categories: [String] = []) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // Simulate API call to fetch services
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock services data
        let mockServices = [
            ChippiService(
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
            ChippiService(
                id: "cfe_electricity",
                providerId: "cfe",
                name: "CFE Electricity Payment",
                description: "Pay your CFE electricity bill",
                category: "LUZ",
                fixedAmount: nil,
                logoUrl: nil,
                referenceLabel: "Service Number",
                amountLabel: "Amount (MXN)",
                canCheckSkuReference: true
            ),
            ChippiService(
                id: "spotify_gift",
                providerId: "spotify",
                name: "Spotify Gift Card 100 MXN",
                description: "Spotify premium subscription gift card",
                category: "GIFT_CARDS",
                fixedAmount: 100.0,
                logoUrl: nil,
                referenceLabel: "Email",
                amountLabel: "Amount (MXN)",
                canCheckSkuReference: false
            )
        ]
        
        availableServices = mockServices
    }
    
    // MARK: - Payment Processing
    
    /// Purchase a service using STRK from the vault
    public func purchaseService(
        skuId: String,
        amount: Double,
        reference: String,
        vaultTransactionHash: String
    ) async throws -> ChippiPurchaseResult {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let wallet = currentWallet else {
            throw ChippiPayError.walletNotConnected
        }
        
        // Simulate payment processing
        try await Task.sleep(nanoseconds: 3_000_000_000)
        
        // Simulate successful purchase
        let result = ChippiPurchaseResult(
            success: true,
            transactionId: "chipi_tx_" + UUID().uuidString.prefix(8),
            status: "completed",
            message: "Service purchased successfully"
        )
        
        // Add to recent transactions
        let transaction = ChippiTransactionStatus(
            id: result.transactionId ?? "unknown",
            status: "completed",
            service: skuId,
            amount: amount,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        
        recentTransactions.insert(transaction, at: 0)
        
        return result
    }
    
    // MARK: - Transaction Monitoring
    
    /// Check the status of a ChippiPay transaction
    func checkTransactionStatus(transactionId: String) async throws -> ChippiTransactionStatus {
        // Simulate API call
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Return mock status
        return ChippiTransactionStatus(
            id: transactionId,
            status: "completed",
            service: "telcel_50",
            amount: 50.0,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    // MARK: - Helper Methods
    
    public func disconnect() {
        currentWallet = nil
        isConnected = false
        availableServices = []
        recentTransactions = []
    }
    
    public func calculateSTRKAmount(for mxnAmount: Double) -> Double {
        // Mock conversion rate: 1 STRK = 20 MXN
        return mxnAmount / 20.0
    }
}

// MARK: - Error Types
enum ChippiPayError: LocalizedError {
    case walletNotConnected
    case invalidAmount
    case networkError(String)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .walletNotConnected:
            return "ChippiPay wallet not connected"
        case .invalidAmount:
            return "Invalid payment amount"
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

// MARK: - ChippiPay Configuration
struct ChippiPayConfig {
    static let apiKey = ProcessInfo.processInfo.environment["CHIPPI_API_KEY"] ?? "pk_test_default"
    static let secretKey = ProcessInfo.processInfo.environment["CHIPPI_SECRET_KEY"] ?? "sk_test_default"
    static let baseURL = "https://api.chipipay.com/v1"
    static let environment: Environment = .development
    
    enum Environment {
        case development
        case production
        
        var baseURL: String {
            switch self {
            case .development:
                return "https://api-dev.chipipay.com/v1"
            case .production:
                return "https://api.chipipay.com/v1"
            }
        }
    }
}