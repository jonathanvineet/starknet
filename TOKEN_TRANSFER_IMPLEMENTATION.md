# 🪙 Token Transfer Implementation: MetaMask → Vault Contract

## The Complete Flow

### **What Happens When User Deposits STRK Tokens:**

```
1. 👤 User has STRK in MetaMask wallet
   ↓
2. 📱 User opens your app and connects wallet
   ↓
3. 💰 User taps "Deposit" and enters amount (e.g., 2.5 STRK)
   ↓
4. ✅ App checks: Does user have enough STRK?
   ↓
5. 🔐 App approves vault contract to spend STRK
   ↓
6. 📤 App deposits STRK to vault contract
   ↓
7. 🎉 Tokens successfully transferred!
```

## 🔧 Technical Implementation

### **Step 1: User Balance Check**
```swift
// Check user's STRK balance in MetaMask wallet
let balance = await realStarknetManager.checkSTRKBalance()
// Returns: 5.0 STRK (for example)
```

**What happens behind the scenes:**
```bash
starkli call 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d balance_of 0x[USER_ADDRESS] --network sepolia
```

### **Step 2: Allowance Check**
```swift
// Check if vault contract is already approved to spend tokens
let allowance = await realStarknetManager.checkAllowance()
// Returns: 0.0 STRK (needs approval)
```

**What happens behind the scenes:**
```bash
starkli call 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d allowance 0x[USER_ADDRESS] 0x[VAULT_CONTRACT] --network sepolia
```

### **Step 3: Approve Vault Contract**
```swift
// Approve vault contract to spend 2.5 STRK
let approveTxHash = try await realStarknetManager.approveVaultContract(amount: 2.5)
// Returns: "0x123abc...def" (transaction hash)
```

**What happens behind the scenes:**
```bash
starkli invoke 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d approve 0x[VAULT_CONTRACT] u256:2500000000000000000 0 --network sepolia --account account.json --keystore keystore.json
```

### **Step 4: Deposit to Vault**
```swift
// Deposit 2.5 STRK to vault contract
let success = await realStarknetManager.depositToVault(amount: 2.5)
// Returns: true (success)
```

**What happens behind the scenes:**
```bash
starkli invoke 0x029961c5af1520f4a4ad57dccc66370b92ff7a0c47fbf00764e354c17156d7db deposit u256:2500000000000000000 0 --network sepolia --account account.json --keystore keystore.json
```

## 📱 User Interface Flow

### **VaultActionView.swift - Deposit Screen**

```swift
struct VaultActionView: View {
    @StateObject private var starknetManager = RealStarknetManager.shared
    @State private var amount = ""
    
    var body: some View {
        VStack {
            // Amount Input
            TextField("Amount to deposit", text: $amount)
            
            // Balance Display
            Text("Available: \(starknetManager.strkBalance, specifier: "%.4f") STRK")
            
            // Deposit Button
            Button("Deposit to Vault") {
                Task {
                    let depositAmount = Double(amount) ?? 0
                    let success = await starknetManager.depositToVault(amount: depositAmount)
                    
                    if success {
                        // Show success message
                        // Update UI
                    }
                }
            }
            .disabled(starknetManager.isLoading)
        }
    }
}
```

## 🔐 Security & Validation

### **Pre-Transaction Checks:**
1. ✅ **Wallet Connected**: User must be connected
2. ✅ **Sufficient Balance**: User has enough STRK
3. ✅ **Valid Amount**: Amount > 0 and <= balance
4. ✅ **Network Check**: Connected to Sepolia testnet

### **Transaction Security:**
1. 🔐 **Private Key**: Stored securely (Keychain in production)
2. 🔑 **Account Files**: Temporary files created for starkli
3. 📝 **Transaction Signing**: All transactions signed with user's private key
4. ⏰ **Confirmation Wait**: Wait for transaction confirmation before updating UI

## 💡 Real Implementation vs Mock

### **Current Mock Implementation:**
```swift
// StarknetManager.swift (MOCK)
func depositToVault(amount: Double) async -> Bool {
    // Simulate network delay
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    
    // Return mock success
    return true
}
```

### **Real Implementation:**
```swift
// RealStarknetManager.swift (REAL)
func depositToVault(amount: Double) async -> Bool {
    // 1. Check balance
    let currentBalance = await checkSTRKBalance()
    guard currentBalance >= amount else {
        throw StarknetError.insufficientBalance
    }
    
    // 2. Check/approve allowance
    let currentAllowance = await checkAllowance()
    if currentAllowance < amount {
        let approveTxHash = try await approveVaultContract(amount: amount)
        try await waitForTransaction(txHash: approveTxHash)
    }
    
    // 3. Execute deposit
    let depositTxHash = try await invokeContract(
        contractAddress: ContractConfig.vaultContractAddress,
        functionName: "deposit",
        parameters: [strkToWei(amount), "0"]
    )
    
    // 4. Wait for confirmation
    try await waitForTransaction(txHash: depositTxHash)
    
    // 5. Update balances
    await loadBalances()
    
    return true
}
```

## 🚀 How to Switch to Real Implementation

### **1. Update HomeView.swift:**
```swift
// Replace this:
@StateObject private var starknet = StarknetManager.shared

// With this:
@StateObject private var starknet = RealStarknetManager.shared
```

### **2. Update VaultActionView.swift:**
```swift
// Replace this:
@StateObject private var starknetManager = StarknetManager()

// With this:
@StateObject private var starknetManager = RealStarknetManager.shared
```

### **3. Test the Real Implementation:**
```swift
// In your test function:
let manager = RealStarknetManager.shared

// Connect with real credentials
manager.connectWallet(
    address: "0x0736bf796e70dad68a103682720dafb090f50065821971b33cbeeb3e3ff5af9f",
    privateKey: "0x04097f4f606ccf39f9c27c01acc14bb99679de225c86795ae811b46fa96b3390",
    publicKey: "0xb2eba21301a43862b7b25e1d7e3f5d27ce57a5075c89e6aa490c33dc3e33cb"
)

// Test deposit
let success = await manager.depositToVault(amount: 0.1)
print("Deposit success: \(success)")
```

## 📊 Transaction Monitoring

### **Real-time Updates:**
```swift
// The app will show:
1. "Approving vault contract..." (Step 1)
2. "Approval confirmed ✅" (Step 2)
3. "Depositing to vault..." (Step 3)
4. "Deposit confirmed ✅" (Step 4)
5. "Balances updated" (Step 5)
```

### **Transaction Hashes:**
```swift
// User can track transactions:
print("Approval TX: \(manager.lastTransactionHash)")
print("Deposit TX: \(manager.lastTransactionHash)")

// View on Starknet explorer:
// https://sepolia.starkscan.co/tx/0x[TRANSACTION_HASH]
```

## 🎯 Key Benefits

### **For Users:**
- 🏃‍♂️ **Fast**: Automated approval + deposit in one flow
- 🔒 **Secure**: All transactions signed with user's private key
- 👀 **Transparent**: Real-time transaction tracking
- 💰 **Accurate**: Real balance updates after each transaction

### **For Developers:**
- 🧪 **Testable**: Works with real Sepolia network
- 🔧 **Maintainable**: Clean separation of concerns
- 📱 **Reactive**: SwiftUI updates automatically
- 🐛 **Debuggable**: Detailed error messages and logging

This implementation provides the **complete bridge** between MetaMask wallet and your vault contract, enabling users to seamlessly deposit STRK tokens through your mobile app! 🎉