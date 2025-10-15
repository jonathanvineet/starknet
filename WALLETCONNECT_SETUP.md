# 🔗 WalletConnect v2 Integration for Braavos

## ✅ **SETUP COMPLETE - What's Been Added**

### 📦 **New Files Created**

1. **`BraavosConnectionManager.swift`** - WalletConnect v2 manager
   - Handles WalletConnect pairing and session management
   - Connects to Braavos wallet via proper protocol
   - Project ID: `573da76e91a5a1c5c6d81566acfd4c31`

2. **`BraavosConnectView.swift`** - Connection UI
   - Shows QR code for scanning with Braavos app
   - Deep link button to open Braavos directly
   - Connection status display

### 🔧 **Required: Install Reown (WalletConnect) Package**

WalletConnect Inc is now Reown. The legacy `WalletConnectSwiftV2` is deprecated. Use the Reown Swift package going forward.

#### **Step 1: Add Reown Package Dependency in Xcode**

1. Open your project in Xcode
2. Go to **File** → **Add Package Dependencies...**
3. Enter this URL:
   ```
   https://github.com/reown-com/reown-swift
   ```
4. Click **Add Package**
5. Select these products to add (names appear under the Reown org):
   - ✅ **WalletConnectSign**
   - ✅ **WalletConnectPairing** (auto-selected)
   - ✅ **WalletConnectNetworking** (auto-selected)
6. Click **Add Package**

> Note: Reown maintains compatibility layers. The existing imports `import WalletConnectSign`
> and calls like `Pair.configure(...)` / `Sign.instance...` used in this app continue to work when sourced from the Reown package.

#### **Step 2: Verify Installation**

After adding the package, build your project:
- Press **Cmd+B** to build
- Verify no "Cannot find type 'WalletConnectSign'" errors

---

## 🎯 **How It Works**

### **Connection Flow (Reown)**

```
User taps "Connect to Braavos"
    ↓
WalletConnect creates pairing URI
    ↓
App shows QR code + "Open Braavos" button
    ↓
User scans QR OR taps button
    ↓
Braavos opens with deep link: braavos://wc?uri=[URI]
    ↓
User approves in Braavos app
    ↓
Session established
    ↓
App receives wallet address
    ↓
Automatically loads STRK balance
```

### **Deep Link Format**

```swift
// ✅ CORRECT (WalletConnect URI):
braavos://wc?uri=wc%3A...

// ❌ WRONG (Custom scheme - doesn't work):
braavos://starknet/connect?callback=...
```

---

## 📱 **Testing Instructions**

### **Option 1: Scan QR Code**
1. Tap "Connect to Braavos (WalletConnect)"
2. Sheet appears with QR code
3. Open Braavos app on another device
4. Scan the QR code
5. Approve connection
6. Watch console for success logs

### **Option 2: Deep Link (Same Device)**
1. Tap "Connect to Braavos (WalletConnect)"
2. Sheet appears
3. Tap "Open Braavos" button
4. Braavos app opens
5. Approve connection
6. App returns automatically
7. Balance loads

---

## 🔍 **Debug Logs to Watch**

Console output will show:

```
🔗 Starting WalletConnect connection...
📱 Connection URI created: wc:...
✅ Session proposal sent
🦁 Opening Braavos with WalletConnect URI...
📝 Received session proposal from wallet
✅ Session proposal approved
✅ Session settled successfully!
📍 Received address: 0x...
👀 ========== READ-ONLY WALLET CONNECTION ==========
✅ Read-only wallet connected, loading balances...
💰 Final STRK balance: X.XXXX
```

---

## ⚠️ **Important Notes**

### **Read-Only Mode**
- Braavos connection is **read-only**
- Can view balance ✅
- Cannot sign transactions ❌
- Transactions must be signed in Braavos app itself

### **Transaction Signing (Future)**
To sign transactions, you'll need to:
1. Call `BraavosConnectionManager.shared.signTransaction(calls: [...])`
2. Braavos app opens for approval
3. User approves in Braavos
4. Returns with signature

### **Network**
Currently set to **Starknet Sepolia testnet**. Change in:
```swift
Blockchain("starknet:SN_SEPOLIA")!  // Testnet
Blockchain("starknet:SN_MAIN")!     // Mainnet
```

---

## 🆚 **Connection Methods Comparison**

| Method | Access Level | Can View Balance | Can Sign TX | Use Case |
|--------|--------------|------------------|-------------|----------|
| **3-QR Scan (Ready)** | Full | ✅ | ✅ | Development/Testing |
| **Braavos WalletConnect** | Read-Only | ✅ | Via Braavos App | Production Users |
| **Demo Account** | Full | ✅ | ✅ | Quick Testing |

---

## 🐛 **Troubleshooting**

### Build Error: "Cannot find type 'WalletConnectSign'"
**Solution:** Install the Reown package (see Step 1 above) and ensure the selected products include `WalletConnectSign`.

### Error: "Braavos not installed"
**Solution:** Install Braavos from App Store:
https://apps.apple.com/app/braavos-starknet-wallet/id6444612175

### Error: "Session proposal timeout"
**Solution:** 
- Check internet connection
- Verify Project ID is correct
- Try generating new pairing URI

### Connection shows QR but nothing happens
**Solution:**
- Make sure Braavos app is updated
- Try "Open Braavos" button instead
- Check console for error messages

---

## 📚 **Additional Resources**

- **Reown Deprecations:** https://docs.reown.com/advanced/walletconnect-deprecations
- **iOS Upgrade Guide:** https://docs.reown.com/walletkit/upgrade/from-web3wallet-ios
- **WalletConnect (legacy) Docs:** https://docs.walletconnect.com/
- **Braavos Wallet:** https://braavos.app/
- **Project Dashboard:** https://cloud.walletconnect.com/

---

## ✨ **Next Steps**

1. **Install WalletConnect package** (Required!)
2. **Build project** (Cmd+B)
3. **Test connection** with Braavos app
4. **Watch console logs** for debugging
5. **Verify balance displays** correctly

Your app now supports **professional wallet integration** using industry-standard WalletConnect v2 protocol! 🎉
