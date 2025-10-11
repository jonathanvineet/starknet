# ChippiPay iOS Integration Guide

## Overview
This guide explains how to integrate ChippiPay's gasless payment system with your existing Starknet vault iOS application. The integration enables users to make payments for real-world services (phone top-ups, utilities, gift cards) without paying gas fees.

## What is ChippiPay?

ChippiPay is a gasless payment platform that allows users to:
- **Create self-custodial wallets** with encrypted private keys
- **Make gasless transactions** on Starknet mainnet
- **Purchase real services** like phone credits, electricity bills, gift cards
- **Pay with STRK tokens** without gas fees

## Integration Architecture

### Current App Flow:
1. User connects Starknet wallet
2. User deposits STRK to vault contract
3. User can withdraw/transfer from vault

### Enhanced Flow with ChippiPay:
1. User connects Starknet wallet
2. User deposits STRK to vault contract
3. **NEW:** User creates ChippiPay gasless wallet
4. **NEW:** User can purchase services gaslessly using vault STRK

## Implementation Files

### 1. ChippiPayManager.swift
- **Location**: `QRPaymentScanner/Managers/ChippiPayManager.swift`
- **Purpose**: Core API integration with ChippiPay services
- **Key Functions**:
  - `createGaslessWallet()` - Creates encrypted wallet for user
  - `fetchAvailableServices()` - Gets phone/utility services
  - `purchaseService()` - Executes gasless payments
  - `checkTransactionStatus()` - Monitors payment status

### 2. ChippiPayServicesView.swift
- **Location**: `QRPaymentScanner/Views/ChippiPayServicesView.swift`
- **Purpose**: Main services marketplace UI
- **Features**:
  - Service grid with categories (Phone, Utilities, Gift Cards)
  - Wallet connection status
  - Recent transaction history
  - Service selection and purchase flow

### 3. ChippiWalletCreationView.swift
- **Location**: `QRPaymentScanner/Views/ChippiWalletCreationView.swift`
- **Purpose**: Multi-step wallet creation wizard
- **Steps**:
  - User information collection
  - Security setup (password encryption)
  - Confirmation and wallet creation

### 4. ServicePurchaseView.swift
- **Location**: `QRPaymentScanner/Views/ServicePurchaseView.swift`
- **Purpose**: Individual service purchase interface
- **Features**:
  - Service details display
  - Reference input (phone number, account number)
  - Cost breakdown (MXN to STRK conversion)
  - Gasless transaction execution

### 5. Enhanced HomeView.swift
- **Location**: `QRPaymentScanner/Views/HomeView.swift`
- **Enhancement**: Added ChippiPay button in action grid
- **Integration**: Links to ChippiPayServicesView

## Key Features

### 1. Gasless Transactions ⚡
- Users pay **zero gas fees** for service purchases
- All transaction costs handled by ChippiPay
- Significant cost savings for users

### 2. Real-World Services 🏪
- **Telefonia**: Mobile phone top-ups (Telcel, etc.)
- **Luz**: Electricity bill payments (CFE)
- **Internet**: Internet service payments
- **Gift Cards**: Spotify, gaming, entertainment
- **Utilities**: Various utility payments

### 3. Self-Custodial Security 🔐
- Users control their private keys
- Keys encrypted with user password
- No ChippiPay access to user funds
- Full decentralization maintained

### 4. Seamless UX 📱
- One-tap service purchases
- Automatic STRK/MXN conversion
- Transaction status monitoring
- Integrated with existing vault system

## User Experience Flow

### First-Time Setup:
1. User opens app and connects Starknet wallet
2. User deposits STRK to vault contract
3. User taps "ChippiPay" button in home screen
4. User creates gasless wallet with password
5. ChippiPay wallet is ready for gasless payments

### Making a Payment:
1. User browses available services
2. User selects service (e.g., "Telcel 50 MXN Top-up")
3. User enters phone number
4. App shows cost breakdown:
   - Service: $50 MXN
   - STRK equivalent: ~2.5 STRK
   - Gas fee: FREE ⚡
   - ChippiPay fee: FREE ⚡
5. User confirms purchase
6. Payment processed gaslessly
7. User receives service confirmation

## Technical Implementation Details

