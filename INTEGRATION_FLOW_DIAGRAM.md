# ChippiPay Integration - Flow Diagrams

Visual representation of how your Starknet vault integrates with ChippiPay.

---

## Complete System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          iOS Application                             │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                        User Interface                           │ │
│  │                                                                 │ │
│  │  HomeView → ChippiPayServicesView → ServicePurchaseView        │ │
│  │     ↓              ↓                       ↓                    │ │
│  │  VaultActionView  ChippiWalletCreationView                     │ │
│  └────────────┬───────────────────────┬──────────────────────────┘ │
│               │                       │                             │
│               ↓                       ↓                             │
│  ┌────────────────────┐   ┌────────────────────────┐              │
│  │ StarknetManager    │   │ ChippiPayManager       │              │
│  │                    │   │                        │              │
│  │ • Connect wallet   │   │ • Create wallet        │              │
│  │ • Deposit to vault │   │ • Fetch services       │              │
│  │ • Withdraw         │   │ • Purchase service     │              │
│  │ • Check balance    │   │ • Poll status          │              │
│  └────────┬───────────┘   └────────┬───────────────┘              │
│           │                        │                               │
│           │                        ↓                               │
│           │              ┌──────────────────┐                      │
│           │              │ ChippiPayAPI     │                      │
│           │              │                  │                      │
│           │              │ REST API Client  │                      │
│           │              └────────┬─────────┘                      │
│           │                       │                                │
│           │              ┌────────▼─────────┐                      │
│           │              │ KeychainHelper   │                      │
│           │              │ (Secure Storage) │                      │
│           │              └──────────────────┘                      │
└───────────┼────────────────────────┼─────────────────────────────┘
            │                        │
            ↓                        ↓
    ┌───────────────┐      ┌─────────────────┐
    │   Starknet    │      │  ChippiPay      │
    │  Blockchain   │      │   Backend       │
    │               │      │                 │
    │  Vault        │      │  • Wallets      │
    │  Contract     │      │  • Services     │
    │  0x0299...    │      │  • Transactions │
    └───────────────┘      └─────────────────┘
```

---

## User Journey: First-Time Setup

```
┌──────────────────────────────────────────────────────────────────┐
│                    First-Time User Setup                          │
└──────────────────────────────────────────────────────────────────┘

User opens app
    ↓
┌────────────────────────────────────────────────┐
│ 1. Connect Starknet Wallet                     │
│    • User enters wallet address                │
│    • User enters private/public keys           │
│    • StarknetManager.connectWallet()           │
└────────────────────────────────────────────────┘
    ↓
┌────────────────────────────────────────────────┐
│ 2. Deposit STRK to Vault                       │
│    • User clicks "Deposit"                     │
│    • User enters amount (e.g., 10 STRK)        │
│    • User approves STRK token spending         │
│    • StarknetManager.depositToVault()          │
│    • STRK moves: Wallet → Vault Contract       │
└────────────────────────────────────────────────┘
    ↓
┌────────────────────────────────────────────────┐
│ 3. Create ChippiPay Wallet                     │
│    • User clicks "ChippiPay" button            │
│    • User clicks "Create Gasless Wallet"       │
│    • User enters email & password              │
│    • ChippiPayManager.createGaslessWallet()    │
│    • Wallet ID saved to keychain               │
└────────────────────────────────────────────────┘
    ↓
✅ Setup Complete!
   User can now purchase services
```

---

## Purchase Flow: Step-by-Step

```
┌──────────────────────────────────────────────────────────────────┐
│              Service Purchase Flow (The Magic!)                   │
└──────────────────────────────────────────────────────────────────┘

User wants to buy phone credit (50 MXN)
    ↓
┌────────────────────────────────────────────────┐
│ STEP 1: Browse Services                        │
│                                                 │
│ ChippiPayServicesView loads                    │
│     ↓                                           │
│ ChippiPayManager.fetchAvailableServices()      │
│     ↓                                           │
│ ChippiPayAPI.fetchSKUs()                       │
│     ↓                                           │
│ GET https://api.chipipay.com/v1/skus           │
│     ↓                                           │
│ Services displayed to user:                    │
│ • Telcel 50 MXN                                │
│ • CFE Electricity                              │
│ • Spotify Gift Card                            │
└────────────────────────────────────────────────┘
    ↓
