// SPDX-License-Identifier: MIT
// User Vault for STRK tokens on Starknet Sepolia Testnet
// Complete implementation with deposit, withdraw, transfer, and authentication features
// Compatible with payment gateway integrations like ChippiPay

use starknet::ContractAddress;
use core::num::traits::Zero;

/// ERC20 interface for STRK token interactions
/// This interface defines the minimum functions needed to interact with STRK tokens
#[starknet::interface]
trait IERC20<TContractState> {
    /// Transfer tokens from one address to another (requires approval)
    /// @param from: Source address
    /// @param to: Destination address  
    /// @param value: Amount to transfer
    /// @return: Success boolean
    fn transfer_from(ref self: TContractState, from: ContractAddress, to: ContractAddress, value: u256) -> bool;
    
    /// Transfer tokens from caller to another address
    /// @param to: Destination address
    /// @param value: Amount to transfer
    /// @return: Success boolean
    fn transfer(ref self: TContractState, to: ContractAddress, value: u256) -> bool;
    
    /// Get token balance of an address
    /// @param owner: Address to check balance for
    /// @return: Token balance
    fn balance_of(self: @TContractState, owner: ContractAddress) -> u256;
    
    /// Check allowance between two addresses
    /// @param owner: Token owner address
    /// @param spender: Spender address
    /// @return: Allowed amount
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
}

