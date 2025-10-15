# Quick Start Guide: Using Braavos & Ready Wallet

## 🚀 Your wallets are now configured!

### What's Been Done

✅ **AppKit Configuration** (AppDelegate.swift)
- Added Braavos as a custom wallet
- Added Ready Wallet with official ID
- Set Ready Wallet as recommended

✅ **Deep Link Handling** (AppDelegate.swift & SceneDelegate.swift)
- Added `AppKit.instance.handleDeeplink(url)` to handle WalletConnect callbacks
- Preserved existing Ready Wallet callback handling

✅ **URL Schemes** (Info.plist)
- Already configured with `braavos://` and `readywallet://`

---

## 📱 How to Use in Your App

### Option 1: Use Existing BraavosConnectionManager

Your `BraavosConnectionManager` already handles connections:

```swift
import SwiftUI

struct MyWalletView: View {
    @ObservedObject var braavos = BraavosConnectionManager.shared
    
    var body: some View {
        VStack {
            if braavos.isConnected {
                Text("Connected: \(braavos.userAddress)")
                Button("Disconnect") {
                    braavos.disconnect()
                }
            } else {
                Button("Connect Braavos") {
                    Task {
                        await braavos.connect()
                    }
                }
            }
        }
    }
}
```

### Option 2: Use AppKit's Built-in Modal (Recommended)

AppKit provides a ready-to-use wallet selection modal:

```swift
import SwiftUI
import ReownAppKit

struct ConnectWalletView: View {
    @State private var showWalletModal = false
    
    var body: some View {
        VStack {
            Button("Connect Wallet") {
                showWalletModal = true
            }
        }
        .sheet(isPresented: $showWalletModal) {
            // AppKit will show a list with:
            // 1. Ready Wallet (⭐ Recommended)
            // 2. Braavos
            // 3. Any other installed wallets
            AppKitModalView()
        }
    }
}

// Create AppKit's modal view
struct AppKitModalView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        // AppKit provides its own modal UI
        let controller = AppKit.instance.createWalletModal()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
}
```

### Option 3: Direct Wallet Launch

Launch a specific wallet directly:

```swift
// Launch Ready Wallet
AppKit.instance.connectWallet(walletId: "bc949c5d968ae81310268bf9193f9c9fb7bb4e1283e1284af8f2bd4992535fd6")

// Launch Braavos
AppKit.instance.connectWallet(walletId: "braavos")

// Or use launchCurrentWallet after creating a pairing
Task {
    let pairingURI = try await AppKit.instance.createPairing()
    AppKit.instance.launchCurrentWallet()
}
```

---

## 🔍 Wallet Information

### Braavos Wallet
- **ID**: `braavos`
- **Scheme**: `braavos://`
- **Order**: 1 (appears first)
- **Type**: Custom wallet
- **Homepage**: https://braavos.app/

### Ready Wallet
- **ID**: `bc949c5d968ae81310268bf9193f9c9fb7bb4e1283e1284af8f2bd4992535fd6`
- **Scheme**: `readywallet://`
- **Order**: 2 (appears second)
- **Type**: Official + Recommended
- **Homepage**: https://readywallet.app/

---

## 🧪 Testing Checklist

### Before Testing:
- [ ] Install Braavos wallet app on your iOS device
- [ ] Install Ready Wallet app on your iOS device
- [ ] Build and run your app on a physical device (not simulator)

### Test Braavos:
1. [ ] Open your app
2. [ ] Tap "Connect Wallet" or similar button
3. [ ] Select "Braavos" from the wallet list
4. [ ] Verify Braavos app opens
5. [ ] Approve connection in Braavos
6. [ ] Verify app receives wallet address
7. [ ] Check `BraavosConnectionManager.isConnected == true`

### Test Ready Wallet:
1. [ ] Open your app  
2. [ ] Tap "Connect Wallet" or similar button
3. [ ] Verify "Ready Wallet" shows as recommended (⭐)
4. [ ] Select "Ready Wallet" from list
5. [ ] Verify Ready Wallet app opens
6. [ ] Approve connection in Ready Wallet
7. [ ] Verify app receives wallet address