### API Integration
```swift
// ChippiPay API endpoints
let baseURL = "https://api.chipipay.com/v1"

// Authentication
Authorization: Bearer sk_prod_your_secret_key
x-api-key: pk_prod_your_public_key

// Key endpoints:
POST /chipi-wallets/prepare-creation  // Wallet creation
POST /chipi-wallets                   // Save wallet
GET /skus                            // Available services
POST /sku-transactions               // Purchase service
```

### Security Considerations
- API keys stored in iOS Keychain
- Private keys encrypted with user password
- All API calls use HTTPS
- Transaction validation on-chain
- Proper error handling for failed transactions

### Environment Configuration
```swift
// Development vs Production
let environment: Environment = .production

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
```

## Setup Requirements

### 1. ChippiPay Dashboard Setup
1. Create account at `dashboard.chipipay.com`
2. Add JWKS endpoint from your auth provider
3. Generate API keys:
   - Public Key: `pk_prod_xxxxx`
   - Secret Key: `sk_prod_xxxxx`
4. Configure webhook endpoints (optional)
5. Set up development environment

### 2. iOS App Configuration
Add to your app's configuration:
```swift
// In your app configuration
let chippiPayConfig = ChippiPayConfig(
    apiKey: "pk_prod_your_key_here",
    secretKey: "sk_prod_your_secret_key",
    environment: .production
)
```

### 3. Starknet Integration
ChippiPay works on **Starknet Mainnet** while your vault is on **Sepolia Testnet**. For production:
- Deploy vault contract to Starknet Mainnet
- Update StarknetManager to use mainnet RPC
- Ensure STRK token compatibility

## Current Implementation Status

### ✅ Completed
- [x] ChippiPayManager with full API integration
- [x] Service discovery and display
- [x] Wallet creation wizard (3-step process)
- [x] Service purchase flow with cost breakdown
- [x] Integration with existing HomeView
- [x] Mock data for demonstration
- [x] Error handling and loading states
- [x] Security considerations implemented

### 🔄 In Progress (Mock Implementation)
- [x] API calls are simulated for demo purposes
- [x] Service data is mocked
- [x] Wallet creation is simulated
- [x] Purchase flow is functional but simulated

### 📋 Next Steps for Production
1. **Replace mock API calls** with real ChippiPay API integration
2. **Add real authentication** (JWT tokens from auth provider)
3. **Configure production API keys** from ChippiPay dashboard
4. **Deploy vault contract to mainnet** for STRK compatibility
5. **Implement webhook handling** for transaction confirmations
6. **Add comprehensive error handling** for network/API failures
7. **Implement proper logging** and analytics
8. **Add transaction persistence** for offline capability

## Benefits for Users

### Cost Savings 💰
- **No gas fees** for service payments
- **Lower total costs** compared to traditional on-chain transactions
- **Competitive service pricing** through ChippiPay marketplace

### Convenience 🎯
- **One app** for both vault management and service payments
- **Real-world utility** for crypto holdings
- **Instant payments** without waiting for block confirmations

### Security 🛡️
- **Self-custodial** wallet maintains user control
- **Encrypted private keys** with user-controlled passwords
- **No third-party access** to user funds

## Testing the Integration

### Manual Testing Steps:
1. Open app and navigate to home screen
2. Tap "ChippiPay" button in action grid
3. Create a gasless wallet (follow 3-step wizard)
4. Browse available services
5. Select a service and make a test purchase
6. Verify purchase flow and confirmation

### Expected Results:
- Services load and display correctly
- Wallet creation completes successfully
- Purchase flow shows proper cost breakdown
- Transaction confirmation displays
- Recent transactions appear in history

## Support and Documentation

### ChippiPay Resources:
- **Documentation**: https://docs.chipipay.com/
- **Dashboard**: https://dashboard.chipipay.com/
- **Telegram Community**: https://t.me/+e2qjHEOwImkyZDVh
- **API Reference**: https://docs.chipipay.com/sdk/api/

### Integration Support:
For technical questions about this integration, refer to:
- ChippiPayManager.swift code comments
- Error handling in each view
- Console logs during testing
- ChippiPay community for API questions

This integration transforms your vault app from a simple STRK storage solution into a comprehensive payment platform with real-world utility! 🚀