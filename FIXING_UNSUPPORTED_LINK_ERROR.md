# Fixing "Unsupported Link" Error - Complete Guide

## 🔴 Problem Analysis

You're getting "unsupported link" because:

1. **Manual Deep Linking Issues:**
   - Using `braavos://wc?uri=<encoded_uri>` format
   - Braavos may not recognize this custom format
   - WalletConnect v2 deep linking requires specific formatting

2. **Missing Reown Registration:**
   - Your app needs to be registered on Reown Cloud Dashboard
   - Bundle ID and redirect URLs must be configured
   - Without registration, wallets can't verify your app

3. **Incorrect Integration Method:**
   - Should use AppKit's built-in modal instead of manual deep linking
   - AppKit handles all the complex deep linking logic automatically

---

## ✅ Solution: Three Options

### **Option 1: Use AppKit Modal (RECOMMENDED)**

This is the easiest and most reliable method:

```swift
// In your view or view controller
import ReownAppKit

// Show the built-in WalletConnect modal
AppKit.present(from: viewController)

// OR in SwiftUI
AppKitButton()  // Automatically shows modal when tapped
```

**Pros:**
- Handles QR codes automatically
- Manages deep linking for all wallets
- Works with universal links
- No manual URL construction needed

**Cons:**
- Less control over UI customization

---

### **Option 2: Use AppKit with Custom UI + launchCurrentWallet()**

Keep your custom UI but use AppKit's deep linking:

```swift
func connect() async throws {
    // Create pairing
    let pairingURI = try await AppKit.instance.createPairing()
    
    // Display YOUR custom QR code
    self.connectionURI = pairingURI.absoluteString
    
    // When user taps "Open Braavos"
    // Let AppKit handle the deep linking
    AppKit.instance.launchCurrentWallet()
}
```

**Pros:**
- Custom UI control
- Reliable deep linking via AppKit
- Works with all registered wallets

**Cons:**
- Requires proper Reown registration

---

### **Option 3: Use Starknet Universal Links (Braavos-Specific)**

Based on the `starknet-deeplink` library, use universal links:

```swift
// Instead of: braavos://wc?uri=...
// Use: https://starknet.app.link/wc?uri=...

func openBraavos() {
    guard !connectionURI.isEmpty else { return }
    
    // Use universal link format
    let universalLink = "https://starknet.app.link/wc?uri=\(connectionURI)"
    
    if let url = URL(string: universalLink) {
        UIApplication.shared.open(url) { success in
            print(success ? "✅ Opened Braavos" : "❌ Failed to open")
        }
    }
}
```

**Pros:**
- Works without app URL scheme
- Better iOS support
- Fallback to App Store

**Cons:**
- Requires internet connection
- Slower than direct deep link

---

## 🌐 Reown Cloud Registration (REQUIRED)

### **Step 1: Sign in to Reown Cloud**

1. Go to: https://cloud.reown.com/
2. Sign in with your account
3. Find your project: "573da76e91a5a1c5c6d81566acfd4c31"

### **Step 2: Configure Your App**

In the Reown Dashboard:

1. **Add App Metadata:**
   - Name: "QRPaymentScanner"
   - Description: "Starknet Payment Scanner with Braavos wallet integration"
   - URL: https://qrpaymentscanner.app
   - Icons: Upload your app icon

2. **Register Redirect URLs:**
   - Native: `qrpaymentscanner://`
   - Universal (if you have): `https://qrpaymentscanner.app`

3. **Add Bundle ID:**
   - iOS Bundle ID: `com.vj.QRPaymentScanner`
   - Platform: iOS

4. **Configure Allowed Domains:**
   - Add your app's domain
   - Add callback URLs

### **Step 3: Update Info.plist**

Your app needs to handle the callback:

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
            <string>qrpaymentscanner</string>
        </array>
    </dict>
</array>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>braavos</string>
    <string>wc</string>
</array>
```

---

## 🔧 Recommended Implementation

Here's the updated `BraavosConnectionManager` using AppKit properly:

```swift
import ReownAppKit
import Combine

class BraavosConnectionManager: ObservableObject {
    static let shared = BraavosConnectionManager()
    