┌────────────────────────────────────────────────┐
│ STEP 2: Select Service                         │
│                                                 │
│ User taps "Telcel 50 MXN Top-up"               │
│     ↓                                           │
│ ServicePurchaseView opens                      │
│     ↓                                           │
│ User enters phone number: "5512345678"         │
│     ↓                                           │
│ App calculates:                                │
│ • Service: 50 MXN                              │
│ • STRK needed: 2.5 STRK (at 20 MXN/STRK)       │
│ • Gas fee: FREE ⚡                              │
│ • Total: 2.5 STRK                              │
└────────────────────────────────────────────────┘
    ↓
┌────────────────────────────────────────────────┐
│ STEP 3: Confirm Purchase                       │
│                                                 │
│ User clicks "Purchase with ChippiPay"          │
│     ↓                                           │
│ ServicePurchaseView.purchaseService()          │
│     ↓                                           │
│ ┌─────────────────────────────────────────┐   │
│ │ SUB-STEP 3A: Check Balance              │   │
│ │                                         │   │
│ │ Check: vaultBalance >= 2.5 STRK?       │   │
│ │ ✅ YES: Continue                        │   │
│ │ ❌ NO: Show error                       │   │
│ └─────────────────────────────────────────┘   │
└────────────────────────────────────────────────┘
    ↓
┌────────────────────────────────────────────────┐
│ STEP 4: Withdraw from Vault                    │
│                                                 │
│ StarknetManager.withdrawFromVault(             │
│     amount: 2.5 STRK,                          │
│     toAddress: ChippiPay_Payment_Address       │
│ )                                               │
│     ↓                                           │
│ Smart Contract Call:                           │
│     vault.withdraw(recipient, 2.5e18)          │
│     ↓                                           │
│ Transaction broadcast to Starknet              │
│     ↓                                           │
│ Transaction confirmed ✅                        │
│     ↓                                           │
│ Returns: txHash = "0xabc123..."                │
└────────────────────────────────────────────────┘
    ↓
┌────────────────────────────────────────────────┐
│ STEP 5: Purchase via ChippiPay                 │
│                                                 │
│ ChippiPayManager.purchaseService(              │
│     skuId: "telcel_50",                        │
│     amount: 50.0,                              │
│     reference: "5512345678",                   │
│     vaultTransactionHash: "0xabc123..."        │
│ )                                               │
│     ↓                                           │
│ ChippiPayAPI.createSKUTransaction()            │
│     ↓                                           │
│ POST https://api.chipipay.com/v1/               │
│      sku-transactions                           │
│     ↓                                           │
│ Body: {                                        │
│   "sku_id": "telcel_50",                       │
│   "reference": "5512345678",                   │
│   "amount": 50.0,                              │
│   "wallet_id": "chipi_wallet_123",             │
│   "vault_transaction_hash": "0xabc123...",     │
│   "metadata": {...}                            │
│ }                                               │
│     ↓                                           │
│ ChippiPay processes:                           │
│ • Verifies vault transaction                   │
│ • Validates phone number                       │
│ • Initiates service purchase                   │
│     ↓                                           │
│ Returns: {                                     │
│   "transaction_id": "chipi_tx_xyz",            │
│   "status": "pending"                          │
│ }                                               │
└────────────────────────────────────────────────┘
    ↓
┌────────────────────────────────────────────────┐
│ STEP 6: Monitor Transaction                    │
│                                                 │
│ ChippiPayManager.pollTransactionStatus(        │
│     transactionId: "chipi_tx_xyz"              │
│ )                                               │
│     ↓                                           │
│ Poll every 2-10 seconds (max 10 attempts)      │
│     ↓                                           │
│ GET https://api.chipipay.com/v1/               │
│     sku-transactions/chipi_tx_xyz              │
│     ↓                                           │
│ Response: { "status": "pending" }              │
│     ↓                                           │
│ Wait 2 seconds...                              │
│     ↓                                           │
│ Poll again...                                  │
│     ↓                                           │
│ Response: { "status": "completed" } ✅          │
└────────────────────────────────────────────────┘
    ↓
┌────────────────────────────────────────────────┐
│ STEP 7: Show Confirmation                      │
│                                                 │
│ ServicePurchaseView shows:                     │
│     ✅ "Purchase Successful!"                   │
│     Transaction ID: chipi_tx_xyz               │
│     Service delivered to: 5512345678           │
│                                                 │
│ User receives phone credit instantly!          │
└────────────────────────────────────────────────┘
    ↓
