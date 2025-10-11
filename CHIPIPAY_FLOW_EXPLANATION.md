# ChippiPay Payment Flow - Step by Step

## 🎯 Example: User wants to top up their phone with $50 MXN

### Step 1: Service Selection
```
User taps "ChippiPay" → Browse Services → Selects "Telcel 50 MXN Top-up"
```

### Step 2: Payment Details
```swift
// User enters:
- Phone Number: 5551234567
- Service: Telcel 50 MXN Top-up
- Cost: $50 MXN = ~2.5 STRK (based on current rates)
```

### Step 3: Cost Calculation
```swift
// ChippiPayManager calculates:
let mxnAmount = 50.0
let strkAmount = chippiPayManager.calculateSTRKAmount(for: mxnAmount)
// Result: ~2.5 STRK

// Cost breakdown shown to user:
Service Cost: $50 MXN
STRK Equivalent: 2.5 STRK
Gas Fee: FREE ⚡ (ChippiPay covers it)
ChippiPay Fee: FREE ⚡
Total: 2.5 STRK from vault
```

### Step 4: Transaction Execution
```swift
// When user taps "Purchase with ChippiPay":

1. App withdraws 2.5 STRK from vault contract
   └── starkli invoke vault_contract withdraw 2.5_STRK

2. App deposits STRK to ChippiPay contract (gasless)
   └── ChippiPay API handles the deposit

3. ChippiPay processes the service payment
   └── POST /sku-transactions with service details

4. ChippiPay pays Telcel for the phone top-up
   └── User's phone gets $50 credit

5. User receives confirmation
   └── Transaction ID + Service confirmation
```

### Step 5: What Happens Behind the Scenes

```
Your Vault Contract (Sepolia)
    ↓ [User withdraws 2.5 STRK]
User's Wallet
    ↓ [User approves ChippiPay]
ChippiPay Contract (Mainnet)
    ↓ [ChippiPay processes gaslessly]
Telcel/Service Provider
    ↓ [Service delivered]
User's Phone (+$50 credit) ✅
```

## 🔧 Technical Implementation Flow

### 1. Wallet Creation Flow
```swift
// ChippiWalletCreationView.swift
func createWallet() {
    // Step 1: Generate Starknet keypair
    let privateKey = stark.randomAddress()
    let publicKey = ec.starkCurve.getStarkKey(privateKey)
    
    // Step 2: Encrypt private key with user password
    let encryptedKey = encryptPrivateKey(privateKey, userPassword)
    
    // Step 3: Calculate future wallet address
    let walletAddress = calculateContractAddress(publicKey, classHash, constructorData)
    
    // Step 4: Sign creation message
    let signature = account.signMessage(typeData)
    
    // Step 5: Submit to ChippiPay API
    let response = await fetch("https://api.chipipay.com/v1/chipi-wallets", {
        method: "POST",
        headers: {
            'Authorization': 'Bearer jwt_token',
            'x-api-key': 'pk_prod_your_key'
        },
        body: {
            publicKey,
            userSignature,
            encryptedPrivateKey,
            deploymentData
        }
    })
    
    // Step 6: Wallet created and ready!
}
```

### 2. Service Purchase Flow
```swift
// ServicePurchaseView.swift
func purchaseService() {
    // Step 1: Get service details
    let service = selectedService // e.g., Telcel 50 MXN
    let reference = phoneNumber   // e.g., 5551234567
    let amount = 50.0            // MXN
    
    // Step 2: Calculate STRK amount
    let strkAmount = chippiPayManager.calculateSTRKAmount(for: amount)
    
    // Step 3: Withdraw from vault (existing StarknetManager)
    let vaultTxHash = await starknetManager.withdrawFromVault(amount: strkAmount)
    
    // Step 4: Purchase via ChippiPay
    let result = await chippiPayManager.purchaseService(
        skuId: service.id,
        amount: amount,
        reference: reference,
        vaultTransactionHash: vaultTxHash
    )
    
    // Step 5: Show confirmation
    if result.success {
        showConfirmation = true
        // User's phone now has $50 credit!
    }
}
```

### 3. API Communication Flow
```swift
// ChippiPayManager.swift
class ChippiPayManager {
    
    // Get available services
    func fetchAvailableServices() async throws {
        let response = await fetch("https://api.chipipay.com/v1/skus", {
            method: "GET",
            headers: {
                'Authorization': 'Bearer sk_prod_your_secret',
                'Content-Type': 'application/json'
            }
        })
        
        // Returns: Phone services, utilities, gift cards, etc.
    }
    
    // Execute purchase
    func purchaseService(skuId: String, amount: Double, reference: String, vaultTransactionHash: String) async throws {
        let response = await fetch("https://api.chipipay.com/v1/sku-transactions", {
            method: "POST",
            headers: {
                'Authorization': 'Bearer sk_prod_your_secret',
                'Content-Type': 'application/json'
            },
            body: {
                walletAddress: chippiWallet.publicKey,
                skuId: skuId,
                chain: "STARKNET",
                chainToken: "STRK",
                mxnAmount: amount,
                reference: reference,
                transactionHash: vaultTransactionHash
            }
        })
        
        // ChippiPay handles the rest gaslessly!
    }
}
```

## 🎭 User Experience Flow

### Current Experience (Without ChippiPay):
```
Want to top up phone? 
→ Leave app 
→ Go to Telcel website/store 
→ Pay with traditional payment 
→ Return to app
```

### New Experience (With ChippiPay):
```
Want to top up phone?
→ Tap "ChippiPay" in app ⚡
→ Select "Telcel Top-up" 
→ Enter phone number
→ Tap "Purchase" (gasless!)
→ Done! Phone topped up ✅
```

## 💡 Key Benefits of This Flow

### For Users:
- **No Gas Fees**: Save ~$0.50 per transaction
- **Real Utility**: Use crypto for daily expenses
- **One App**: Vault + payments in single interface
- **Instant**: No waiting for block confirmations
- **Secure**: Self-custodial, encrypted keys

### For Your App:
- **Competitive Edge**: First mobile app with gasless payments
- **User Retention**: Real-world utility keeps users engaged
- **Revenue Potential**: Partner fees from ChippiPay
- **Market Expansion**: Appeals to non-crypto users

### Technical Advantages:
- **Gasless UX**: Users never worry about gas fees
- **Scalable**: ChippiPay handles service provider integrations
- **Secure**: Maintains decentralization principles
- **Flexible**: Easy to add new service categories

## 🔮 Production Deployment Flow

### Phase 1: Setup (1-2 days)
1. Register at https://dashboard.chipipay.com/
2. Get production API keys
3. Configure JWKS endpoint
4. Deploy vault contract to mainnet

### Phase 2: Integration (2-3 days)
1. Replace mock API calls with real endpoints
2. Configure mainnet RPC endpoints
3. Test with real STRK tokens
4. Implement webhook handling

### Phase 3: Testing (3-5 days)
1. Test real service purchases
2. Verify gasless transactions
3. Confirm service delivery
4. Load testing and optimization

### Phase 4: Launch (1 day)
1. App Store submission
2. User documentation
3. Marketing materials
4. Community announcement

This flow transforms your vault from a simple storage solution into a revolutionary payment platform that bridges crypto and real-world services! 🚀⚡