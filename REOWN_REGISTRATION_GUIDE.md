# Reown Cloud Registration Guide

## ✅ Answer: YES, you SHOULD register your app on Reown Cloud

Your app needs to be properly registered on Reown Cloud Dashboard for production use. While development may work with just a Project ID, proper registration ensures:
- ✅ Correct deep linking configuration
- ✅ App metadata (name, icon, description)
- ✅ Verified redirect URLs
- ✅ Better debugging and analytics
- ✅ Production-ready deployment

## 📋 Registration Steps

### Step 1: Access Reown Cloud Dashboard

1. Go to: https://cloud.reown.com/
2. Sign in with your account (or create one)
3. Navigate to your project with ID: `18b7d657eedae828d0e6d780a80eded9`

### Step 2: Configure App Metadata

In your project settings, add:

```json
{
  "name": "QR Payment Scanner",
  "description": "Starknet payment application with Braavos wallet integration",
  "url": "https://yourapp.com",
  "icons": [
    "https://yourapp.com/icon-512x512.png"
  ]
}
```

### Step 3: Add iOS App Configuration

**Bundle Identifier:**
```
com.vj.QRPaymentScanner
```

**Redirect URLs:** (Add these to the dashboard)
```
qrpaymentscanner://
starknet://
```

**Universal Link Domain:** (Optional but recommended)
```
yourapp.com
```

### Step 4: Verify URL Schemes

Confirm these are in your `Info.plist` (✅ already configured):

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.vj.QRPaymentScanner</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>starknet</string>
            <string>qrpaymentscanner</string>
        </array>
    </dict>
</array>
```

### Step 5: Configure Query Schemes

Verify `LSApplicationQueriesSchemes` in `Info.plist` (✅ already configured):

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>argent</string>
    <string>argentx</string>
    <string>argentmobile</string>
    <string>readywallet</string>
    <string>ready</string>
    <string>braavos</string>
    <string>wc</string>
</array>
```

## 🔧 Updated Deep Linking Implementation

I've updated `BraavosConnectionManager.swift` with THREE methods:

### Method 1: AppKit.launchCurrentWallet() ⭐ RECOMMENDED

```swift
func openBraavos() {
    print("🦾 Opening Braavos wallet with WalletConnect...")
    
    guard !connectionURI.isEmpty else {
        print("⚠️ No connection URI available - call connect() first")
        return
    }
    
    // Best method: Let AppKit handle everything
    AppKit.instance.launchCurrentWallet()
}
```

**Why this is best:**
- ✅ AppKit knows the correct format for each wallet
- ✅ Handles universal links automatically
- ✅ Manages deep linking fallbacks
- ✅ No manual URL encoding needed
- ✅ Works across all supported wallets

### Method 2: Manual Universal Links

```swift
func openBraavosManually() {
    // Uses: https://starknet.app.link/wc?uri=<encoded_uri>
    // This is the format from starknet-deeplink library
}
```

Use this if `launchCurrentWallet()` doesn't work for some reason.

### Method 3: Custom URL Scheme (Legacy)

```swift
func openBraavosWithCustomScheme() {
    // Uses: braavos://wc?uri=<encoded_uri>
    // This is what was causing "unsupported link" error
}
```

This is the OLD method that was failing. Keep it as fallback only.

## 🧪 Testing Checklist

After registration, test in this order:

### 1. Verify AppKit Configuration
```swift
// In AppDelegate, check console for:
print("✅ Reown AppKit configured successfully")
print("Project ID: 18b7d657eedae828d0e6d780a80eded9")
```

### 2. Test Connection Flow
```swift
// In your view:
let manager = BraavosConnectionManager()

// Step 1: Create pairing
manager.connect()

// Step 2: Wait for QR code/URI
// Should see: manager.connectionURI populated
// Should see: manager.qrCodeImage generated

// Step 3: Open wallet (using NEW method)
manager.openBraavos()  // Uses AppKit.launchCurrentWallet()
```

### 3. Verify Deep Linking
- ✅ Braavos app opens (not "unsupported link")
- ✅ Shows WalletConnect approval screen
- ✅ Can approve connection
- ✅ App receives session settled event
- ✅ Address is extracted: `manager.connectedAddress`

