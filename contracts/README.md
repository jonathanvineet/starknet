# User Vault Smart Contract# User Vault Smart Contract



A secure STRK token vault contract deployed on Starknet Sepolia testnet with deposit, withdraw, and payment gateway integration features.A secure vault contract for STRK tokens on Starknet Sepolia testnet with deposit, withdrawal, and transfer functionality.



## 📋 Contract Information## Features



- **Contract Address**: `0x029961c5af1520f4a4ad57dccc66370b92ff7a0c47fbf00764e354c17156d7db`- **Secure Token Storage**: Users can deposit STRK tokens into individual vaults

- **Class Hash**: `0x06c8af74006d49d03e45216630e34dc893f0ea8a255730d88b3ded3191d31263`- **Owner-Only Access**: Only vault owners can withdraw or transfer their tokens

- **Network**: Starknet Sepolia Testnet- **Signature Verification**: Support for off-chain signature authorization

- **STRK Token**: `0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d`- **Event Emission**: Comprehensive event logging for all operations

- **Owner**: `0x0736bf796e70dad68a103682720dafb090f50065821971b33cbeeb3e3ff5af9f`- **Emergency Controls**: Pause functionality for security

- **Payment Gateway Ready**: Compatible with payment systems like ChippiPay

## 🚀 Quick Start

## Project Structure

### Prerequisites

```

1. Install [Starkli](https://book.starkli.rs/installation):contracts/

   ```bash├── src/

   curl https://get.starkli.sh | sh│   ├── lib.cairo          # Main module declaration

   source ~/.starkli/env│   └── user_vault.cairo   # Complete vault contract implementation

   starkliup├── scripts/

   ```│   ├── deploy.sh          # Bash deployment script

│   └── deploy.js          # JavaScript deployment script

2. Set up environment variables:├── Scarb.toml            # Cairo package configuration

   ```bash├── python_integration.py # Python SDK integration examples

   cp .env.example .env├── js_integration.js     # JavaScript SDK integration examples

   # Edit .env with your account details├── requirements.txt      # Python dependencies

   ```├── .env.example         # Environment variables template

└── DEPLOYMENT_GUIDE.md  # Detailed deployment instructions

### Environment Setup```



Create a `.env` file with your credentials:## Quick Start



```bash### 1. Setup Environment

# Starknet Sepolia configuration

STARKNET_RPC_URL="https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_6/YOUR_API_KEY"```bash

# Copy environment template

# Your account detailscp .env.example .env

STARKNET_ACCOUNT_ADDRESS="YOUR_ACCOUNT_ADDRESS"

STARKNET_PRIVATE_KEY="YOUR_PRIVATE_KEY"# Edit .env with your Starknet account details

STARKNET_PUBLIC_KEY="YOUR_PUBLIC_KEY"# STARKNET_ACCOUNT_ADDRESS, STARKNET_PRIVATE_KEY, etc.

```

# Contract details

STRK_TOKEN_ADDRESS="0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d"### 2. Build Contract

VAULT_CONTRACT_ADDRESS="0x029961c5af1520f4a4ad57dccc66370b92ff7a0c47fbf00764e354c17156d7db"

``````bash

cd contracts

## 🔧 Developmentscarb build

```

### Build Contract

### 3. Deploy Contract

```bash

# Clean and buildUsing bash script:

scarb clean && scarb build```bash

```./scripts/deploy.sh

```

### Deploy New Contract (if needed)

Using JavaScript:

```bash```bash

# Source environment variablesnode scripts/deploy.js

source .env```



# 1. Declare the contract class### 4. Test Integration

starkli declare target/dev/user_vault_user_vault.contract_class.json \

    --network sepolia \Python:

    --account ~/.starkli-wallets/deployer/account.json \```bash

    --keystore ~/.starkli-wallets/deployer/keystore.jsonpip install -r requirements.txt

python python_integration.py

# 2. Deploy with constructor arguments```

starkli deploy CLASS_HASH $STRK_TOKEN_ADDRESS $STARKNET_ACCOUNT_ADDRESS \

    --network sepolia \JavaScript:

    --account ~/.starkli-wallets/deployer/account.json \```bash

    --keystore ~/.starkli-wallets/deployer/keystore.jsonnpm install starknet dotenv

node js_integration.js

# 3. Set public key (initialize)```

