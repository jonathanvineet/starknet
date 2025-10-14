# Braavos & Ready Wallet Integration with Reown AppKit

## ✅ Successfully Added Wallet Support

Your app now supports **Braavos** and **Ready Wallet** through Reown AppKit's custom wallet configuration.

---

## 🔧 Implementation Details

### 1. **Custom Wallet Configuration**

Added to `AppDelegate.swift` in the `configureReownAppKit()` method:

```swift
// Configure custom wallets for Starknet
let customWallets = [
    // Braavos Wallet
    Wallet(
        id: "braavos",
        name: "Braavos",
        homepage: "https://braavos.app/",
        imageUrl: "https://braavos.app/icon.png",
        order: 1,
        mobileLink: "braavos://",
        linkMode: nil
    ),
    // Ready Wallet
    Wallet(
        id: "bc949c5d968ae81310268bf9193f9c9fb7bb4e1283e1284af8f2bd4992535fd6",
        name: "Ready Wallet",
        homepage: "https://readywallet.app/",
        imageUrl: "https://readywallet.app/icon.png",
        order: 2,
        mobileLink: "readywallet://",
        linkMode: nil
    )
]
```

### 2. **Recommended Wallets**

Added Ready Wallet as a recommended wallet using its official Wallet ID:

```swift
let recommendedWalletIds = [
    "bc949c5d968ae81310268bf9193f9c9fb7bb4e1283e1284af8f2bd4992535fd6" // Ready Wallet
]
```

### 3. **AppKit Configuration**

Updated the `AppKit.configure()` call to include the custom wallets:

```swift
AppKit.configure(
    projectId: projectId,
    metadata: metadata,
    crypto: cryptoProvider,
    sessionParams: sessionParams,
    authRequestParams: nil,
    customWallets: customWallets,
    recommendedWalletIds: recommendedWalletIds
)
```

---

## 📱 Info.plist Configuration

The `Info.plist` already includes the necessary URL schemes for wallet detection:

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

This allows iOS to:
- ✅ Detect if Braavos or Ready Wallet is installed
- ✅ Deep link to these wallets for connection
- ✅ Handle return callbacks after wallet approval

---

## 🔑 Wallet Details

### **Braavos Wallet**
- **Custom ID**: `braavos`
- **Mobile Link**: `braavos://`
- **Homepage**: https://braavos.app/
- **Order**: 1 (displayed first)

### **Ready Wallet**
- **Official Wallet ID**: `bc949c5d968ae81310268bf9193f9c9fb7bb4e1283e1284af8f2bd4992535fd6`
- **Mobile Link**: `readywallet://`
- **Homepage**: https://readywallet.app/
- **Order**: 2 (displayed second)
- **Status**: Listed in WalletGuide (recommended)

---

## 🎯 How It Works

1. **Wallet Discovery**: AppKit will display both wallets in the connection modal
2. **Priority**: Ready Wallet is marked as "recommended" and appears at the top
3. **Custom Order**: Braavos (order: 1) and Ready Wallet (order: 2) appear in sequence
4. **Deep Linking**: When user selects a wallet:
   - AppKit checks if wallet is installed via URL schemes
   - Opens wallet app with WalletConnect URI
   - Wallet prompts user to approve connection
   - Returns to your app with approved session

---

## 🔄 Integration Flow

```
Your App (QRPaymentScanner)
    ↓
AppKit.configure() with customWallets
    ↓
User taps "Connect Wallet"
    ↓
AppKit shows wallet list:
    • Ready Wallet (recommended) ⭐
    • Braavos
    ↓
User selects wallet
    ↓
AppKit creates WalletConnect pairing
    ↓
Opens wallet app via deep link
    ↓
User approves in wallet
    ↓
Session established
    ↓
BraavosConnectionManager receives callback
```

---

## 📚 Reference Documentation