### 4. Monitor Console Output
Look for these success messages:
```
🦾 Opening Braavos wallet with WalletConnect...
📱 Using AppKit.launchCurrentWallet() - recommended method
✅ Session settled!
📍 Connected Address: 0x...
```

## 🐛 Troubleshooting

### Still getting "unsupported link"?

**Try Method 2** (universal links):
```swift
manager.openBraavosManually()
```

This uses `https://starknet.app.link/wc?uri=` instead of `braavos://wc?uri=`

### Braavos not opening at all?

Check:
1. ✅ Braavos app is installed on device
2. ✅ `LSApplicationQueriesSchemes` includes `braavos`
3. ✅ Running on physical device (not simulator)
4. ✅ Console shows connection URI is generated

### Session not settling?

Verify:
1. ✅ AppKit configuration includes Starknet methods
2. ✅ Networking.configure() called BEFORE AppKit.configure()
3. ✅ Session event subscriptions are active
4. ✅ Approved connection in Braavos wallet

## 📱 Complete Usage Example

```swift
import SwiftUI
import ReownAppKit

struct BraavosConnectView: View {
    @StateObject private var walletManager = BraavosConnectionManager()
    
    var body: some View {
        VStack(spacing: 20) {
            if !walletManager.isConnected {
                // STEP 1: Create pairing and show QR
                Button("Connect Braavos") {
                    walletManager.connect()
                }
                
                // STEP 2: Show QR code for scanning
                if let qrImage = walletManager.qrCodeImage {
                    Image(uiImage: qrImage)
                        .resizable()
                        .frame(width: 250, height: 250)
                    
                    Text("Scan with Braavos or tap below")
                        .font(.caption)
                }
                
                // STEP 3: Deep link button (NEW METHOD)
                if !walletManager.connectionURI.isEmpty {
                    Button("Open Braavos App") {
                        walletManager.openBraavos()  // ⭐ Uses AppKit
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                // Connected!
                VStack {
                    Text("✅ Connected")
                        .font(.headline)
                    
                    if let address = walletManager.connectedAddress {
                        Text("Address: \(address.prefix(10))...")
                            .font(.caption)
                            .monospaced()
                    }
                    
                    Button("Disconnect") {
                        Task {
                            await walletManager.disconnect()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
    }
}
```

## 🎯 Next Steps

1. **Register on Reown Cloud Dashboard** (if not already done)
   - Add app metadata
   - Configure bundle ID: `com.vj.QRPaymentScanner`
   - Add redirect URLs

2. **Test with NEW deep linking method**
   - Build and run app
   - Call `manager.connect()`
   - Wait for QR code
   - Call `manager.openBraavos()` (now uses AppKit)
   - Verify Braavos opens correctly

3. **If still issues, try fallback methods**
   - Test `manager.openBraavosManually()` (universal links)
   - Test `manager.openBraavosWithCustomScheme()` (custom scheme)

4. **Monitor and debug**
   - Check console for all print statements
   - Verify session events are fired
   - Confirm address extraction works

## 📚 References

- Reown Cloud Dashboard: https://cloud.reown.com/
- Reown AppKit Docs: https://docs.reown.com/appkit/ios/core/installation
- Starknet Deep Links: https://github.com/myBraavos/starknet-deeplink
- Your Implementation Docs: 
  - `REOWN_APPKIT_IMPLEMENTATION.md`
  - `FIXING_UNSUPPORTED_LINK_ERROR.md`

## ✅ Summary

**YES**, register your app on Reown Cloud Dashboard for production.

**Primary fix:** Updated `BraavosConnectionManager.openBraavos()` to use `AppKit.instance.launchCurrentWallet()` instead of manual deep linking. This is the recommended approach and should resolve the "unsupported link" error.

**Alternative fix:** If needed, use universal links `https://starknet.app.link/wc?uri=` via `openBraavosManually()` method.

The custom URL scheme `braavos://wc?uri=` was causing the error because it's not the proper format for WalletConnect deep links on Starknet. AppKit handles this complexity automatically.