✅ Purchase Complete!
   • Vault balance decreased by 2.5 STRK
   • Phone received 50 MXN credit
   • Zero gas fees paid by user
   • Transaction recorded in history
```

---

## API Authentication Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                 API Authentication Process                        │
└──────────────────────────────────────────────────────────────────┘

App Initialization
    ↓
┌────────────────────────────────────────────────┐
│ 1. Read API Keys from Keychain                 │
│                                                 │
│ KeychainHelper.shared.getChippiPayAPIKey()     │
│     ↓                                           │
│ Returns: "pk_prod_xxxxx"                       │
│                                                 │
│ KeychainHelper.shared.getChippiPaySecretKey()  │
│     ↓                                           │
│ Returns: "sk_prod_xxxxx"                       │
└────────────────────────────────────────────────┘
    ↓
┌────────────────────────────────────────────────┐
│ 2. Initialize API Client                       │
│                                                 │
│ ChippiPayAPI(environment: .production)         │
│     ↓                                           │
│ Stores keys internally                         │
└────────────────────────────────────────────────┘
    ↓
┌────────────────────────────────────────────────┐
│ 3. Make API Request                            │
│                                                 │
│ HTTP Request Headers:                          │
│ ┌──────────────────────────────────────┐       │
│ │ Authorization: Bearer sk_prod_xxxxx  │       │
│ │ x-api-key: pk_prod_xxxxx             │       │
│ │ Content-Type: application/json       │       │
│ └──────────────────────────────────────┘       │
│     ↓                                           │
│ Sent to: https://api.chipipay.com/v1/...      │
└────────────────────────────────────────────────┘
    ↓
┌────────────────────────────────────────────────┐
│ 4. ChippiPay Validates                         │
│                                                 │
│ ChippiPay Backend checks:                      │
│ • Is API key valid?                            │
│ • Is secret key matching?                      │
│ • Is account active?                           │
│ • Does account have permissions?               │
│     ↓                                           │
│ ✅ YES: Process request                        │
│ ❌ NO: Return 401 Unauthorized                 │
└────────────────────────────────────────────────┘
```

---

## Wallet Creation Flow

```
┌──────────────────────────────────────────────────────────────────┐
│              ChippiPay Wallet Creation Process                    │
└──────────────────────────────────────────────────────────────────┘

User clicks "Create Gasless Wallet"
    ↓
┌────────────────────────────────────────────────┐
│ PHASE 1: User Input                            │
│                                                 │
│ ChippiWalletCreationView:                      │
│ • Step 1: Enter email                          │
│ • Step 2: Create password                      │
│ • Step 3: Confirm details                      │
└────────────────────────────────────────────────┘
    ↓
┌────────────────────────────────────────────────┐
│ PHASE 2: Prepare Wallet                        │
│                                                 │
│ ChippiPayManager.createGaslessWallet(          │
│     userPassword: "***",                       │
│     authToken: supabaseJWT,                    │
│     externalUserId: "user_123"                 │
│ )                                               │
│     ↓                                           │
│ ChippiPayAPI.prepareWalletCreation()           │
│     ↓                                           │
│ POST /chipi-wallets/prepare-creation           │
│     ↓                                           │
│ Body: {                                        │
│   "auth_token": "eyJ...",                      │
│   "external_user_id": "user_123",              │
│   "metadata": {"source": "ios_app"}            │
│ }                                               │
│     ↓                                           │
│ ChippiPay Backend:                             │
│ • Validates JWT token                          │
│ • Generates key pair (public + private)        │
│ • Encrypts private key                         │
│ • Creates wallet ID                            │
│     ↓                                           │
│ Returns: {                                     │
│   "wallet_id": "wallet_abc123",                │
│   "public_key": "0x049d36...",                 │
│   "encrypted_private_key": "enc_..."           │
│ }                                               │
└────────────────────────────────────────────────┘
    ↓
┌────────────────────────────────────────────────┐
│ PHASE 3: Save Wallet                           │
│                                                 │
│ ChippiPayAPI.saveWallet(                       │
│     walletId: "wallet_abc123",                 │
│     publicKey: "0x049d36...",                  │
│     encryptedPrivateKey: "enc_...",            │
│     authToken: supabaseJWT                     │
│ )                                               │
│     ↓                                           │
│ POST /chipi-wallets                            │
│     ↓                                           │
│ ChippiPay Backend:                             │
│ • Validates all parameters                     │
│ • Links wallet to user account                 │
│ • Activates wallet                             │
│     ↓                                           │
│ Returns: { "success": true }                   │
└────────────────────────────────────────────────┘
    ↓
┌────────────────────────────────────────────────┐
│ PHASE 4: Store Locally                         │
│                                                 │
│ ChippiPayManager:                              │
│ • currentWallet = ChippiWallet(...)            │
│ • currentWalletId = "wallet_abc123"            │
│ • isConnected = true                           │
│     ↓                                           │
│ KeychainHelper:                                │
│ • Save wallet ID to keychain                   │
│     ↓                                           │
│ UserDefaults:                                  │
│ • Mark wallet as created                       │
└────────────────────────────────────────────────┘
    ↓
✅ Wallet Created!
   User can now make gasless purchases
```

