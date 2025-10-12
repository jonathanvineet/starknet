//
//  KeychainHelper.swift
//  QRPaymentScanner
//
//  Secure storage for API keys and sensitive data using iOS Keychain
//

import Foundation
import Security

public class KeychainHelper {

    public static let shared = KeychainHelper()

    private init() {}

    // MARK: - Keychain Keys
    private enum KeychainKey {
        static let chippiPayAPIKey = "com.qrpayment.chipipay.apikey"
        static let chippiPaySecretKey = "com.qrpayment.chipipay.secretkey"
        static let chippiPayWalletKey = "com.qrpayment.chipipay.walletkey"
    }

    // MARK: - Public API

    /// Save ChippiPay API key securely
    public func saveChippiPayAPIKey(_ key: String) -> Bool {
        return save(key: KeychainKey.chippiPayAPIKey, value: key)
    }

    /// Retrieve ChippiPay API key
    public func getChippiPayAPIKey() -> String? {
        return retrieve(key: KeychainKey.chippiPayAPIKey)
    }

    /// Save ChippiPay secret key securely
    public func saveChippiPaySecretKey(_ key: String) -> Bool {
        return save(key: KeychainKey.chippiPaySecretKey, value: key)
    }

    /// Retrieve ChippiPay secret key
    public func getChippiPaySecretKey() -> String? {
        return retrieve(key: KeychainKey.chippiPaySecretKey)
    }

    /// Save wallet encryption key
    public func saveWalletEncryptionKey(_ key: String) -> Bool {
        return save(key: KeychainKey.chippiPayWalletKey, value: key)
    }

    /// Retrieve wallet encryption key
    public func getWalletEncryptionKey() -> String? {
        return retrieve(key: KeychainKey.chippiPayWalletKey)
    }

    /// Delete specific key from keychain
    public func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Clear all ChippiPay keys from keychain
    public func clearAllChippiPayKeys() {
        _ = delete(key: KeychainKey.chippiPayAPIKey)
        _ = delete(key: KeychainKey.chippiPaySecretKey)
        _ = delete(key: KeychainKey.chippiPayWalletKey)
    }

    // MARK: - Generic Keychain Operations

    /// Save a string value to keychain
    private func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }

        // Delete any existing value first
        _ = delete(key: key)

        // Add new value
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Retrieve a string value from keychain
    private func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    /// Save codable object to keychain
    public func save<T: Codable>(key: String, object: T) -> Bool {
        guard let data = try? JSONEncoder().encode(object),
              let jsonString = String(data: data, encoding: .utf8) else {
            return false
        }
        return save(key: key, value: jsonString)
    }

    /// Retrieve codable object from keychain
    public func retrieve<T: Codable>(key: String, type: T.Type) -> T? {
        guard let jsonString = retrieve(key: key),
              let data = jsonString.data(using: .utf8),
              let object = try? JSONDecoder().decode(type, from: data) else {
            return nil
        }
        return object
    }
}

// MARK: - Keychain Error Handling

public enum KeychainError: Error {
    case saveFailed
    case retrievalFailed
    case deletionFailed
    case encodingFailed
    case decodingFailed

    var localizedDescription: String {
        switch self {
        case .saveFailed:
            return "Failed to save data to keychain"
        case .retrievalFailed:
            return "Failed to retrieve data from keychain"
        case .deletionFailed:
            return "Failed to delete data from keychain"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        }
    }
}