starkli invoke $VAULT_CONTRACT_ADDRESS set_public_key $STARKNET_PUBLIC_KEY \

    --network sepolia \## Contract Functions

    --account ~/.starkli-wallets/deployer/account.json \

    --keystore ~/.starkli-wallets/deployer/keystore.json### Core Operations

```- `deposit(amount)` - Deposit STRK tokens into vault

- `withdraw(to, amount)` - Withdraw tokens to specified address

## 💰 Using the Vault- `transfer_to_user(to_user, amount)` - Transfer between vault users

- `balance_of(user)` - Query user's vault balance

### Check Balances

### Authentication

```bash- `set_public_key(pubkey)` - Set public key for signature verification

source .env- `withdraw_with_signature(...)` - Withdraw with off-chain authorization



# Check STRK balance### Administrative

starkli call $STRK_TOKEN_ADDRESS balance_of $STARKNET_ACCOUNT_ADDRESS --network sepolia- `emergency_pause()` - Pause contract (owner only)

- `emergency_unpause()` - Unpause contract (owner only)

# Check vault balance

starkli call $VAULT_CONTRACT_ADDRESS balance_of $STARKNET_ACCOUNT_ADDRESS --network sepolia## Integration Examples



# Check total depositedSee the integration files for complete examples:

starkli call $VAULT_CONTRACT_ADDRESS get_total_deposited --network sepolia- `python_integration.py` - Python SDK usage

- `js_integration.js` - JavaScript SDK usage

# Check contract owner- `DEPLOYMENT_GUIDE.md` - Detailed deployment guide

starkli call $VAULT_CONTRACT_ADDRESS get_contract_owner --network sepolia

```## Security Features



### Deposit Tokens- **Owner Authorization**: Only vault owners can access their funds

- **Nonce-based Replay Protection**: Prevents transaction replay attacks

```bash- **Signature Verification**: Support for off-chain authorization

source .env- **Emergency Pause**: Contract can be paused for security

- **Event Logging**: All operations emit events for monitoring

# 1. Approve vault contract to spend STRK tokens (1 STRK = 1000000000000000000 wei)

starkli invoke $STRK_TOKEN_ADDRESS approve $VAULT_CONTRACT_ADDRESS u256:1000000000000000000 \## Contract Addresses

    --network sepolia \

    --account ~/.starkli-wallets/deployer/account.json \After deployment, your contract addresses will be:

    --keystore ~/.starkli-wallets/deployer/keystore.json- **Sepolia Testnet**: Set in `.env` as `VAULT_CONTRACT_ADDRESS`

- **STRK Token**: `0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d`

# 2. Check allowance

starkli call $STRK_TOKEN_ADDRESS allowance $STARKNET_ACCOUNT_ADDRESS $VAULT_CONTRACT_ADDRESS --network sepolia## Support



# 3. Deposit tokens (0.5 STRK = 500000000000000000 wei)For deployment issues or integration help:

starkli invoke $VAULT_CONTRACT_ADDRESS deposit u256:500000000000000000 \1. Check the `DEPLOYMENT_GUIDE.md` for detailed instructions

    --network sepolia \2. Review the integration examples

    --account ~/.starkli-wallets/deployer/account.json \3. Ensure all environment variables are set correctly

    --keystore ~/.starkli-wallets/deployer/keystore.json4. Verify you have sufficient STRK tokens and ETH for gas
```

### Withdraw Tokens

```bash
source .env

# Withdraw tokens to your address (0.5 STRK = 500000000000000000 wei)
starkli invoke $VAULT_CONTRACT_ADDRESS withdraw $STARKNET_ACCOUNT_ADDRESS u256:500000000000000000 \
    --network sepolia \
    --account ~/.starkli-wallets/deployer/account.json \
    --keystore ~/.starkli-wallets/deployer/keystore.json
```

### Transfer Between Users

```bash
source .env

# Transfer tokens from your vault to another user (0.1 STRK = 100000000000000000 wei)
starkli invoke $VAULT_CONTRACT_ADDRESS transfer_to_user $RECIPIENT_ADDRESS u256:100000000000000000 \
    --network sepolia \
    --account ~/.starkli-wallets/deployer/account.json \
    --keystore ~/.starkli-wallets/deployer/keystore.json
```

## 🔑 Account Management

### Create New Account (if needed)

```bash
# Create keystore
starkli signer keystore new ~/.starkli-wallets/deployer/keystore.json

