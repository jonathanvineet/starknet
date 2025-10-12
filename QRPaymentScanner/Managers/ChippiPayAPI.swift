//
//  ChippiPayAPI.swift
//  QRPaymentScanner
//
//  REST API client for ChippiPay integration
//  Handles all HTTP requests to ChippiPay endpoints
//

import Foundation

// MARK: - Environment Configuration

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

// MARK: - Error Types

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
