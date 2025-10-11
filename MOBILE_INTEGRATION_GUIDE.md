# Mobile App Integration Testing Guide

This guide helps you test the integration between your Starknet smart contract and iOS mobile application, including the new ChippiPay gasless payment features.

## 🔧 Setup Requirements

### 1. Smart Contract (Already Deployed)
- ✅ Contract Address: `0x029961c5af1520f4a4ad57dccc66370b92ff7a0c47fbf00764e354c17156d7db`
- ✅ Network: Starknet Sepolia
- ✅ STRK Token: `0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d`

### 2. Mobile App Files Updated
- ✅ `StarknetManager.swift` - Smart contract integration
- ✅ `StarknetConnectView.swift` - Wallet connection interface
- ✅ `VaultActionView.swift` - Deposit/Withdraw/Transfer actions
- ✅ `QRPaymentView.swift` - QR code payment processing
- ✅ `HomeView.swift` - Updated with vault integration

## 📱 Testing the Mobile App

### Step 1: Connect Wallet

1. **Open the app** and you'll see the updated HomeView
2. **Tap "Connect"** button next to the profile button
3. **Choose connection method**:
   - **Quick Demo**: Use the pre-filled demo account
   - **Manual Entry**: Enter your wallet credentials

**Demo Account Credentials:**
```
Address: 0x0736bf796e70dad68a103682720dafb090f50065821971b33cbeeb3e3ff5af9f
Private Key: 0x04097f4f606ccf39f9c27c01acc14bb99679de225c86795ae811b46fa96b3390
Public Key: 0xb2eba21301a43862b7b25e1d7e3f5d27ce57a5075c89e6aa490c33dc3e33cb
```

4. **Tap "Connect Wallet"**
5. **Verify connection**: Button should show "Connected" in green

### Step 2: Check Balances

1. **View vault balance** in the main balance card
2. **Tap "Refresh"** to update balances
3. **Verify balances match**:
   - Wallet balance: Your STRK tokens
   - Vault balance: Previously deposited amount (0.5 STRK from testing)

### Step 3: Test Deposit

1. **Tap "Deposit"** button (green plus icon)
2. **Enter amount**: Try 0.1 STRK
3. **Tap "Max"** to use maximum available
4. **Tap "Deposit STRK"**
5. **Wait for processing** (shows loading indicator)
6. **Verify success**: Balance should update automatically

### Step 4: Test Transfer

1. **Tap "Transfer"** button (blue arrow icon)
2. **Enter recipient**: `0x057d0fb86ba9a76d97d00bcd5b61379773070f7451a2ddb4ccb0d04d71586473`
3. **Enter amount**: Try 0.05 STRK
4. **Tap "Transfer STRK"**
5. **Verify transaction**: Check balances refresh

### Step 5: Test Withdraw

1. **Tap "Withdraw"** button (orange minus icon)
2. **Enter amount**: Try 0.1 STRK
3. **Enter address**: Use your wallet address or tap "Use My Address"
4. **Tap "Withdraw STRK"**
5. **Verify**: Check both wallet and vault balances update

### Step 6: Test QR Payment

1. **Tap "QR Pay"** button
2. **Tap "Scan QR Code"** (simulates scanning)
3. **Review payment details**:
   - Recipient: Coffee Shop demo
   - Amount: 0.1 STRK
4. **Tap "Pay with Vault"**
5. **Confirm payment** in dialog
6. **Verify success** message

## 🔍 Troubleshooting

### Connection Issues
- **"Not Connected"**: Check credentials are correct
- **"Network Error"**: Verify RPC endpoint is working
- **"Invalid Address"**: Ensure addresses start with 0x

### Transaction Issues
- **"Insufficient Balance"**: Check you have enough STRK/vault balance
- **"Transaction Failed"**: May be network congestion, try again
- **"Processing..."**: Wait for blockchain confirmation

### Balance Issues
- **"Balance not updating"**: Tap refresh or restart app
- **"Wrong balance"**: Check network connection and RPC status

## 🚀 Real Implementation Notes

The current implementation uses **simulated responses** for demonstration. To make it fully functional:

### 1. Replace Simulation with Real Starkli Calls

In `StarknetManager.swift`, replace these functions:

```swift
// Replace this simulation:
private func simulateStarkliCall(command: String) async -> String {
    // Real implementation:
    return try await executeStarkliCommand(command)
}

// Replace this simulation:
private func simulateStarkliInvoke(command: String) async -> Bool {
    // Real implementation:
    return try await executeStarkliInvokeCommand(command)
}
```

### 2. Add Real Command Execution

```swift
private func executeStarkliCommand(_ command: String) async throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/local/bin/starkli")
    process.arguments = command.components(separatedBy: " ")
    
    let pipe = Pipe()
    process.standardOutput = pipe
    
    try process.run()
    process.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8) ?? ""
}
```

