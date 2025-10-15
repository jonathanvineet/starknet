# Ready Wallet Connection Debugging

## Issue
Ready Wallet opens but shows "This screen doesn't exist" error when trying to connect via WalletConnect.

## Diagnosis

### Observations:
1. ✅ Pairing URI is created successfully
2. ✅ Wallet app opens correctly
3. ❌ Session proposal not recognized by Ready Wallet
4. ❌ Error: "This screen doesn't exist"

### Possible Causes:

#### 1. **Starknet Namespace Not Supported**
Ready Wallet's iOS app may not support the `starknet:` namespace via WalletConnect v2 yet.

**Evidence:**
- Ready Wallet documentation focuses on web dApps using StarknetKit
- No mention of native iOS WalletConnect support for Starknet
- The error "screen doesn't exist" suggests unrecognized session proposal

**Solution:**
Test with EIP155 (Ethereum) namespace to confirm if issue is Starknet-specific.

#### 2. **Missing dApp Registration**
From Ready Wallet docs:
> "Register your dApp's information on Dappland. This data will be displayed in the app when users connect to your dApp."

**Solution:**
Register on https://dappland.com

#### 3. **Incorrect URL Scheme**
Ready Wallet might expect specific deep link format.

**Current format:**
```
ready-wallet://wc?uri=wc%3A...
```

**Alternative formats to try:**
```
readywallet://wc?uri=wc%3A...
ready://wc?uri=wc%3A...
https://ready.io/wc?uri=wc%3A...
```

#### 4. **In-App Browser Detection**
Ready Wallet has special handling for in-app browser connections. Our app might need to declare itself differently.

## Next Steps

### Option A: Use AppKit Modal (Current Implementation)
```swift
AppKit.present(from: viewController)
```
Let AppKit handle the connection flow automatically.

### Option B: Test with EIP155 Namespace
Temporarily configure with Ethereum namespace to test if Ready Wallet responds:

```swift
let ethNamespace = ProposalNamespace(
    chains: [Blockchain("eip155:1")!],
    methods: Set(["eth_sendTransaction", "personal_sign"]),
    events: Set(["chainChanged", "accountsChanged"])
)
```

### Option C: Contact Ready Wallet Team
- Ask about native iOS WalletConnect support
- Confirm Starknet namespace support
- Get correct deep link format
- Ask about dApp registration requirements

### Option D: Alternative Connection Methods
1. **Check if Ready Wallet has a native iOS SDK**
2. **Use universal links instead of custom schemes**
3. **Implement QR code scanning within app**

## References
- Ready Wallet Docs: https://docs.ready.io
- WalletConnect v2: https://docs.walletconnect.com
- CAIP-25 (Session Proposal): https://github.com/ChainAgnostic/CAIPs/blob/main/CAIPs/caip-25.md
