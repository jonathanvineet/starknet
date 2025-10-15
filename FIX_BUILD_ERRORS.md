# Fix Build Errors - Add Missing Files to Xcode

## Problem
The build is failing because two files exist on disk but are NOT added to the Xcode project:
1. `QRPaymentScanner/Helpers/KeychainHelper.swift` ✅ Exists on disk, ❌ Not in Xcode project
2. `QRPaymentScanner/Views/ManualWalletImportView.swift` ✅ Exists on disk, ❌ Not in Xcode project

## Error Message
```
error: value of type 'KeychainHelper' has no member 'saveStarknetPrivateKey'
error: cannot find 'ManualWalletImportView' in scope
```

## Solution - Add Files to Xcode Project

### Step 1: Add KeychainHelper.swift
1. In Xcode, locate the **Helpers** folder in the Project Navigator (left sidebar)
2. **Right-click** on the **Helpers** folder
3. Select **"Add Files to QRPaymentScanner..."**
4. Navigate to: `/Users/vine/elco/starknet/QRPaymentScanner/Helpers/`
5. Select **`KeychainHelper.swift`**
6. Make sure **"QRPaymentScanner" target is checked** (in the bottom section)
7. Click **"Add"**

### Step 2: Add ManualWalletImportView.swift
1. In Xcode, locate the **Views** folder in the Project Navigator
2. **Right-click** on the **Views** folder
3. Select **"Add Files to QRPaymentScanner..."**
4. Navigate to: `/Users/vine/elco/starknet/QRPaymentScanner/Views/`
5. Select **`ManualWalletImportView.swift`**
6. Make sure **"QRPaymentScanner" target is checked**
7. Click **"Add"**

### Step 3: Build
1. Press **Cmd+B** to build
2. All errors should be resolved! ✅

## What These Files Do

### KeychainHelper.swift
- Securely stores Starknet private keys, addresses, and public keys
- Uses iOS Keychain for secure storage
- Methods:
  - `saveStarknetPrivateKey()` - Save private key securely
  - `getStarknetPrivateKey()` - Retrieve private key
  - `saveStarknetAddress()` - Save wallet address
  - `clearAllStarknetKeys()` - Clear all Starknet data

### ManualWalletImportView.swift
- UI for manual wallet import via private key
- QR code scanner integration for scanning private keys
- Instructions for exporting from Ready Wallet / Braavos
- Security warnings
- Keychain integration for secure storage

## Why This Happened
These files were created by the assistant but need to be manually added to the Xcode project file. Xcode maintains a `project.pbxproj` file that tracks all files in the project, and GUI action is required to add new files.

## After Adding
Once both files are added, the build should succeed and you'll have:
- ✅ Working WalletConnect buttons (for Argent X and future support)
- ✅ Working Manual Import button with QR scanner
- ✅ Secure keychain storage for private keys
- ✅ Complete wallet connection solution!
