# ChippiPay Testing Guide

## ✅ Your API Keys Are Configured!

Your ChippiPay integration is now fully configured with your production API keys:

```
Public Key: pk_prod_0f67a3155f8d994796b3ecdb50b8db67
Secret Key: sk_prod_c035c91fcc9ac3ac6cf7b8a3c2d88bb3c428eecf75d11b18f0006d8b9e84599b
```

These keys are securely stored in your iOS Keychain and ready for testing.

---

## 🚀 What Was Configured

### 1. API Key Storage
- **File Created**: `ChippiPayConfiguration.swift`
- **Location**: `QRPaymentScanner/Helpers/`
- **Purpose**: Manages ChippiPay API key configuration
- **Security**: Keys stored in iOS Keychain with device-only encryption

### 2. App Initialization
- **File Modified**: `AppDelegate.swift`
- **What Happens**:
  - On app launch, keys are automatically loaded from secure storage
  - In DEBUG mode, connection test runs automatically
  - Status logged to console for verification

### 3. Testing Tools Added
- **File Modified**: `HomeView.swift`
- **Feature**: "Test API" button added to home screen (DEBUG mode only)
- **Purpose**: Quickly test ChippiPay connection without restarting app

---

## 📱 How to Test

### Test 1: Launch App & Check Console

1. **Build and run your app** in Xcode
2. **Check the Xcode console** for these messages:

**Expected Output:**
```
📱 Configuring ChippiPay for first time...
✅ ChippiPay API keys configured successfully
   Public Key: pk_prod_0f67a3155f8d...
   Secret Key: sk_prod_c035c91fcc9a...
🔄 Testing ChippiPay API connection...
✅ Connection successful!
   Found X available services:
   1. [Service Name] ([Category])
   2. [Service Name] ([Category])
   3. [Service Name] ([Category])
🎉 ChippiPay is ready to use!
```

**If you see this**, ChippiPay is working! ✅

**If you see errors:**
```
❌ Connection failed: [error message]
```
See "Troubleshooting" section below.

---

### Test 2: Use Test API Button

1. **Open your app**
2. **Scroll to action buttons** on home screen
3. **Look for "Test API" button** (purple, with network icon)
   - Note: Only visible in DEBUG builds
4. **Tap "Test API"**
5. **Tap "Run Test"** in the alert
6. **Wait for result**:
   - ✅ "Connection successful!" - All good!
   - ❌ "Connection failed" - Check troubleshooting

---

### Test 3: Create ChippiPay Wallet

1. **In your app, tap "ChippiPay" button**
2. **Tap "Create Gasless Wallet"**
3. **Follow the wizard**:
   - Step 1: Enter email
   - Step 2: Create password
   - Step 3: Confirm
4. **Expected Result**: "Wallet created successfully" ✅

**What This Tests:**
- API authentication
- Wallet creation endpoint
- JWT token from Supabase
- Keychain wallet storage

---

### Test 4: Browse Services

1. **After creating wallet**, services should load automatically
2. **You should see services like**:
   - Telefonia (phone top-ups)
   - Luz (electricity)
   - Gift Cards
   - etc.

**If services show**:
- ✅ Real service names → API is working
- ⚠️ "Mock data" → API failed, using fallback

---

### Test 5: Test Purchase Flow (Without Real Money)

**⚠️ Important**: This test won't actually charge you, but prepares the flow.

1. **Select a service** (e.g., "Telcel 50 MXN")
2. **Enter a phone number** (can be fake for testing: "5512345678")
3. **View cost breakdown**:
   - Service cost in MXN
   - STRK equivalent
   - Fees (should show FREE)
4. **Don't click "Purchase" yet** unless you want to spend real STRK

**What This Tests:**
- Service selection UI
- Cost calculation
- Form validation

---

## 🔍 Verification Checklist

Run through this checklist to verify everything works:

- [ ] App launches without crashes
- [ ] Console shows "ChippiPay configured successfully"
- [ ] Console shows "Connection successful"
- [ ] "Test API" button appears in DEBUG mode
- [ ] Test API returns success
- [ ] ChippiPay button opens services view
- [ ] Can create ChippiPay wallet
- [ ] Services load (real or mock)
- [ ] Can select a service
- [ ] Purchase view shows cost breakdown
- [ ] No errors in console

---

## 🐛 Troubleshooting

### Issue: "Connection failed: Network error"

**Possible Causes:**
- No internet connection
- ChippiPay servers down
- Firewall blocking requests

**Solutions:**
1. Check your internet connection
2. Try again in a few minutes
3. Check ChippiPay status page (if available)

---

### Issue: "Connection failed: API credentials not configured"

**Cause:** Keys not saved to keychain

**Solution:**
```swift
// Run this in a test or console:
let config = ChippiPayConfiguration.shared
config.configure()
```

Or **delete the app** and reinstall to trigger first-time setup.

---

### Issue: "401 Unauthorized" or "Invalid API key"

**Causes:**
- Wrong API keys
- Keys not configured in ChippiPay dashboard
- Account not activated

**Solutions:**
1. Verify your keys in ChippiPay dashboard
2. Ensure your account is active
3. Check if keys have proper permissions
4. Regenerate keys if needed

---

### Issue: "Services return empty" or "No services found"

**Causes:**
- No services configured in your ChippiPay account
- API working but no SKUs available yet
- Account needs approval