# Create account file
starkli account oz init ~/.starkli-wallets/deployer/account.json --keystore ~/.starkli-wallets/deployer/keystore.json

# Fund the account with ETH for deployment fees, then deploy
starkli account deploy ~/.starkli-wallets/deployer/account.json \
    --network sepolia \
    --keystore ~/.starkli-wallets/deployer/keystore.json
```

### Use Existing Account

```bash
# Fetch existing account from network
starkli account fetch YOUR_ACCOUNT_ADDRESS \
    --output ~/.starkli-wallets/deployer/account.json \
    --network sepolia
```

## 📊 Contract Functions

### Read Functions (View)
- `get_contract_owner()` - Get contract owner address
- `balance_of(user)` - Get user's vault balance
- `get_total_deposited()` - Get total deposited amount
- `get_strk_token_address()` - Get STRK token contract address
- `get_nonce(user)` - Get user's nonce for signatures
- `get_public_key(user)` - Get user's stored public key
- `is_paused()` - Check if contract is paused

### Write Functions (Invoke)
- `deposit(amount)` - Deposit STRK tokens
- `withdraw(to, amount)` - Withdraw tokens to address
- `transfer_to_user(to, amount)` - Transfer between vault users
- `set_public_key(pubkey)` - Set user's public key
- `pause()` - Pause contract (admin only)
- `unpause()` - Unpause contract (admin only)

## 🔗 Integration Examples

### Payment Gateway Integration
```bash
# Check if user has sufficient balance for payment
starkli call $VAULT_CONTRACT_ADDRESS balance_of $USER_ADDRESS --network sepolia

# Process payment by transferring from user's vault to merchant
starkli invoke $VAULT_CONTRACT_ADDRESS transfer_to_user $MERCHANT_ADDRESS u256:$AMOUNT \
    --network sepolia \
    --account $USER_ACCOUNT \
    --keystore $USER_KEYSTORE
```

### QR Code Payment Flow
1. Generate QR code with payment details
2. User scans QR code
3. Check user's vault balance
4. Execute transfer if sufficient funds
5. Confirm transaction on blockchain

## 🛡️ Security Features

- **Pausable**: Contract can be paused in emergencies
- **Access Control**: Owner-only administrative functions
- **Signature Verification**: Secure transaction signing
- **Input Validation**: All inputs are validated
- **Reentrancy Protection**: Safe external calls

## 📝 Common Token Amounts

| Amount | Wei Value | Hex Value |
|--------|-----------|-----------|
| 0.1 STRK | 100000000000000000 | 0x16345785d8a0000 |
| 0.5 STRK | 500000000000000000 | 0x6f05b59d3b20000 |
| 1 STRK | 1000000000000000000 | 0xde0b6b3a7640000 |
| 10 STRK | 10000000000000000000 | 0x8ac7230489e80000 |

## 🔍 Useful Commands

```bash
# Check contract deployment status
starkli class-hash-at $VAULT_CONTRACT_ADDRESS --network sepolia

# Get transaction receipt
starkli receipt TRANSACTION_HASH --network sepolia

# Check account nonce
starkli nonce $STARKNET_ACCOUNT_ADDRESS --network sepolia

# Get block number
starkli block-number --network sepolia
```

## 📋 File Structure

```
contracts/
├── README.md              # This file
├── .env                   # Environment variables (not in git)
├── .env.example          # Environment template
├── Scarb.toml            # Project configuration
├── Scarb.lock            # Dependencies lock file
├── src/
│   ├── lib.cairo         # Library exports
│   └── user_vault.cairo  # Main contract
└── target/               # Compiled artifacts
    └── dev/
        ├── user_vault_user_vault.contract_class.json
        └── user_vault_user_vault.compiled_contract_class.json
```

## 🆘 Troubleshooting

### Common Issues

1. **"ContractNotFound" error**: Check if account address is correct and account is deployed
2. **"InsufficientBalance" error**: Fund your account with STRK tokens
3. **"InsufficientAllowance" error**: Approve the contract to spend your tokens first
4. **RPC compatibility issues**: Use the correct RPC version (v0.6 for starkli 0.4.2)

### Getting Help

- [Starkli Documentation](https://book.starkli.rs/)
- [Starknet Documentation](https://docs.starknet.io/)
- [Cairo Book](https://book.cairo-lang.org/)

## 📄 License

MIT License - see LICENSE file for details.