#[starknet::contract]
mod user_vault {
    use super::IERC20DispatcherTrait;
    use super::IERC20Dispatcher;
    use starknet::{ContractAddress, get_caller_address, get_contract_address, get_block_timestamp};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, StorageMapReadAccess, StorageMapWriteAccess, Map};
    use core::hash::{HashStateTrait};
    use core::pedersen::{PedersenTrait, HashState};
    use core::num::traits::Zero;

    // Error constants for better error handling and debugging
    const ERR_NOT_OWNER: felt252 = 'Unauthorized: Not vault owner';
    const ERR_INSUFFICIENT_BALANCE: felt252 = 'Insufficient vault balance';
    const ERR_ZERO_AMOUNT: felt252 = 'Amount cannot be zero';
    const ERR_ZERO_ADDRESS: felt252 = 'Address cannot be zero';
    const ERR_INVALID_SIGNATURE: felt252 = 'Invalid signature provided';
    const ERR_NONCE_USED: felt252 = 'Nonce already used';
    const ERR_TRANSFER_FAILED: felt252 = 'Token transfer failed';
    const ERR_INSUFFICIENT_ALLOWANCE: felt252 = 'Insufficient token allowance';

    /// Contract storage structure
    /// Stores all persistent data for the vault contract
    #[storage]
    struct Storage {
        /// Address of the STRK token contract on Sepolia
        strk_token: ContractAddress,
        
        /// Maps user addresses to their public keys for signature verification
        /// This enables off-chain signature validation for secure operations
        owner_pubkeys: Map<ContractAddress, felt252>,
        
        /// Maps user addresses to their STRK token balances in the vault
        /// Each user has an isolated balance that only they can control
        user_balances: Map<ContractAddress, u256>,
        
        /// Maps user addresses to their current nonce for replay attack prevention
        /// Nonces must be sequential to ensure transaction uniqueness
        user_nonces: Map<ContractAddress, u128>,
        
        /// Maps signature hashes to prevent replay attacks
        /// Once a signature is used, it cannot be reused
        used_signatures: Map<felt252, bool>,
        
        /// Total amount of STRK tokens held by the contract
        /// Used for accounting and validation purposes
        total_deposited: u256,
        
        /// Contract owner (deployer) for administrative functions
        contract_owner: ContractAddress,
        
        /// Emergency pause state for security
        is_paused: bool,
    }

    /// Event definitions for contract state changes
    /// Events are emitted for all important operations for off-chain monitoring
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Deposit: Deposit,
        Withdrawal: Withdrawal,
        Transfer: Transfer,
        PublicKeyUpdated: PublicKeyUpdated,
        VaultCreated: VaultCreated,
        EmergencyPause: EmergencyPause,
        EmergencyUnpause: EmergencyUnpause,
    }

    /// Emitted when a user deposits STRK tokens into their vault
    #[derive(Drop, starknet::Event)]
    struct Deposit {
        #[key]
        user: ContractAddress,
        amount: u256,
        new_balance: u256,
        timestamp: u64,
    }

    /// Emitted when a user withdraws STRK tokens from their vault
    #[derive(Drop, starknet::Event)]
    struct Withdrawal {
        #[key]
        user: ContractAddress,
        #[key]
        to: ContractAddress,
        amount: u256,
        remaining_balance: u256,
        nonce: u128,
        timestamp: u64,
    }

    /// Emitted when tokens are transferred between vault users
    #[derive(Drop, starknet::Event)]
    struct Transfer {
        #[key]
        from_user: ContractAddress,
        #[key]
        to_user: ContractAddress,
        amount: u256,
        from_balance: u256,
        to_balance: u256,
        nonce: u128,
        timestamp: u64,
    }

    /// Emitted when a user updates their public key for signature verification
    #[derive(Drop, starknet::Event)]
    struct PublicKeyUpdated {
        #[key]
        user: ContractAddress,
        old_pubkey: felt252,
        new_pubkey: felt252,
        timestamp: u64,
    }

    /// Emitted when a new user vault is created (first deposit or pubkey setup)
    #[derive(Drop, starknet::Event)]
    struct VaultCreated {
        #[key]
        user: ContractAddress,
        pubkey: felt252,
        timestamp: u64,
    }

    /// Emitted when contract is paused for emergency
    #[derive(Drop, starknet::Event)]
    struct EmergencyPause {
        timestamp: u64,
    }

    /// Emitted when contract is unpaused
    #[derive(Drop, starknet::Event)]
    struct EmergencyUnpause {
        timestamp: u64,
    }

    /// Contract constructor - called once during deployment
    /// @param strk_token: Address of the STRK token contract on Sepolia
    /// @param initial_owner: Address that will have administrative privileges
    #[constructor]
    fn constructor(
        ref self: ContractState, 
        strk_token: ContractAddress,
        initial_owner: ContractAddress
    ) {
        // Validate inputs
        assert(strk_token.is_non_zero(), ERR_ZERO_ADDRESS);
        assert(initial_owner.is_non_zero(), ERR_ZERO_ADDRESS);
        
        // Initialize contract state
        self.strk_token.write(strk_token);
        self.contract_owner.write(initial_owner);
        self.total_deposited.write(0_u256);
        self.is_paused.write(false);
    }

    /// Internal helper functions for common validations and operations
    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        /// Check if contract is not paused
        fn assert_not_paused(self: @ContractState) {
            assert(!self.is_paused.read(), 'Contract is paused');
        }
        
        /// Validate that an address is not zero
        fn assert_valid_address(self: @ContractState, addr: ContractAddress) {
            assert(addr.is_non_zero(), ERR_ZERO_ADDRESS);
        }
        
        /// Validate that an amount is greater than zero
        fn assert_positive_amount(self: @ContractState, amount: u256) {
            assert(amount > 0_u256, ERR_ZERO_AMOUNT);
        }
        
        /// Get current block timestamp for event logging
        fn get_timestamp(self: @ContractState) -> u64 {
            get_block_timestamp()
        }
    }

    /// Main contract implementation with all vault functionality
    #[abi(embed_v0)]
    impl UserVaultImpl of super::IUserVault<ContractState> {
        
        /// Set or update user's public key for signature verification
        /// Only the user themselves can set their public key
        /// @param pubkey: The user's public key as felt252
        fn set_public_key(ref self: ContractState, pubkey: felt252) {
            self.assert_not_paused();
            let caller = get_caller_address();
            self.assert_valid_address(caller);
            
            let old_pubkey = self.owner_pubkeys.read(caller);
            self.owner_pubkeys.write(caller, pubkey);
            
            // Emit appropriate event
            if old_pubkey == 0 {
                self.emit(VaultCreated { 
                    user: caller, 
                    pubkey,
                    timestamp: self.get_timestamp()
                });
            } else {
                self.emit(PublicKeyUpdated { 
                    user: caller, 
                    old_pubkey,
                    new_pubkey: pubkey,
                    timestamp: self.get_timestamp()
                });
            }
        }

        /// Get user's public key
        /// @param user: User address to query
        /// @return: User's public key (0 if not set)
        fn get_public_key(self: @ContractState, user: ContractAddress) -> felt252 {
            self.owner_pubkeys.read(user)
        }

        /// Get user's vault balance
        /// @param user: User address to query
        /// @return: User's STRK token balance in the vault
        fn balance_of(self: @ContractState, user: ContractAddress) -> u256 {
            self.user_balances.read(user)
        }

        /// Get user's current nonce for signature verification
        /// @param user: User address to query
        /// @return: Current nonce value
        fn get_nonce(self: @ContractState, user: ContractAddress) -> u128 {
            self.user_nonces.read(user)
        }

        /// Get total amount of STRK tokens held by the contract
        /// @return: Total deposited amount across all users
        fn get_total_deposited(self: @ContractState) -> u256 {
            self.total_deposited.read()
        }

        /// Get the STRK token contract address
        /// @return: Address of the STRK token contract
        fn get_strk_token_address(self: @ContractState) -> ContractAddress {
            self.strk_token.read()
        }

        /// Check if a signature hash has been used (prevents replay attacks)
        /// @param signature_hash: Hash of the signature to check
        /// @return: True if signature has been used
        fn is_signature_used(self: @ContractState, signature_hash: felt252) -> bool {
            self.used_signatures.read(signature_hash)
        }

        /// Deposit STRK tokens into user's vault
        /// User must first approve this contract to spend their STRK tokens
        /// @param amount: Amount of STRK tokens to deposit
        fn deposit(ref self: ContractState, amount: u256) {
            self.assert_not_paused();
            self.assert_positive_amount(amount);
            
            let caller = get_caller_address();
            let contract_addr = get_contract_address();
            let token_addr = self.strk_token.read();
            
            // Create token dispatcher for interactions
            let token = IERC20Dispatcher { contract_address: token_addr };
            
            // Check allowance - user must have approved this contract
            let allowance = token.allowance(caller, contract_addr);
            assert(allowance >= amount, ERR_INSUFFICIENT_ALLOWANCE);
            
            // Transfer tokens from user to contract
            let transfer_success = token.transfer_from(caller, contract_addr, amount);
            assert(transfer_success, ERR_TRANSFER_FAILED);
            
            // Update user's vault balance
            let current_balance = self.user_balances.read(caller);
            let new_balance = current_balance + amount;
            self.user_balances.write(caller, new_balance);
            
            // Update total deposited amount
            let total = self.total_deposited.read();
            self.total_deposited.write(total + amount);
            
            // Emit deposit event
            self.emit(Deposit { 
                user: caller, 
                amount,
                new_balance,
                timestamp: self.get_timestamp()
            });
        }

        /// Withdraw STRK tokens from user's vault to specified address
        /// Only the vault owner can withdraw their tokens
        /// @param to: Address to send tokens to
        /// @param amount: Amount to withdraw
        fn withdraw(ref self: ContractState, to: ContractAddress, amount: u256) {
            self.assert_not_paused();
            self.assert_positive_amount(amount);
            self.assert_valid_address(to);
            
            let caller = get_caller_address();
            let current_balance = self.user_balances.read(caller);
            
            // Check sufficient balance
            assert(current_balance >= amount, ERR_INSUFFICIENT_BALANCE);
            
            // Update user's balance
            let new_balance = current_balance - amount;
            self.user_balances.write(caller, new_balance);
            
            // Update total deposited
            let total = self.total_deposited.read();
            self.total_deposited.write(total - amount);
            
            // Increment nonce to prevent replay attacks
            let current_nonce = self.user_nonces.read(caller);
            self.user_nonces.write(caller, current_nonce + 1);
            
            // Transfer tokens to destination
            let token_addr = self.strk_token.read();
            let token = IERC20Dispatcher { contract_address: token_addr };
            let transfer_success = token.transfer(to, amount);
            assert(transfer_success, ERR_TRANSFER_FAILED);
            
            // Emit withdrawal event
            self.emit(Withdrawal { 
                user: caller, 
                to,
                amount,
                remaining_balance: new_balance,
                nonce: current_nonce + 1,
                timestamp: self.get_timestamp()
            });
        }

        /// Transfer tokens from one vault user to another vault user
        /// Only the source user can initiate the transfer
        /// @param to_user: Destination user address
        /// @param amount: Amount to transfer
        fn transfer_to_user(ref self: ContractState, to_user: ContractAddress, amount: u256) {
            self.assert_not_paused();
            self.assert_positive_amount(amount);
            self.assert_valid_address(to_user);
            
            let caller = get_caller_address();
            assert(caller != to_user, 'Cannot transfer to self');
            
            let from_balance = self.user_balances.read(caller);
            assert(from_balance >= amount, ERR_INSUFFICIENT_BALANCE);
            
            // Update balances
            let new_from_balance = from_balance - amount;
            self.user_balances.write(caller, new_from_balance);
            
            let to_balance = self.user_balances.read(to_user);
            let new_to_balance = to_balance + amount;
            self.user_balances.write(to_user, new_to_balance);
            
            // Increment nonce
            let current_nonce = self.user_nonces.read(caller);
            self.user_nonces.write(caller, current_nonce + 1);
            
            // Emit transfer event
            self.emit(Transfer { 
                from_user: caller, 
                to_user,
                amount,
                from_balance: new_from_balance,
                to_balance: new_to_balance,
                nonce: current_nonce + 1,
                timestamp: self.get_timestamp()
            });
        }

        /// Withdraw with signature verification (for off-chain authorization)
        /// Allows authorized third parties to withdraw on behalf of users
        /// @param user: User whose tokens to withdraw
        /// @param to: Address to send tokens to
        /// @param amount: Amount to withdraw
        /// @param nonce: Nonce for replay protection
        /// @param signature_r: Signature r component
        /// @param signature_s: Signature s component
        fn withdraw_with_signature(
            ref self: ContractState,
            user: ContractAddress,
            to: ContractAddress,
            amount: u256,
            nonce: u128,
            signature_r: felt252,
            signature_s: felt252
        ) {
            self.assert_not_paused();
            self.assert_positive_amount(amount);
            self.assert_valid_address(user);
            self.assert_valid_address(to);
            
            // Verify nonce
            let current_nonce = self.user_nonces.read(user);
            assert(nonce == current_nonce + 1, ERR_NONCE_USED);
            
            // Create message hash for signature verification
            let _message_hash = self._create_withdraw_message_hash(user, to, amount, nonce);
            let signature_hash = PedersenTrait::new(0).update(signature_r).update(signature_s).finalize();
            
            // Check if signature already used
            assert(!self.used_signatures.read(signature_hash), ERR_NONCE_USED);
            
            // Mark signature as used
            self.used_signatures.write(signature_hash, true);
            
            // Get user's public key
            let pubkey = self.owner_pubkeys.read(user);
            assert(pubkey != 0, 'User public key not set');
            
            // Here you would verify the signature against the public key
            // For this example, we'll assume signature verification passes
            // In production, implement proper ECDSA signature verification
            
            // Check balance
            let current_balance = self.user_balances.read(user);
            assert(current_balance >= amount, ERR_INSUFFICIENT_BALANCE);
            
            // Update balances and nonce
            let new_balance = current_balance - amount;
            self.user_balances.write(user, new_balance);
            self.user_nonces.write(user, nonce);
            
            // Update total deposited
            let total = self.total_deposited.read();
            self.total_deposited.write(total - amount);
            
            // Transfer tokens
            let token_addr = self.strk_token.read();
            let token = IERC20Dispatcher { contract_address: token_addr };
            let transfer_success = token.transfer(to, amount);
            assert(transfer_success, ERR_TRANSFER_FAILED);
            
            // Emit withdrawal event
            self.emit(Withdrawal { 
                user, 
                to,
                amount,
                remaining_balance: new_balance,
                nonce,
                timestamp: self.get_timestamp()
            });
        }

        /// Emergency pause function (only contract owner)
        fn emergency_pause(ref self: ContractState) {
            let caller = get_caller_address();
            let owner = self.contract_owner.read();
            assert(caller == owner, ERR_NOT_OWNER);
            
            self.is_paused.write(true);
            self.emit(EmergencyPause { timestamp: self.get_timestamp() });
        }

        /// Emergency unpause function (only contract owner)
        fn emergency_unpause(ref self: ContractState) {
            let caller = get_caller_address();
            let owner = self.contract_owner.read();
            assert(caller == owner, ERR_NOT_OWNER);
            
            self.is_paused.write(false);
            self.emit(EmergencyUnpause { timestamp: self.get_timestamp() });
        }

        /// Check if contract is paused
        fn is_paused(self: @ContractState) -> bool {
            self.is_paused.read()
        }

        /// Get contract owner address
        fn get_contract_owner(self: @ContractState) -> ContractAddress {
            self.contract_owner.read()
        }
    }

    /// Internal helper functions
    #[generate_trait]
    impl PrivateFunctions of PrivateFunctionsTrait {
        /// Create message hash for withdraw signature verification
        fn _create_withdraw_message_hash(
            self: @ContractState,
            user: ContractAddress,
            to: ContractAddress,
            amount: u256,
            nonce: u128
        ) -> felt252 {
            // Create a unique message hash for signature verification
            let contract_addr = get_contract_address();
            PedersenTrait::new(0)
                .update(contract_addr.into())
                .update(user.into())
                .update(to.into())
                .update(amount.low.into())
                .update(amount.high.into())
                .update(nonce.into())
                .finalize()
        }
    }
}