---

## 🎯 Integration Points

### Where BraavosConnectionManager is Already Used:

1. **BraavosConnectView.swift** - UI for Braavos connection
2. **StarknetConnectView.swift** - Shows connection options
3. **BraavosConnectionManager.swift** - Handles session management

### Existing Session Handling:

The `BraavosConnectionManager` already subscribes to AppKit events:

```swift
// Listens for new sessions
AppKit.instance.sessionSettlePublisher
    .receive(on: DispatchQueue.main)
    .sink { [weak self] session in
        self?.handleSessionSettled(session)
    }
    .store(in: &cancellables)

// Listens for disconnections
AppKit.instance.sessionDeletePublisher
    .receive(on: DispatchQueue.main)
    .sink { [weak self] (topic, reason) in
        self?.handleDisconnection()
    }
    .store(in: &cancellables)
```

This means **connection callbacks are automatically handled** by your existing manager!

---

## 📊 Session Flow

```
User taps "Connect Braavos"
    ↓
BraavosConnectionManager.connect()
    ↓
AppKit.instance.createPairing()
    ↓
AppKit.instance.launchCurrentWallet()
    ↓
Braavos app opens with WC URI
    ↓
User approves in Braavos
    ↓
Braavos sends session back
    ↓
AppKit receives session
    ↓
sessionSettlePublisher emits
    ↓
BraavosConnectionManager.handleSessionSettled()
    ↓
isConnected = true
    ↓
userAddress = "0x..."
```

---

## 🔧 Advanced Configuration

### Add More Wallets

Edit `AppDelegate.swift` → `configureReownAppKit()`:

```swift
let customWallets = [
    // Existing wallets...
    
    // Add new wallet
    Wallet(
        id: "mynewwallet",
        name: "My New Wallet",
        homepage: "https://mynewwallet.com/",
        imageUrl: "https://mynewwallet.com/icon.png",
        order: 3,
        mobileLink: "mynewwallet://",
        linkMode: nil
    )
]
```

### Exclude Unwanted Wallets

```swift
AppKit.configure(
    // ... other params
    excludedWalletIds: ["wallet-id-to-hide"]
)
```

### Change Wallet Order

Modify the `order` parameter in custom wallets:
- Lower numbers appear first
- Order 1 = top of list
- Order 999 = bottom of list

---

## 🐛 Troubleshooting

### "Wallet not appearing in list"
- Check AppKit configuration in AppDelegate
- Verify console for initialization errors
- Ensure `customWallets` array is passed to `AppKit.configure()`

### "Wallet app not opening"
- Ensure wallet is installed on device
- Check `Info.plist` has correct URL scheme in `LSApplicationQueriesSchemes`
- Verify scheme matches `mobileLink` parameter

### "Connection not establishing"
- Check console logs for pairing errors
- Verify Starknet namespace is configured
- Ensure `BraavosConnectionManager` is initialized
- Check that `handleDeeplink()` is called in AppDelegate/SceneDelegate

### "Session lost after app restart"
- AppKit handles session persistence automatically
- Check that you're not creating multiple AppKit instances
- Verify keychain entitlements are configured

---

## 📚 Further Reading

- [Reown AppKit Documentation](https://docs.reown.com/appkit/ios/core/options)
- [WalletConnect Protocol](https://walletconnect.org/)
- [Braavos Documentation](https://docs.braavos.app/)
- [WalletGuide Explorer](https://walletguide.walletconnect.network/)

---

## ✅ You're All Set!

Your app now supports:
- 🦁 Braavos Wallet (custom)
- 🎯 Ready Wallet (official + recommended)
- 🔗 WalletConnect v2 protocol
- 🌐 Starknet mainnet & Sepolia
- 🔐 Secure session management

Build and test on a real device to see it in action!
