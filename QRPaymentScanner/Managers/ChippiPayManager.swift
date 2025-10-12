import Foundation
import SwiftUI

// MARK: - ChippiPay API Environment

public enum ChippiPayEnvironment {
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

// MARK: - API Response Models

public struct ChippiAPIResponse<T: Codable>: Codable {
    public let success: Bool
    public let data: T?
    public let error: ChippiAPIError?
    public let message: String?
}

public struct ChippiAPIError: Codable {
    public let code: String
    public let message: String
    public let details: String?
}

// MARK: - Wallet Creation Models

public struct WalletPrepareRequest: Codable {
    public let authToken: String
    public let externalUserId: String
    public let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case authToken = "auth_token"
        case externalUserId = "external_user_id"
        case metadata
    }
}

public struct WalletPrepareResponse: Codable {
    public let publicKey: String
    public let encryptedPrivateKey: String
    public let walletId: String

    enum CodingKeys: String, CodingKey {
        case publicKey = "public_key"
        case encryptedPrivateKey = "encrypted_private_key"
        case walletId = "wallet_id"
    }
}

public struct WalletSaveRequest: Codable {
    public let walletId: String
    public let publicKey: String
    public let encryptedPrivateKey: String
    public let authToken: String

    enum CodingKeys: String, CodingKey {
        case walletId = "wallet_id"
        case publicKey = "public_key"
        case encryptedPrivateKey = "encrypted_private_key"
        case authToken = "auth_token"
    }
}

// MARK: - Service/SKU Models

public struct SKUListResponse: Codable {
    public let skus: [ChippiService]
    public let total: Int
    public let page: Int
    public let perPage: Int

    enum CodingKeys: String, CodingKey {
        case skus
        case total
        case page
        case perPage = "per_page"
    }
}

// MARK: - Transaction Models

public struct SKUTransactionRequest: Codable {
    public let skuId: String
    public let reference: String
    public let amount: Double?
    public let walletId: String
    public let vaultTransactionHash: String
    public let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case skuId = "sku_id"
        case reference
        case amount
        case walletId = "wallet_id"
        case vaultTransactionHash = "vault_transaction_hash"
        case metadata
    }
}

public struct SKUTransactionResponse: Codable {
    public let transactionId: String
    public let status: String
    public let skuId: String
    public let amount: Double
    public let reference: String
    public let createdAt: String

    enum CodingKeys: String, CodingKey {
        case transactionId = "transaction_id"
        case status
        case skuId = "sku_id"
        case amount
        case reference
        case createdAt = "created_at"
    }
}

// MARK: - ChippiPayAPI Client

public class ChippiPayAPI {

    // MARK: - Properties

    private let environment: ChippiPayEnvironment
    private let apiKey: String
    private let secretKey: String
    private let session: URLSession

    // MARK: - Initialization