### 3. Add Starknet SDK Integration

Consider using a proper Starknet SDK for iOS instead of shell commands:
- [starknet-rs](https://github.com/xJonathanLEI/starknet-rs) (if Swift bindings available)
- Custom RPC client for JSON-RPC calls
- WebAssembly integration for Cairo/Starknet operations

## 📋 Command Reference

For manual testing via command line (parallel to app testing):

```bash
# Check balances
starkli call $VAULT_CONTRACT_ADDRESS balance_of $ACCOUNT_ADDRESS --network sepolia
starkli call $STRK_TOKEN_ADDRESS balance_of $ACCOUNT_ADDRESS --network sepolia

# Test deposit (requires approval first)
starkli invoke $STRK_TOKEN_ADDRESS approve $VAULT_CONTRACT_ADDRESS u256:100000000000000000 --network sepolia --account ~/.starkli-wallets/deployer/account.json --keystore ~/.starkli-wallets/deployer/keystore.json

starkli invoke $VAULT_CONTRACT_ADDRESS deposit u256:100000000000000000 --network sepolia --account ~/.starkli-wallets/deployer/account.json --keystore ~/.starkli-wallets/deployer/keystore.json

# Test transfer
starkli invoke $VAULT_CONTRACT_ADDRESS transfer_to_user $RECIPIENT_ADDRESS u256:50000000000000000 --network sepolia --account ~/.starkli-wallets/deployer/account.json --keystore ~/.starkli-wallets/deployer/keystore.json
```

### Step 6: Test ChippiPay Integration (NEW! ⚡)

1. **Tap "ChippiPay"** button (orange bolt icon) in the action grid
2. **Create Gasless Wallet**:
   - Tap "Create Gasless Wallet"
   - Follow the 3-step wizard:
     - Step 1: Enter unique user ID
     - Step 2: Set secure password
     - Step 3: Confirm details and create
3. **Browse Services**:
   - View available services (Phone, Utilities, Gift Cards)
   - Notice different categories and pricing
4. **Purchase a Service**:
   - Tap on a service (e.g., "Telcel 50 MXN Top-up")
   - Enter phone number or reference
   - Review cost breakdown:
     - Service cost in MXN
     - STRK equivalent
     - Gas fees: FREE ⚡
   - Tap "Purchase with ChippiPay"
5. **Verify Transaction**:
   - Check transaction confirmation
   - View in Recent Transactions
   - Note gasless execution

**ChippiPay Features to Test:**
- ⚡ **Gasless Transactions**: No gas fees for service purchases
- 🏪 **Real Services**: Phone top-ups, utilities, gift cards
- 🔐 **Self-Custodial**: Encrypted wallet with user password
- 📱 **Seamless UX**: Integrated payment experience

## ✅ Success Criteria

Your mobile app integration is successful when:

### Core Vault Features:
1. ✅ **Connection**: Can connect with Starknet wallet credentials
2. ✅ **Balance Display**: Shows accurate vault and wallet balances
3. ✅ **Deposits**: Can deposit STRK tokens to vault
4. ✅ **Withdrawals**: Can withdraw from vault to wallet
5. ✅ **Transfers**: Can transfer between vault users
6. ✅ **QR Payments**: Can process QR code payments
7. ✅ **Error Handling**: Shows appropriate error messages
8. ✅ **Loading States**: Displays loading indicators during operations

### ChippiPay Gasless Features:
9. ✅ **Gasless Wallet Creation**: Can create encrypted ChippiPay wallet
10. ✅ **Service Discovery**: Displays available payment services
11. ✅ **Service Categories**: Shows different service types (Phone, Utilities, etc.)
12. ✅ **Cost Calculation**: Accurate MXN to STRK conversion
13. ✅ **Gasless Purchases**: Completes payments without gas fees
14. ✅ **Transaction History**: Tracks ChippiPay payment history
15. ✅ **Integration Flow**: Seamless experience between vault and ChippiPay

## 🚀 Production Readiness

For production deployment, you'll need to:

### ChippiPay Configuration:
1. **Get real API keys** from https://dashboard.chipipay.com/
2. **Configure JWKS endpoint** for authentication
3. **Replace mock API calls** with real ChippiPay integration
4. **Deploy vault contract to mainnet** (ChippiPay uses mainnet)
5. **Set up webhook endpoints** for transaction confirmations

### Testing Checklist:
- [ ] Test with real ChippiPay API keys
- [ ] Verify mainnet STRK token integration
- [ ] Test actual service purchases (phone top-ups, etc.)
- [ ] Confirm gasless transaction execution
- [ ] Validate transaction confirmations via webhooks

The app now provides a complete mobile interface for your Starknet vault smart contract with revolutionary gasless payment capabilities through ChippiPay! 🎉⚡