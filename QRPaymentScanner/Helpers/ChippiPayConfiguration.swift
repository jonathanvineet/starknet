//
//  ChippiPayConfiguration.swift
//  QRPaymentScanner
//
//  ChippiPay API configuration and setup
//

import Foundation

public class ChippiPayConfiguration {

    public static let shared = ChippiPayConfiguration()

    private init() {}

    // MARK: - Configuration

    /// Configure ChippiPay with your API keys
    /// Call this once during app initialization
    public func configure() {
        let keychain = KeychainHelper.shared

        // Your ChippiPay API credentials
        let publicKey = "pk_prod_0f67a3155f8d994796b3ecdb50b8db67"
        let secretKey = "sk_prod_c035c91fcc9ac3ac6cf7b8a3c2d88bb3c428eecf75d11b18f0006d8b9e84599b"

        // Save to secure keychain
        let publicKeySaved = keychain.saveChippiPayAPIKey(publicKey)
        let secretKeySaved = keychain.saveChippiPaySecretKey(secretKey)

        if publicKeySaved && secretKeySaved {
            print("✅ ChippiPay API keys configured successfully")
            print("   Public Key: \(publicKey.prefix(20))...")
            print("   Secret Key: \(secretKey.prefix(20))...")
        } else {
            print("❌ Failed to save ChippiPay API keys to keychain")
        }
    }

    /// Verify that API keys are configured
    public func isConfigured() -> Bool {
        let keychain = KeychainHelper.shared

        guard let publicKey = keychain.getChippiPayAPIKey(),
              let secretKey = keychain.getChippiPaySecretKey() else {
            return false
        }

        return !publicKey.isEmpty && !secretKey.isEmpty
    }

    /// Get current configuration status
    public func getStatus() -> String {
        let keychain = KeychainHelper.shared

        if let publicKey = keychain.getChippiPayAPIKey(),
           let secretKey = keychain.getChippiPaySecretKey() {
            return """
            ✅ ChippiPay Configured
            Public Key: \(publicKey.prefix(20))...
            Secret Key: \(secretKey.prefix(20))...
            Status: Ready for testing
            """
        } else {
            return """
            ❌ ChippiPay Not Configured
            Please run ChippiPayConfiguration.shared.configure()
            """
        }
    }

    /// Clear stored API keys (for testing/debugging)
    public func clearConfiguration() {
        let keychain = KeychainHelper.shared
        keychain.clearAllChippiPayKeys()
        print("🗑️ ChippiPay configuration cleared")
    }

    /// Test API connection
    @MainActor
    public func testConnection() async -> Bool {
        guard isConfigured() else {
            print("❌ Cannot test connection - API keys not configured")
            return false
        }

        print("🔄 Testing ChippiPay API connection...")

        let manager = ChippiPayManager(environment: .production)

        do {
            try await manager.fetchAvailableServices()

            if manager.availableServices.isEmpty {
                print("⚠️  Connection successful but no services returned")
                print("   This might be normal if no services are configured in your ChippiPay account")
                return true
            } else {
                print("✅ Connection successful!")
                print("   Found \(manager.availableServices.count) available services:")
                for (index, service) in manager.availableServices.prefix(3).enumerated() {
                    print("   \(index + 1). \(service.name) (\(service.category))")
                }
                return true
            }
        } catch {
            print("❌ Connection failed: \(error.localizedDescription)")
            return false
        }
    }
}