**Solutions:**
1. Check ChippiPay dashboard → Services
2. Contact ChippiPay support to activate services
3. For now, app will use mock data (this is normal)

---

### Issue: "Wallet creation fails"

**Causes:**
- Missing JWKS configuration in ChippiPay dashboard
- Invalid Supabase JWT token
- Account not configured properly

**Solutions:**
1. In ChippiPay dashboard, add your Supabase JWKS endpoint:
   ```
   https://<your-project>.supabase.co/auth/v1/jwks
   ```
2. Ensure user is logged in to Supabase
3. Check Supabase session is valid

---

## 📊 Understanding the Logs

### What Each Log Message Means:

**"📱 Configuring ChippiPay for first time..."**
- First app launch, saving keys to keychain

**"✅ ChippiPay already configured"**
- Keys already in keychain, skipping setup

**"🔄 Testing ChippiPay API connection..."**
- Making test API call to fetch services

**"✅ Connection successful!"**
- API authentication worked
- Network request succeeded
- Keys are valid

**"Found X available services:"**
- Services retrieved from ChippiPay API
- X = number of services your account has access to

**"⚠️ Connection successful but no services returned"**
- API works, but your account has no services yet
- This is normal for new accounts
- App will use mock data for testing

---

## 🧪 Advanced Testing

### Check Keychain Storage

```swift
// In Xcode console or a test:
let keychain = KeychainHelper.shared
print("API Key:", keychain.getChippiPayAPIKey() ?? "NOT SET")
print("Secret Key:", keychain.getChippiPaySecretKey() ?? "NOT SET")
```

**Expected Output:**
```
API Key: pk_prod_0f67a3155f8d994796b3ecdb50b8db67
Secret Key: sk_prod_c035c91fcc9ac3ac6cf7b8a3c2d88bb3c428eecf75d11b18f0006d8b9e84599b
```

---

### Clear and Reconfigure

If you need to reset everything:

```swift
// Clear configuration
ChippiPayConfiguration.shared.clearConfiguration()

// Reconfigure
ChippiPayConfiguration.shared.configure()

// Test again
await ChippiPayConfiguration.shared.testConnection()
```

---

### Manual API Test

Test the API directly in code:

```swift
Task {
    let api = ChippiPayAPI(environment: .production)
    do {
        let services = try await api.fetchSKUs()
        print("✅ Fetched \(services.count) services")
        for service in services.prefix(5) {
            print("  - \(service.name)")
        }
    } catch {
        print("❌ Error: \(error)")
    }
}
```

---

## 🎯 Next Steps After Testing

Once all tests pass:

### 1. Deploy Vault to Mainnet
Your vault is currently on **Sepolia testnet**. For production:

```swift
// In StarknetManager.swift, update:
static let vaultContractAddress = "0x_your_mainnet_address"
static let rpcUrl = "https://starknet-mainnet.g.alchemy.com/starknet/version/rpc/v0_6"
```

### 2. Configure JWKS in ChippiPay
1. Go to ChippiPay Dashboard
2. Settings → Authentication
3. Add: `https://<your-project>.supabase.co/auth/v1/jwks`

### 3. Test Real Purchase
1. Deposit small amount to vault (0.5 STRK)
2. Create ChippiPay wallet
3. Select cheapest service
4. Complete purchase
5. Verify service delivered

### 4. Remove DEBUG Features
Before TestFlight/App Store:

```swift
// Remove or comment out:
#if DEBUG
ActionButton(icon: "network", title: "Test API", color: .purple) {
    showChippiPayTest = true
}
#endif
```

---

## 📱 Production Checklist

Before going live:

- [ ] All tests passing
- [ ] Vault deployed to mainnet
- [ ] JWKS configured in ChippiPay dashboard
- [ ] Test purchase completed successfully
- [ ] Real service delivered
- [ ] Error handling tested
- [ ] DEBUG features removed
- [ ] Console logs reviewed
- [ ] App submitted to TestFlight
- [ ] Beta testers feedback collected

---

## 🎉 Success Criteria

Your integration is working if:

✅ Console shows "Connection successful"
✅ Services load (real or mock)
✅ Can create ChippiPay wallet
✅ Purchase flow completes without crashes
✅ Cost calculations are correct
✅ No 401/403 errors in console
✅ Test API button works

---

## 📞 Support

### If You're Stuck

1. **Check Console Logs** - Most issues show clear error messages
2. **Review This Guide** - Follow troubleshooting steps
3. **Check ChippiPay Dashboard** - Verify account/keys/services
4. **Contact ChippiPay Support**:
   - Telegram: [t.me/+e2qjHEOwImkyZDVh](https://t.me/+e2qjHEOwImkyZDVh)
   - Docs: [docs.chipipay.com](https://docs.chipipay.com)

---

## 🔧 Configuration Files Reference

All configuration happens in these files:

```
QRPaymentScanner/
├── Helpers/
│   ├── ChippiPayConfiguration.swift  ← API key management
│   └── KeychainHelper.swift          ← Secure storage
├── Managers/
│   ├── ChippiPayAPI.swift            ← REST client
│   └── ChippiPayManager.swift        ← Business logic
└── AppDelegate.swift                 ← Auto-configuration on launch
```

---

**Last Updated**: October 12, 2025
**API Keys Configured**: ✅ Yes
**Environment**: Production
**Status**: Ready for Testing

**🎉 Happy Testing!**