    public init(environment: ChippiPayEnvironment = .production) {
        self.environment = environment

        // Retrieve API keys from Keychain
        let keychain = KeychainHelper.shared
        self.apiKey = keychain.getChippiPayAPIKey() ?? ""
        self.secretKey = keychain.getChippiPaySecretKey() ?? ""

        // Configure URL session with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Wallet Management

    /// Prepare wallet creation - Step 1
    public func prepareWalletCreation(authToken: String, externalUserId: String, metadata: [String: String]? = nil) async throws -> WalletPrepareResponse {
        let endpoint = "/chipi-wallets/prepare-creation"
        let request = WalletPrepareRequest(
            authToken: authToken,
            externalUserId: externalUserId,
            metadata: metadata
        )

        let response: ChippiAPIResponse<WalletPrepareResponse> = try await post(endpoint: endpoint, body: request)

        guard response.success, let data = response.data else {
            throw ChippiPayAPIError.apiError(response.error?.message ?? "Wallet preparation failed")
        }

        return data
    }

    /// Save wallet - Step 2
    public func saveWallet(walletId: String, publicKey: String, encryptedPrivateKey: String, authToken: String) async throws -> Bool {
        let endpoint = "/chipi-wallets"
        let request = WalletSaveRequest(
            walletId: walletId,
            publicKey: publicKey,
            encryptedPrivateKey: encryptedPrivateKey,
            authToken: authToken
        )

        let response: ChippiAPIResponse<[String: String]> = try await post(endpoint: endpoint, body: request)
        return response.success
    }

    // MARK: - Service/SKU Management

    /// Fetch available services (SKUs)
    public func fetchSKUs(category: String? = nil, page: Int = 1, perPage: Int = 50) async throws -> [ChippiService] {
        var endpoint = "/skus?page=\(page)&per_page=\(perPage)"

        if let category = category {
            endpoint += "&category=\(category)"
        }

        let response: ChippiAPIResponse<SKUListResponse> = try await get(endpoint: endpoint)

        guard response.success, let data = response.data else {
            throw ChippiPayAPIError.apiError(response.error?.message ?? "Failed to fetch services")
        }

        return data.skus
    }

    /// Check SKU reference validity
    public func checkSKUReference(skuId: String, reference: String) async throws -> Bool {
        let endpoint = "/skus/\(skuId)/check-reference"
        let body = ["reference": reference]

        let response: ChippiAPIResponse<[String: Bool]> = try await post(endpoint: endpoint, body: body)

        guard response.success, let data = response.data, let isValid = data["is_valid"] else {
            return false
        }

        return isValid
    }

    // MARK: - Transaction Management

    /// Purchase a service (create SKU transaction)
    public func createSKUTransaction(
        skuId: String,
        reference: String,
        amount: Double?,
        walletId: String,
        vaultTransactionHash: String,
        metadata: [String: String]? = nil
    ) async throws -> SKUTransactionResponse {
        let endpoint = "/sku-transactions"
        let request = SKUTransactionRequest(
            skuId: skuId,
            reference: reference,
            amount: amount,
            walletId: walletId,
            vaultTransactionHash: vaultTransactionHash,
            metadata: metadata
        )

        let response: ChippiAPIResponse<SKUTransactionResponse> = try await post(endpoint: endpoint, body: request)

        guard response.success, let data = response.data else {
            throw ChippiPayAPIError.apiError(response.error?.message ?? "Transaction failed")
        }

        return data
    }

    /// Get transaction status
    public func getTransactionStatus(transactionId: String) async throws -> SKUTransactionResponse {
        let endpoint = "/sku-transactions/\(transactionId)"

        let response: ChippiAPIResponse<SKUTransactionResponse> = try await get(endpoint: endpoint)

        guard response.success, let data = response.data else {
            throw ChippiPayAPIError.apiError(response.error?.message ?? "Failed to fetch transaction status")
        }

        return data
    }

    // MARK: - HTTP Methods

    /// Generic GET request
    private func get<T: Codable>(endpoint: String) async throws -> T {
        let url = URL(string: environment.baseURL + endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addHeaders(to: &request)

        return try await performRequest(request: request)
    }

    /// Generic POST request
    private func post<T: Codable, B: Codable>(endpoint: String, body: B) async throws -> T {
        let url = URL(string: environment.baseURL + endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addHeaders(to: &request)

        request.httpBody = try JSONEncoder().encode(body)

        return try await performRequest(request: request)
    }

    /// Add authentication headers
    private func addHeaders(to request: inout URLRequest) {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(secretKey)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
    }

    /// Perform URLRequest and decode response
    private func performRequest<T: Codable>(request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChippiPayAPIError.networkError("Invalid response")
        }

        // Log response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("ChippiPay API Response (\(httpResponse.statusCode)): \(responseString)")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to decode error response
            if let errorResponse = try? JSONDecoder().decode(ChippiAPIResponse<T>.self, from: data) {
                throw ChippiPayAPIError.apiError(errorResponse.error?.message ?? "API error \(httpResponse.statusCode)")
            }
            throw ChippiPayAPIError.httpError(httpResponse.statusCode)
        }

        do {
            let decodedResponse = try JSONDecoder().decode(T.self, from: data)
            return decodedResponse
        } catch {
            print("Decoding error: \(error)")
            throw ChippiPayAPIError.decodingError(error.localizedDescription)
        }
    }
}

// MARK: - ChippiPay API Error Types

public enum ChippiPayAPIError: LocalizedError {
    case networkError(String)
    case apiError(String)
    case httpError(Int)
    case decodingError(String)
    case missingCredentials
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .missingCredentials:
            return "ChippiPay API credentials not configured"
        case .invalidResponse:
            return "Invalid API response"
        }
    }
}

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