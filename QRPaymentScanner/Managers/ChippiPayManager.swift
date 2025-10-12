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
    @Published public var currentWalletId: String?
    @Published public var availableServices: [ChippiService] = []
    @Published public var recentTransactions: [ChippiTransactionStatus] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?

    // MARK: - Configuration
    private let api: ChippiPayAPI
    private let keychain = KeychainHelper.shared

    // MARK: - Initialization
    public init(environment: ChippiPayEnvironment = .production) {
        self.api = ChippiPayAPI(environment: environment)
    }
    
    // MARK: - Wallet Management
    
    /// Creates a new ChippiPay gasless wallet for the user
    /// This uses the two-step wallet creation process from ChippiPay
    public func createGaslessWallet(userPassword: String, authToken: String, externalUserId: String) async throws -> ChippiWallet {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            // Step 1: Prepare wallet creation
            let prepareResponse = try await api.prepareWalletCreation(
                authToken: authToken,
                externalUserId: externalUserId,
                metadata: ["source": "ios_app"]
            )

            // Step 2: Save wallet to ChippiPay
            let saveSuccess = try await api.saveWallet(
                walletId: prepareResponse.walletId,
                publicKey: prepareResponse.publicKey,
                encryptedPrivateKey: prepareResponse.encryptedPrivateKey,
                authToken: authToken
            )

            guard saveSuccess else {
                throw ChippiPayError.apiError("Failed to save wallet")
            }

            // Create wallet object
            let wallet = ChippiWallet(
                publicKey: prepareResponse.publicKey,
                encryptedPrivateKey: prepareResponse.encryptedPrivateKey
            )

            // Store wallet locally
            currentWallet = wallet
            currentWalletId = prepareResponse.walletId
            isConnected = true

            // Optionally save wallet ID to keychain for persistence
            _ = keychain.save(key: "chipi_wallet_id", object: prepareResponse.walletId)

            return wallet

        } catch {
            errorMessage = "Wallet creation failed: \(error.localizedDescription)"
            throw error
        }
    }

    /// Load existing wallet from keychain
    public func loadExistingWallet() {
        if let walletId: String = keychain.retrieve(key: "chipi_wallet_id", type: String.self) {
            currentWalletId = walletId
            isConnected = true
        }
    }
    
    // MARK: - Service Discovery
    
    /// Fetches available services from ChippiPay
    public func fetchAvailableServices(categories: [String] = []) async throws {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            // If specific categories requested, fetch each separately
            if !categories.isEmpty {
                var allServices: [ChippiService] = []
                for category in categories {
                    let services = try await api.fetchSKUs(category: category)
                    allServices.append(contentsOf: services)
                }
                availableServices = allServices
            } else {
                // Fetch all services
                let services = try await api.fetchSKUs()
                availableServices = services
            }

        } catch {
            errorMessage = "Failed to fetch services: \(error.localizedDescription)"

            // Fallback to mock data if API fails (for development)
            availableServices = getMockServices()

            throw error
        }
    }

    /// Mock services for development/fallback
    private func getMockServices() -> [ChippiService] {
        return [
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
    }
    
    // MARK: - Payment Processing
    
    /// Purchase a service using STRK from the vault
    /// This connects your vault withdrawal with ChippiPay service purchase
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

        guard let walletId = currentWalletId else {
            throw ChippiPayError.walletNotConnected
        }

        do {
            // Create SKU transaction via ChippiPay API
            let transactionResponse = try await api.createSKUTransaction(
                skuId: skuId,
                reference: reference,
                amount: amount > 0 ? amount : nil,
                walletId: walletId,
                vaultTransactionHash: vaultTransactionHash,
                metadata: ["platform": "ios", "app_version": "1.0"]
            )

            // Create purchase result
            let result = ChippiPurchaseResult(
                success: true,
                transactionId: transactionResponse.transactionId,
                status: transactionResponse.status,
                message: "Service purchased successfully"
            )

            // Add to recent transactions
            let transaction = ChippiTransactionStatus(
                id: transactionResponse.transactionId,
                status: transactionResponse.status,
                service: transactionResponse.skuId,
                amount: transactionResponse.amount,
                createdAt: transactionResponse.createdAt
            )

            recentTransactions.insert(transaction, at: 0)

            return result

        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Transaction Monitoring
    
    /// Check the status of a ChippiPay transaction
    public func checkTransactionStatus(transactionId: String) async throws -> ChippiTransactionStatus {
        do {
            let response = try await api.getTransactionStatus(transactionId: transactionId)

            let status = ChippiTransactionStatus(
                id: response.transactionId,
                status: response.status,
                service: response.skuId,
                amount: response.amount,
                createdAt: response.createdAt
            )

            // Update local transactions list
            if let index = recentTransactions.firstIndex(where: { $0.id == transactionId }) {
                recentTransactions[index] = status
            }

            return status

        } catch {
            throw ChippiPayError.apiError("Failed to check transaction status: \(error.localizedDescription)")
        }
    }

    /// Poll transaction status until completed or failed
    public func pollTransactionStatus(transactionId: String, maxAttempts: Int = 10) async throws -> ChippiTransactionStatus {
        for attempt in 1...maxAttempts {
            let status = try await checkTransactionStatus(transactionId: transactionId)

            if status.status == "completed" || status.status == "failed" {
                return status
            }

            // Wait before next poll (exponential backoff)
            let delay = UInt64(min(attempt * 2, 10)) * 1_000_000_000
            try await Task.sleep(nanoseconds: delay)
        }

        throw ChippiPayError.apiError("Transaction status polling timeout")
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