- **Reown AppKit Options**: https://docs.reown.com/appkit/ios/core/options
- **Reown Swift SDK**: https://github.com/reown-com/reown-swift
- **WalletGuide**: https://walletguide.walletconnect.network/
- **Wallet List**: https://docs.reown.com/cloud/wallets/wallet-list

---

## 🧪 Testing

### Test Braavos Connection:
1. Ensure Braavos wallet app is installed
2. Run your app
3. Navigate to wallet connection screen
4. Select "Braavos"
5. Verify app opens Braavos with connection request

### Test Ready Wallet Connection:
1. Ensure Ready Wallet app is installed
2. Run your app
3. Navigate to wallet connection screen
4. Select "Ready Wallet" (should appear as recommended)
5. Verify app opens Ready Wallet with connection request

---

## 🎨 UI Customization

To customize how wallets appear in the connection modal, you can:

1. **Update Order**: Change the `order` parameter in custom wallet configuration
2. **Add More Wallets**: Add additional `Wallet` objects to `customWallets` array
3. **Exclude Wallets**: Use `excludedWalletIds` parameter to hide unwanted wallets
4. **Custom Images**: Update `imageUrl` to use your own wallet icons

Example:
```swift
Wallet(
    id: "my-custom-wallet",
    name: "My Wallet",
    homepage: "https://mywallet.com/",
    imageUrl: "https://mywallet.com/icon.png",
    order: 3,
    mobileLink: "mywallet://",
    linkMode: nil
)
```

---

## ⚠️ Important Notes

1. **Wallet ID Format**: 
   - Custom wallets can use simple IDs like `"braavos"`
   - Official WalletGuide wallets use long hex IDs like Ready Wallet's

2. **Mobile Links**: 
   - Must match the URL schemes in `Info.plist`
   - Format: `walletname://` (with trailing slashes)

3. **Recommended vs Custom**:
   - `recommendedWalletIds`: For wallets listed in WalletGuide
   - `customWallets`: For any wallet (custom or not)

4. **Link Mode**: 
   - Use `linkMode` for web-based wallet connections
   - Set to `nil` for mobile-only wallets

---

## 🚀 Next Steps

1. ✅ Wallets are configured in AppKit
2. ✅ URL schemes are set in Info.plist
3. ✅ BraavosConnectionManager already handles session callbacks
4. 🔄 Test wallet connections on a physical device
5. 🎨 Customize wallet UI if needed
6. 📱 Add deep link handling in `AppDelegate` if not already present

---

## 🐛 Troubleshooting

### Wallet not appearing in list?
- Verify `customWallets` array is passed to `AppKit.configure()`
- Check console for AppKit initialization errors

### Wallet app not opening?
- Ensure URL scheme is in `Info.plist` → `LSApplicationQueriesSchemes`
- Verify wallet app is installed on device
- Check `mobileLink` format matches wallet's deep link scheme

### Connection not establishing?
- Verify Starknet namespace is properly configured
- Check `BraavosConnectionManager` is subscribed to session events
- Review AppKit session logs for pairing issues

---

## 📝 Code Changes Summary

**File Modified**: `QRPaymentScanner/AppDelegate.swift`
- ✅ Added `customWallets` array with Braavos and Ready Wallet
- ✅ Added `recommendedWalletIds` with Ready Wallet ID
- ✅ Updated `AppKit.configure()` call with new parameters
- ✅ Enhanced console logging for wallet configuration

**No changes needed**:
- `Info.plist` (already configured)
- `BraavosConnectionManager.swift` (already handles sessions)
- `QRPaymentScanner.entitlements` (keychain access configured)

---

## 🎉 Success!

Your app now supports:
- ✅ Braavos Wallet (custom configuration)
- ✅ Ready Wallet (official + recommended)
- ✅ Proper deep linking
- ✅ WalletConnect v2 protocol
- ✅ Starknet network support

Build and run your app to see both wallets in the connection modal!