    @Published var isConnected = false
    @Published var connectedAddress: String?
    @Published var connectionURI: String = ""
    @Published var showConnectionSheet = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        subscribeToSessionEvents()
    }
    
    // MARK: - Session Monitoring
    
    private func subscribeToSessionEvents() {
        // Listen for successful connections
        AppKit.instance.sessionSettlePublisher
            .sink { [weak self] session in
                self?.handleSessionSettled(session)
            }
            .store(in: &cancellables)
        
        // Listen for disconnections
        AppKit.instance.sessionDeletePublisher
            .sink { [weak self] _ in
                self?.handleDisconnection()
            }
            .store(in: &cancellables)
    }
    
    private func handleSessionSettled(_ session: Session) {
        print("✅ WalletConnect session established!")
        
        // Extract Starknet address from session
        if let starknetAccount = session.namespaces["starknet"]?.accounts.first {
            let address = starknetAccount.address
            
            DispatchQueue.main.async {
                self.isConnected = true
                self.connectedAddress = address
                self.showConnectionSheet = false
                print("🔗 Connected address: \(address)")
            }
        }
    }
    
    private func handleDisconnection() {
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectedAddress = nil
            self.connectionURI = ""
            print("🔌 Wallet disconnected")
        }
    }
    
    // MARK: - Connection Methods
    
    // Method 1: Use AppKit Modal (Easiest)
    func connectWithModal(from viewController: UIViewController) {
        // AppKit handles everything automatically
        AppKit.present(from: viewController)
    }
    
    // Method 2: Custom UI with AppKit Deep Linking
    func connect() async throws {
        print("🦾 Starting Braavos connection...")
        
        do {
            // Create pairing
            let pairingURI = try await AppKit.instance.createPairing()
            
            await MainActor.run {
                self.connectionURI = pairingURI.absoluteString
                self.showConnectionSheet = true
                print("✅ Pairing URI: \(pairingURI.absoluteString)")
            }
            
        } catch {
            print("❌ Connection failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Open wallet using AppKit's method (RECOMMENDED)
    func openBraavos() {
        print("🦾 Opening Braavos wallet...")
        
        // Let AppKit handle the deep linking
        // It knows the correct format for each wallet
        AppKit.instance.launchCurrentWallet()
    }
    
    // Alternative: Manual universal link (if needed)
    func openBraavosManually() {
        guard !connectionURI.isEmpty else {
            print("⚠️ No connection URI")
            return
        }
        
        // Use Starknet universal link format
        let encodedURI = connectionURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let universalLink = "https://starknet.app.link/wc?uri=\(encodedURI)"
        
        if let url = URL(string: universalLink) {
            UIApplication.shared.open(url) { success in
                if !success {
                    self.openAppStore()
                }
            }
        }
    }
    
    private func openAppStore() {
        if let url = URL(string: "https://apps.apple.com/app/braavos-starknet-wallet/id6444612175") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Disconnect
    
    func disconnect() {
        guard let session = AppKit.instance.getSessions().first else { return }
        
        Task {
            try? await AppKit.instance.disconnect(topic: session.topic)
        }
    }
}
```

---

## 📱 SwiftUI View Implementation

```swift
import SwiftUI
import ReownAppKit

struct BraavosConnectView: View {
    @StateObject private var manager = BraavosConnectionManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            if manager.isConnected {
                // Connected State
                VStack {
                    Text("✅ Connected to Braavos")
                        .font(.headline)
                    
                    if let address = manager.connectedAddress {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Button("Disconnect") {
                        manager.disconnect()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            } else {
                // Not Connected - Method 1: Use AppKit Button
                AppKitButton()
                    .frame(height: 50)
                
                Divider()
                
                // OR Method 2: Custom UI
                VStack {
                    Button("Connect with Braavos") {
                        Task {
                            try? await manager.connect()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    if !manager.connectionURI.isEmpty {
                        // Show QR Code
                        QRCodeView(uri: manager.connectionURI)
                            .frame(width: 250, height: 250)
                        
                        // Open Wallet Button
                        Button("Open in Braavos") {
                            manager.openBraavos()  // Uses AppKit's method
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding()
    }
}
```

---

## ✅ Checklist

- [ ] **Register on Reown Cloud Dashboard**
  - Add app metadata
  - Configure redirect URLs
  - Register bundle ID

- [ ] **Update Info.plist**
  - Add URL schemes
  - Add query schemes for wallet detection

- [ ] **Update BraavosConnectionManager**
  - Use `AppKit.instance.launchCurrentWallet()` instead of manual deep linking
  - OR use `AppKit.present()` for built-in modal

- [ ] **Test Connection Flow**
  - Generate QR code
  - Scan with Braavos
  - Verify session establishment

---

## 🐛 Troubleshooting

**"Unsupported link" error:**
- ✅ Use `AppKit.instance.launchCurrentWallet()` instead of manual URL
- ✅ Register app on Reown Cloud Dashboard
- ✅ Use universal links (`https://starknet.app.link/`) not custom scheme (`braavos://`)

**Braavos not opening:**
- Check LSApplicationQueriesSchemes in Info.plist
- Verify Braavos is installed
- Use universal link as fallback

**Session not establishing:**
- Check network connectivity
- Verify Starknet namespace configuration
- Ensure AppKit is properly initialized

---

## 📚 Key Takeaways

1. **Always use AppKit's built-in methods** for deep linking
2. **Register your app** on Reown Cloud Dashboard
3. **Use universal links** (`https://starknet.app.link/`) for better compatibility
4. **Let AppKit handle the complexity** - it knows each wallet's requirements

---

**Next Step:** Choose Option 1 (AppKit Modal) or Option 2 (Custom UI + AppKit deep linking) and update your code accordingly!