---

## Error Handling Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                    Error Handling Strategy                        │
└──────────────────────────────────────────────────────────────────┘

API Call Made
    ↓
    ├─→ Success (200-299) → Process Response
    │
    └─→ Error Detected
            ↓
        ┌────────────────────────────────────┐
        │ What Type of Error?                 │
        └────────────────────────────────────┘
            ↓
            ├─→ Network Error (no internet)
            │       ↓
            │   Show: "Check your internet connection"
            │       ↓
            │   Retry button available
            │
            ├─→ 401 Unauthorized (bad API keys)
            │       ↓
            │   Show: "API credentials invalid"
            │       ↓
            │   Prompt to reconfigure keys
            │
            ├─→ 404 Not Found (wrong endpoint)
            │       ↓
            │   Log error details
            │       ↓
            │   Show: "Service temporarily unavailable"
            │
            ├─→ 429 Rate Limited (too many requests)
            │       ↓
            │   Wait exponentially
            │       ↓
            │   Auto-retry after delay
            │
            ├─→ 500 Server Error (ChippiPay issue)
            │       ↓
            │   Show: "ChippiPay service error"
            │       ↓
            │   Retry button available
            │
            └─→ Timeout (request too slow)
                    ↓
                Show: "Request timed out"
                    ↓
                Retry button available

For All Errors:
    ↓
┌────────────────────────────────────────────────┐
│ 1. Log error details to console                │
│ 2. Set errorMessage in manager                 │
│ 3. Update isLoading = false                    │
│ 4. Show user-friendly message                  │
│ 5. Provide actionable next steps               │
└────────────────────────────────────────────────┘
```

---

## Data Flow Summary

```
[User Input] → [iOS App] → [Starknet Blockchain]
                    ↓
              [iOS App] → [ChippiPay API]
                    ↓
              [iOS App] ← [ChippiPay Backend]
                    ↓
            [User sees result]

Detailed:
─────────────────────────────────────────────────
User Action          iOS Layer              Backend
─────────────────────────────────────────────────
Deposit STRK    →    StarknetManager    →   Vault Contract
                                              (Blockchain)

Create Wallet   →    ChippiPayManager   →   ChippiPay API
                     KeychainHelper          (Wallet DB)

Browse Services →    ChippiPayManager   →   ChippiPay API
                                              (Services DB)

Purchase        →    StarknetManager    →   Vault Contract
                     (withdraw)              (Blockchain)
                     ↓
                     ChippiPayManager   →   ChippiPay API
                     (purchase)              (Transaction DB)
                     ↓
                     ServicePurchaseView ←  ChippiPay API
                     (confirmation)          (Webhook)
```

---

## Security & Trust Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                  Security & Trust Model                           │
└──────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────┐
│ What the User Controls:              │
│                                      │
│ • Starknet wallet private key        │
│ • Vault contract (self-custody)      │
│ • ChippiPay wallet password          │
│ • When to withdraw from vault        │
│ • Which services to purchase         │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ What's Stored Securely on Device:   │
│                                      │
│ • ChippiPay API keys (Keychain)      │
│ • ChippiPay wallet ID (Keychain)     │
│ • User preferences (UserDefaults)    │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ What ChippiPay Never Sees:          │
│                                      │
│ • Starknet private key               │
│ • Vault funds (until withdrawal)     │
│ • User's choice to not use service   │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Trust Boundaries:                    │
│                                      │
│ iOS App ←→ User (Trust Required)     │
│ iOS App ←→ Starknet (Trustless)      │
│ iOS App ←→ ChippiPay (API Trust)     │
│ ChippiPay ←→ Services (ChippiPay)    │
└─────────────────────────────────────┘
```

---

**Version**: 1.0
**Last Updated**: October 12, 2025
**Status**: Production-ready
