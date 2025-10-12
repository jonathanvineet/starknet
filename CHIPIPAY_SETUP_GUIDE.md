# ChippiPay Integration Setup Guide

## Overview
This guide walks you through configuring your iOS app with real ChippiPay API credentials and deploying to production.

---

## Prerequisites

1. **ChippiPay Dashboard Account**
   - Sign up at [dashboard.chipipay.com](https://dashboard.chipipay.com)
   - Complete KYC verification if required

2. **Auth Provider JWKS Endpoint**
   - You're using Supabase for authentication
   - ChippiPay needs your JWKS endpoint for JWT verification

3. **Starknet Wallet**
   - For mainnet deployment, ensure your vault contract is deployed on Starknet mainnet
   - Currently deployed on Sepolia testnet: `0x029961c5af1520f4a4ad57dccc66370b92ff7a0c47fbf00764e354c17156d7db`

---

## Step 1: ChippiPay Dashboard Configuration

### 1.1 Create Project
1. Log in to ChippiPay dashboard
2. Navigate to **Projects** → **Create New Project**
3. Name: "Starknet Vault iOS App"
4. Select environment: **Production** (or Development for testing)

### 1.2 Configure Authentication
1. Go to **Settings** → **Authentication**
2. Add your Supabase JWKS endpoint:
   ```
   https://<your-supabase-project>.supabase.co/auth/v1/jwks
   ```
3. Save configuration

### 1.3 Generate API Keys
1. Navigate to **API Keys** section
2. Click **Generate New Key Pair**
3. You'll receive:
   - **Public Key**: `pk_prod_xxxxxxxxxxxxx`
   - **Secret Key**: `sk_prod_xxxxxxxxxxxxx`
4. **IMPORTANT**: Copy and save these immediately - secret key is shown only once!

---

## Step 2: Configure iOS App

### 2.1 Store API Keys Securely

Add this code to your app's initialization (e.g., in `AppDelegate.swift` or first launch):

```swift
import Foundation

// IMPORTANT: Only run this ONCE during first setup or config update
func configureChippiPayKeys() {
    let keychain = KeychainHelper.shared

    // Replace with your actual keys from ChippiPay dashboard
    let apiKey = "pk_prod_your_actual_public_key_here"
    let secretKey = "sk_prod_your_actual_secret_key_here"

    // Save to keychain
    let apiKeySaved = keychain.saveChippiPayAPIKey(apiKey)
    let secretKeySaved = keychain.saveChippiPaySecretKey(secretKey)

    if apiKeySaved && secretKeySaved {
        print("✅ ChippiPay keys configured successfully")
    } else {
        print("❌ Failed to save ChippiPay keys")
    }
}
```

### 2.2 Call Configuration Function

**Option A: First Launch Setup**

Add to your main app file (`QRPaymentApp.swift`):

```swift
@main
struct QRPaymentApp: App {
    @StateObject private var supabase = SupabaseManager.shared

    init() {
        // Configure ChippiPay on first launch
        if !UserDefaults.standard.bool(forKey: "chippiPayConfigured") {
            configureChippiPayKeys()
            UserDefaults.standard.set(true, forKey: "chippiPayConfigured")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(supabase)
        }
    }
}
```

**Option B: Admin Settings View**

Create a developer/admin settings screen where you can update keys:

```swift
struct AdminSettingsView: View {
    @State private var apiKey = ""
    @State private var secretKey = ""
    @State private var showSuccess = false

    var body: some View {
        Form {
            Section(header: Text("ChippiPay API Configuration")) {
                SecureField("Public API Key", text: $apiKey)
                SecureField("Secret Key", text: $secretKey)

                Button("Save Configuration") {
                    let keychain = KeychainHelper.shared
                    _ = keychain.saveChippiPayAPIKey(apiKey)
                    _ = keychain.saveChippiPaySecretKey(secretKey)
                    showSuccess = true
                }
            }
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") { }
        } message: {
            Text("ChippiPay keys saved successfully")
        }
    }
}
```

### 2.3 Environment Selection

In your `ChippiPayManager` initialization, choose the environment:

```swift
// For production
let chippiPayManager = ChippiPayManager(environment: .production)

// For development/testing
let chippiPayManager = ChippiPayManager(environment: .development)
```

---

## Step 3: Verify Integration

### 3.1 Test API Connection

Add this test function to verify your setup:

```swift
extension ChippiPayManager {
    func testConnection() async -> Bool {
        do {
            // Try to fetch services as a connection test
            try await fetchAvailableServices()
            print("✅ ChippiPay API connection successful")
            return true
        } catch {
            print("❌ ChippiPay API connection failed: \(error.localizedDescription)")
            return false
        }
    }
}
```

### 3.2 Run Connection Test

In your app, test the connection:

```swift
Task {
    let isConnected = await chippiPayManager.testConnection()
    if isConnected {
        print("Ready to use ChippiPay services")
    } else {
        print("Check your API keys and configuration")
    }
}
```

---

## Step 4: Production Deployment Checklist

### 4.1 Smart Contract Deployment

- [ ] Deploy vault contract to Starknet **mainnet**
- [ ] Update `StarknetManager.swift` with mainnet contract address:
  ```swift
  static let vaultContractAddress = "0x_your_mainnet_contract_address"
  static let strkTokenAddress = "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d" // STRK on mainnet
  static let rpcUrl = "https://starknet-mainnet.g.alchemy.com/starknet/version/rpc/v0_6"
  ```

### 4.2 Security Review

- [ ] Ensure API keys are never hardcoded in source code
- [ ] Verify keychain storage is working
- [ ] Test key rotation process
- [ ] Add error handling for missing keys
- [ ] Implement API key refresh mechanism if needed

### 4.3 Network Configuration

- [ ] Set `ChippiPayEnvironment` to `.production`
- [ ] Update RPC URLs to mainnet
- [ ] Configure proper timeout values
- [ ] Add network reachability checks

### 4.4 Testing

- [ ] Test wallet creation end-to-end
- [ ] Test service purchase with small amount
- [ ] Verify transaction status polling
- [ ] Test error scenarios (insufficient balance, network failures)
- [ ] Verify vault withdrawal → ChippiPay purchase flow

---

## Step 5: User Flow Overview

### Complete Purchase Flow

1. **User opens app** → Connects Starknet wallet
2. **User deposits STRK** → Funds go to vault contract on mainnet
3. **User creates ChippiPay wallet** → One-time setup
4. **User browses services** → Fetched from ChippiPay API
5. **User selects service** → Enters reference (phone number, etc.)
6. **App shows cost breakdown** → STRK amount calculated
7. **User confirms purchase** → App executes:
   - Withdraws STRK from vault to ChippiPay payment address
   - Submits transaction to ChippiPay API with vault tx hash
   - Polls for transaction completion
8. **User receives confirmation** → Service delivered

---

## Troubleshooting

### Common Issues

**1. "ChippiPay API credentials not configured"**
```swift
// Solution: Ensure keys are saved to keychain
let keychain = KeychainHelper.shared
print("API Key: \(keychain.getChippiPayAPIKey() ?? "NOT SET")")
print("Secret Key: \(keychain.getChippiPaySecretKey() ?? "NOT SET")")
```

**2. "Network error" or "Invalid response"**
- Check internet connection
- Verify API keys are correct
- Ensure JWKS endpoint is accessible
- Check ChippiPay service status

**3. "Wallet not connected"**
- User needs to create ChippiPay wallet first
- Call `loadExistingWallet()` on app launch

**4. "Insufficient balance"**
- User needs to deposit STRK to vault first
- Check vault balance before purchase

---

## Security Best Practices

1. **Never commit API keys to source control**
   - Add to `.gitignore`: `**/APIKeys.swift`
   - Use environment variables or keychain only

2. **Rotate keys periodically**
   - Generate new keys in ChippiPay dashboard
   - Update in app via admin settings

3. **Monitor API usage**
   - Check ChippiPay dashboard for unusual activity
   - Set up alerts for failed transactions

4. **Implement rate limiting**
   - Add cooldown between API calls
   - Implement retry logic with exponential backoff

5. **Validate all inputs**
   - Check amounts before vault withdrawal
   - Validate phone numbers/references
   - Verify transaction hashes

---

## Support & Resources

- **ChippiPay Documentation**: [docs.chipipay.com](https://docs.chipipay.com)
- **ChippiPay Dashboard**: [dashboard.chipipay.com](https://dashboard.chipipay.com)
- **Telegram Community**: [t.me/+e2qjHEOwImkyZDVh](https://t.me/+e2qjHEOwImkyZDVh)
- **Starknet RPC Docs**: [starknet.io](https://www.starknet.io/)

---

## Quick Reference

### File Locations
- **API Client**: `QRPaymentScanner/Managers/ChippiPayAPI.swift`
- **Manager**: `QRPaymentScanner/Managers/ChippiPayManager.swift`
- **Keychain Helper**: `QRPaymentScanner/Helpers/KeychainHelper.swift`
- **Purchase View**: `QRPaymentScanner/Views/ServicePurchaseView.swift`

### Environment URLs
- **Production API**: `https://api.chipipay.com/v1`
- **Development API**: `https://api-dev.chipipay.com/v1`
- **Starknet Mainnet RPC**: `https://starknet-mainnet.g.alchemy.com/starknet/version/rpc/v0_6`
- **Starknet Sepolia RPC**: `https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_6`

---

**Last Updated**: 2025-10-12
**Integration Version**: 1.0
**ChippiPay API Version**: v1