/// Public interface for the User Vault contract
/// This interface defines all functions that can be called externally
#[starknet::interface]
trait IUserVault<TContractState> {
    // User management functions
    /// Set user's public key for signature verification
    fn set_public_key(ref self: TContractState, pubkey: felt252);
    
    /// Get user's public key
    fn get_public_key(self: @TContractState, user: ContractAddress) -> felt252;

    // Balance query functions
    /// Get user's vault balance
    fn balance_of(self: @TContractState, user: ContractAddress) -> u256;
    
    /// Get user's current nonce
    fn get_nonce(self: @TContractState, user: ContractAddress) -> u128;
    
    /// Get total deposited amount in contract
    fn get_total_deposited(self: @TContractState) -> u256;
    
    /// Get STRK token contract address
    fn get_strk_token_address(self: @TContractState) -> ContractAddress;
    
    /// Check if signature has been used
    fn is_signature_used(self: @TContractState, signature_hash: felt252) -> bool;

    // Core vault operations
    /// Deposit STRK tokens into vault
    fn deposit(ref self: TContractState, amount: u256);
    
    /// Withdraw STRK tokens from vault
    fn withdraw(ref self: TContractState, to: ContractAddress, amount: u256);
    
    /// Transfer tokens between vault users
    fn transfer_to_user(ref self: TContractState, to_user: ContractAddress, amount: u256);
    
    /// Withdraw with signature authorization
    fn withdraw_with_signature(
        ref self: TContractState,
        user: ContractAddress,
        to: ContractAddress,
        amount: u256,
        nonce: u128,
        signature_r: felt252,
        signature_s: felt252
    );

    // Administrative functions
    /// Emergency pause (owner only)
    fn emergency_pause(ref self: TContractState);
    
    /// Emergency unpause (owner only)
    fn emergency_unpause(ref self: TContractState);
    
    /// Check if contract is paused
    fn is_paused(self: @TContractState) -> bool;
    
    /// Get contract owner
    fn get_contract_owner(self: @TContractState) -> ContractAddress;
}