//
//  Extensions+Helpers.swift
//  QRPaymentScanner
//
//  Created by Rehaan John on 09/10/25.
//

import SwiftUI
import UIKit

// MARK: - Color Extensions

extension Color {
    /// App theme colors
    static let appRed = Color(red: 0.9, green: 0, blue: 0)
    static let appDarkRed = Color(red: 0.6, green: 0, blue: 0)
    static let appBackground = Color.black
    static let appSecondaryBackground = Color(red: 0.1, green: 0, blue: 0)
    
    /// Custom color from hex
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions

extension View {
    /// Hide keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    /// Custom card style
    func cardStyle() -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
    }
    
    /// Glowing effect
    func glowingEffect(color: Color = .red, radius: CGFloat = 10) -> some View {
        self
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
    }
    
    /// Loading overlay
    func loadingOverlay(isLoading: Bool) -> some View {
        self.overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 15) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.red)
                        
                        Text("Loading...")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.red.opacity(0.5), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
}

// MARK: - String Extensions

extension String {
    /// Check if string is valid email
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// Check if string is valid password (at least 6 characters)
    var isValidPassword: Bool {
        return self.count >= 6
    }
    
    /// Truncate string to specified length
    func truncate(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        }
        return self
    }
    
    /// Remove whitespace and newlines
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Date Extensions

extension Date {
    /// Format date to string
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// Format date with time
    func formattedWithTime(dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }
    
    /// Relative time string (e.g., "2 hours ago")
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Double Extensions

extension Double {
    /// Format as currency
    var asCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD" // Change as needed
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
    
    /// Format with specific decimal places
    func rounded(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: - UIApplication Extensions

extension UIApplication {
    /// Get key window
    var keyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    /// Get safe area insets
    var safeAreaInsets: UIEdgeInsets {
        keyWindow?.safeAreaInsets ?? .zero
    }
}

// MARK: - Animation Extensions

extension Animation {
    /// Custom spring animation
    static var customSpring: Animation {
        .spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)
    }
    
    /// Custom bouncy animation
    static var bouncy: Animation {
        .spring(response: 0.4, dampingFraction: 0.6)
    }
}

// MARK: - Haptic Feedback

struct HapticFeedback {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}

// MARK: - Custom View Modifiers

struct GradientButtonStyle: ViewModifier {
    let colors: [Color]
    let cornerRadius: CGFloat
    
    init(colors: [Color] = [Color.appRed, Color.appDarkRed], cornerRadius: CGFloat = 15) {
        self.colors = colors
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(cornerRadius)
            .shadow(color: colors.first?.opacity(0.5) ?? .clear, radius: 15)
    }
}

extension View {
    func gradientButton(colors: [Color] = [Color.appRed, Color.appDarkRed], cornerRadius: CGFloat = 15) -> some View {
        self.modifier(GradientButtonStyle(colors: colors, cornerRadius: cornerRadius))
    }
}

// MARK: - Network Monitoring (Optional)

class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    
    static let shared = NetworkMonitor()
    
    private init() {
        // Add network monitoring logic here if needed
        // Using NWPathMonitor or similar
    }
}

// MARK: - UserDefaults Helper

extension UserDefaults {
    enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let isDarkMode = "isDarkMode"
        static let preferredLanguage = "preferredLanguage"
    }
    
    var hasSeenOnboarding: Bool {
        get { bool(forKey: Keys.hasSeenOnboarding) }
        set { set(newValue, forKey: Keys.hasSeenOnboarding) }
    }
}

// MARK: - Validation Helpers

struct Validator {
    static func isValidEmail(_ email: String) -> Bool {
        email.isValidEmail
    }

    static func isValidPassword(_ password: String) -> Bool {
        password.isValidPassword
    }

    static func passwordStrength(_ password: String) -> Int {
        var strength = 0
        if password.count >= 6 { strength += 1 }
        if password.count >= 10 { strength += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { strength += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { strength += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil { strength += 1 }
        return strength
    }
}

// MARK: - Keychain Helper

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
        static let starknetPrivateKey = "com.qrpayment.starknet.privatekey"
        static let starknetAddress = "com.qrpayment.starknet.address"
        static let starknetPublicKey = "com.qrpayment.starknet.publickey"
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
    
    // MARK: - Starknet Wallet Keys
    
    /// Save Starknet private key securely
    public func saveStarknetPrivateKey(_ key: String) -> Bool {
        return save(key: KeychainKey.starknetPrivateKey, value: key)
    }
    
    /// Retrieve Starknet private key
    public func getStarknetPrivateKey() -> String? {
        return retrieve(key: KeychainKey.starknetPrivateKey)
    }
    
    /// Save Starknet address
    public func saveStarknetAddress(_ address: String) -> Bool {
        return save(key: KeychainKey.starknetAddress, value: address)
    }
    
    /// Retrieve Starknet address
    public func getStarknetAddress() -> String? {
        return retrieve(key: KeychainKey.starknetAddress)
    }
    
    /// Save Starknet public key
    public func saveStarknetPublicKey(_ key: String) -> Bool {
        return save(key: KeychainKey.starknetPublicKey, value: key)
    }
    
    /// Retrieve Starknet public key
    public func getStarknetPublicKey() -> String? {
        return retrieve(key: KeychainKey.starknetPublicKey)
    }
    
    /// Clear all Starknet keys from keychain
    public func clearAllStarknetKeys() {
        _ = delete(key: KeychainKey.starknetPrivateKey)
        _ = delete(key: KeychainKey.starknetAddress)
        _ = delete(key: KeychainKey.starknetPublicKey)
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
