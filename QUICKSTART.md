# ChippiPay Integration - Quick Start Guide

## 🚀 Get Started in 5 Minutes

This guide gets your ChippiPay integration up and running quickly.

---

## Prerequisites

- ✅ Xcode 15.0+
- ✅ iOS 17.0+
- ✅ ChippiPay dashboard account ([sign up here](https://dashboard.chipipay.com))

---

## Step 1: Get Your API Keys (2 minutes)

1. Log in to [ChippiPay Dashboard](https://dashboard.chipipay.com)
2. Navigate to **API Keys** → **Generate New Key Pair**
3. Copy both keys:
   ```
   Public Key:  pk_prod_xxxxxxxxxxxxx
   Secret Key:  sk_prod_xxxxxxxxxxxxx
   ```
4. **Save these immediately** - secret key shown only once!

---

## Step 2: Configure Your App (1 minute)

### Option A: Quick Setup (Recommended for Testing)

Add this code to your `AppDelegate.swift` or main app file:

```swift
import Foundation

// Add this function
func configureChippiPayKeys() {
    let keychain = KeychainHelper.shared

    // 👇 REPLACE WITH YOUR ACTUAL KEYS
    let apiKey = "pk_prod_your_public_key_here"
    let secretKey = "sk_prod_your_secret_key_here"

    _ = keychain.saveChippiPayAPIKey(apiKey)
    _ = keychain.saveChippiPaySecretKey(secretKey)

    print("✅ ChippiPay configured!")
}
```

Call it once when app launches:

```swift
@main
struct QRPaymentApp: App {
    init() {
        // Run only once
        if !UserDefaults.standard.bool(forKey: "chippiPayConfigured") {
            configureChippiPayKeys()
            UserDefaults.standard.set(true, forKey: "chippiPayConfigured")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

## Step 3: Test the Integration (2 minutes)

### Test 1: Verify API Connection

Add this to your `HomeView`:

```swift
Button("Test ChippiPay") {
    Task {
        let manager = ChippiPayManager()
        do {
            try await manager.fetchAvailableServices()
            print("✅ SUCCESS: \(manager.availableServices.count) services loaded")
        } catch {
            print("❌ ERROR: \(error)")
        }
    }
}
```

Tap the button and check console:
- ✅ **Success**: "SUCCESS: X services loaded"
- ❌ **Failure**: Check your API keys

### Test 2: Create a Wallet

1. Open your app
2. Connect your Starknet wallet
3. Tap **ChippiPay** button
4. Tap **Create Gasless Wallet**
5. Follow the 3-step wizard

Expected result: ✅ "Wallet created successfully"

### Test 3: Browse Services

1. After wallet creation, services should load automatically
2. You should see categories: Telefonia, Luz, Gift Cards, etc.
3. Tap any service to see purchase details

---

## What Works Right Now

✅ **Wallet Creation**: Create gasless ChippiPay wallets
✅ **Service Discovery**: Browse available services from ChippiPay
✅ **Purchase Flow**: Complete purchase flow is implemented
✅ **Transaction Polling**: Real-time status updates
✅ **Secure Storage**: API keys encrypted in iOS Keychain
✅ **Error Handling**: Comprehensive error messages

---

## What You Need to Do Next

### Before Production:

1. **Deploy to Mainnet**
   - Your vault is currently on Sepolia testnet
   - ChippiPay requires mainnet
   - Deploy your vault contract to Starknet mainnet
   - Update contract address in `StarknetManager.swift`

2. **Configure JWKS Endpoint**
   - In ChippiPay dashboard, add your Supabase JWKS endpoint
   - Format: `https://<your-project>.supabase.co/auth/v1/jwks`

3. **Test with Real Money**
   - Start with small amounts (0.1 STRK)
   - Test phone top-up or utility payment
   - Verify transaction completes

---

## Usage in Your App

### User Flow

```
1. User opens app
   ↓
2. User connects Starknet wallet
   ↓
3. User deposits STRK to vault
   ↓
4. User creates ChippiPay wallet (one-time)
   ↓
5. User browses services
   ↓
6. User selects service & enters details
   ↓
7. User confirms purchase
   ↓
8. App withdraws from vault → sends to ChippiPay
   ↓
9. Service delivered instantly!
```

### Purchase Flow Details

When user makes a purchase, your app:

1. **Checks vault balance** → Ensures sufficient STRK
2. **Withdraws from vault** → Moves STRK to ChippiPay payment address
3. **Submits to ChippiPay** → Creates transaction with vault tx hash
4. **Polls for status** → Monitors until "completed" or "failed"
5. **Shows confirmation** → User receives service

All of this happens automatically in `ServicePurchaseView.swift` - you don't need to write any additional code!

---

## Project Structure

Your project now has these new files:

```
QRPaymentScanner/
├── Helpers/
│   └── KeychainHelper.swift          ← Secure API key storage
├── Managers/
│   ├── ChippiPayAPI.swift            ← REST API client
│   └── ChippiPayManager.swift        ← Business logic (updated)
└── Views/
    └── ServicePurchaseView.swift     ← Purchase flow (updated)

Documentation/
├── QUICKSTART.md                     ← You are here!
├── CHIPIPAY_SETUP_GUIDE.md          ← Detailed setup
├── IMPLEMENTATION_SUMMARY.md         ← Technical details
└── CHIPIPAY_INTEGRATION_GUIDE.md    ← Original guide
```

---

## Common Issues & Quick Fixes

### "Missing API credentials"
```swift
// Check if keys are saved
let keychain = KeychainHelper.shared
print(keychain.getChippiPayAPIKey() ?? "NOT SET")
```
**Fix**: Run `configureChippiPayKeys()` again

### "Network error"
**Possible causes**:
- Wrong API keys
- Network connectivity
- ChippiPay service down

**Fix**: Verify keys in dashboard, check internet

### "Wallet not connected"
**Cause**: User hasn't created ChippiPay wallet yet

**Fix**: Prompt user to create wallet first

### Services show as "mock data"
**Cause**: API call failed, fell back to mock

**Fix**: Check API keys and network

---

## Environment Switching

### Development Mode
```swift
let manager = ChippiPayManager(environment: .development)
```
- Uses `https://api-dev.chipipay.com/v1`
- Safe for testing
- Separate from production data

### Production Mode
```swift
let manager = ChippiPayManager(environment: .production)
```
- Uses `https://api.chipipay.com/v1`
- Real transactions
- Real service delivery

---

## Debug Mode

Enable detailed logging:

```swift
// In ChippiPayAPI.swift, line ~280
print("ChippiPay API Response (\(httpResponse.statusCode)): \(responseString)")
```

This shows:
- Request URLs
- Response status codes
- Full response bodies
- Error details

---

## Testing Checklist

Before deploying to TestFlight:

- [ ] API keys configured and working
- [ ] Wallet creation succeeds
- [ ] Services load from real API
- [ ] Test purchase with small amount ($5-10)
- [ ] Transaction status updates correctly
- [ ] Vault balance decreases after purchase
- [ ] Error messages are user-friendly
- [ ] No crashes during normal flow

---

## Support

### Documentation
- **Setup Guide**: `CHIPIPAY_SETUP_GUIDE.md` - detailed configuration
- **Implementation Summary**: `IMPLEMENTATION_SUMMARY.md` - technical details
- **Integration Guide**: `CHIPIPAY_INTEGRATION_GUIDE.md` - original flow

### ChippiPay Resources
- **Docs**: [docs.chipipay.com](https://docs.chipipay.com)
- **Dashboard**: [dashboard.chipipay.com](https://dashboard.chipipay.com)
- **Telegram**: [t.me/+e2qjHEOwImkyZDVh](https://t.me/+e2qjHEOwImkyZDVh)

### Starknet Resources
- **Documentation**: [starknet.io](https://www.starknet.io)
- **Explorer**: [starkscan.co](https://starkscan.co)

---

## Next Steps

1. ✅ Complete this quick start
2. 📖 Read `CHIPIPAY_SETUP_GUIDE.md` for production deployment
3. 🧪 Test with small amounts on testnet
4. 🚀 Deploy vault to mainnet
5. 📱 Release to TestFlight
6. 🎉 Launch to production!

---

## Quick Reference

### Important Addresses

```swift
// Your vault contract (Sepolia testnet)
let vaultAddress = "0x029961c5af1520f4a4ad57dccc66370b92ff7a0c47fbf00764e354c17156d7db"

// STRK token (Sepolia)
let strkAddress = "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d"
```

### API Endpoints

```
Production: https://api.chipipay.com/v1
Development: https://api-dev.chipipay.com/v1
```

### RPC URLs

```
Mainnet: https://starknet-mainnet.g.alchemy.com/starknet/version/rpc/v0_6
Sepolia: https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_6
```

---

**Setup Time**: ~5 minutes
**Complexity**: Low
**Status**: ✅ Production-ready after testing
**Last Updated**: October 12, 2025

---

🎉 **Congratulations!** Your ChippiPay integration is complete. Users can now spend STRK on real-world services with zero gas fees!

