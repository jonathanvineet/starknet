# ChippiPay Integration Plan for iOS Vault App

## Overview
ChippiPay offers gasless transactions and service purchasing through API integration. Since there's no iOS SDK, we'll integrate via HTTP API calls to enhance our vault functionality.

## Integration Architecture

### 1. Enhanced User Flow with ChippiPay

#### Current Flow:
- User connects wallet → Deposits STRK → Uses vault for payments

#### Enhanced Flow with ChippiPay:
- User connects wallet → **Creates ChippiPay gasless wallet** → Deposits STRK → **Gasless payments** via ChippiPay services

### 2. Key ChippiPay Features for Integration

#### A. Gasless Wallet Creation
- Self-custodial wallets with encrypted private keys
- No gas fees for users
- Starknet mainnet support

#### B. Service Purchasing
- Phone/telecom top-ups
- Utility payments
- Gift cards
- Gaming services

#### C. Payment Flow
- Deposit STRK to ChippiPay contract
- Purchase services without gas fees
- All transactions gasless for end users

## Implementation Strategy

### Phase 1: ChippiPay API Client (Swift)

Create `ChippiPayManager.swift` with:

```swift
class ChippiPayManager: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://api.chipipay.com/v1"
    
    // 1. Create gasless wallet for user
    func createChippiWallet(bearerToken: String, encryptKey: String) async throws -> ChippiWallet
    
    // 2. Get available services
    func getAvailableServices() async throws -> [ChippiService]
    
    // 3. Purchase service with STRK
    func purchaseService(skuId: String, amount: Double, walletAddress: String, txHash: String) async throws -> PurchaseResult
    
    // 4. Check transaction status
    func checkTransactionStatus(transactionId: String) async throws -> TransactionStatus
}
```

### Phase 2: Enhanced Mobile UI

Update existing views:

#### A. Enhanced `StarknetConnectView`
- Add ChippiPay wallet creation option
- Show both regular wallet and gasless wallet status

#### B. New `ChippiPayServicesView`
- Display available services (phone, utilities, etc.)
- Show service costs in STRK
- Purchase flow integration

#### C. Enhanced `VaultActionView`
- Add "Pay with ChippiPay" option
- Gasless transaction flows
- Service payment history

### Phase 3: Payment Flow Integration

#### User Deposit Flow (STRK → Vault Contract) with ChippiPay:
1. User deposits STRK to vault contract (existing flow)
2. **NEW**: Option to create ChippiPay gasless wallet
3. **NEW**: Transfer portion of vault STRK to ChippiPay for gasless payments

#### In-App Transaction Flow (Spend from Vault):
1. User selects service (phone top-up, utilities, etc.)
2. **ChippiPay Integration**: Gasless transaction to ChippiPay contract
3. ChippiPay processes service payment
4. User receives service without paying gas fees

## Technical Implementation Details

### 1. Authentication Setup
- Register with ChippiPay dashboard
- Get API keys (pk_prod_xxx, sk_prod_xxx)
- Configure JWKS endpoint for JWT authentication
- Set up webhook URLs

### 2. API Integration Points

#### Wallet Creation Endpoint:
```
POST /chipi-wallets/prepare-creation
POST /chipi-wallets
```

#### Service Discovery:
```
GET /skus?categories=TELEFONIA,INTERNET,LUZ
```

#### Purchase Flow:
```
POST /sku-transactions
```

### 3. Enhanced User Experience

#### Benefits for Users:
- **Gasless payments** - No STRK spent on gas
- **Service variety** - Phone, utilities, gift cards
- **Seamless UX** - One app for vault + payments
- **Cost effective** - Lower transaction costs

#### UI Enhancements:
- Service marketplace within app
- Payment history with service details
- Gasless transaction confirmations
- Balance tracking (vault + ChippiPay)

## Implementation Timeline

### Week 1: Foundation
- [ ] ChippiPayManager.swift implementation
- [ ] API authentication setup
- [ ] Basic service fetching

### Week 2: UI Integration
- [ ] ChippiPayServicesView creation
- [ ] Enhanced StarknetConnectView
- [ ] Wallet creation flow

### Week 3: Payment Flows
- [ ] Purchase service implementation
- [ ] Transaction status monitoring
- [ ] Error handling and edge cases

### Week 4: Testing & Polish
- [ ] End-to-end testing
- [ ] UI/UX refinements
- [ ] Documentation updates

## Security Considerations

### 1. API Key Management
- Store API keys securely in iOS Keychain
- Use environment-specific keys (dev/prod)
- Implement secure API communication

### 2. Private Key Handling
- ChippiPay encrypts private keys with user password
- Never store unencrypted private keys
- Proper key rotation and management

### 3. Transaction Validation
- Verify transaction hashes on-chain
- Implement proper error handling
- Monitor for failed transactions

## Configuration Requirements

### 1. ChippiPay Dashboard Setup
```
1. Create account at dashboard.chipipay.com
2. Add JWKS endpoint from auth provider
3. Generate API keys (pk_prod_xxx, sk_prod_xxx)
4. Configure webhook endpoints
5. Set up development environment
```

### 2. iOS App Configuration
```swift
// Configuration.swift
struct ChippiPayConfig {
    static let apiKey = "pk_prod_your_key_here"
    static let baseURL = "https://api.chipipay.com/v1"
    static let environment = "production" // or "development"
}
```

## Expected Outcomes

### For Users:
- Gasless payments for everyday services
- Integrated payment experience
- Lower transaction costs
- More use cases for vault STRK

### For App:
- Enhanced value proposition
- Increased user engagement
- Revenue opportunities through service fees
- Competitive advantage in payment space