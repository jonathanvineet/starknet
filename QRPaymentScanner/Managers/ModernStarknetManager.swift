import Foundation
import Combine
// import Starknet  // Temporarily commented out to avoid build conflicts
import metamask_ios_sdk

/*
// MARK: - Modern Starknet Manager with Native SDKs
// Temporarily commented out to avoid Starknet.swift build conflicts
@MainActor
class ModernStarknetManager: ObservableObject {
    static let shared = ModernStarknetManager()
    
    // MARK: - Contract Configuration
    struct ContractConfig {
        static let vaultContractAddress = Felt("0x029961c5af1520f4a4ad57dccc66370b92ff7a0c47fbf00764e354c17156d7db")!
        static let strkTokenAddress = Felt("0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d")!
    static let rpcUrl = "https://starknet-sepolia.public.blastapi.io/rpc/v0_9"
        static let chainId = Felt("0x534e5f5345504f4c4941")! // Sepolia chain ID
    }
    
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var userAddress = ""
    @Published var vaultBalance: Double = 0.0
    @Published var strkBalance: Double = 0.0
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var lastTransactionHash = ""
    
    // MARK: - SDK Instances
    private var starknetProvider: StarknetProvider?
    private var userAccount: StarknetAccount?
    private var metamaskSDK: MetaMaskSDK?
    
    private init() {
        setupStarknetProvider()
        setupMetaMaskSDK()
    }
    
    // MARK: - Setup Methods
    
    private func setupStarknetProvider() {
        // Initialize Starknet provider with Sepolia network
        starknetProvider = StarknetProvider(url: URL(string: ContractConfig.rpcUrl)!)
    }
    
    private func setupMetaMaskSDK() {
        // Initialize MetaMask SDK for wallet connection
        let appMetadata = AppMetadata(name: "Starknet Vault", url: "https://your-app-url.com")
        
        metamaskSDK = MetaMaskSDK.shared(
            appMetadata,
            transport: .socket,
            sdkOptions: SDKOptions(infuraAPIKey: "your-infura-key") // Optional for read-only calls
        )
        
        metamaskSDK?.enableDebug = true
    }
    
    // MARK: - Wallet Connection with MetaMask Integration
    
    /// Connect using MetaMask SDK + Starknet credentials
    func connectWithMetaMask() async throws {
        guard let metamaskSDK = metamaskSDK else {
            throw StarknetError.sdkNotInitialized
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            // Connect to MetaMask (for Ethereum side if needed)
            let connectResult = await metamaskSDK.connect()
            
            switch connectResult {
            case .success(let account):
                print("MetaMask connected: \(account)")
                // Note: MetaMask gives us Ethereum address, but we need Starknet credentials
                // For now, we'll use the demo Starknet account
                try await connectStarknetAccount()
                
            case .failure(let error):
                throw StarknetError.connectionFailed(error.localizedDescription)
            }
            
        } catch {
            errorMessage = "Connection failed: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }
    
    /// Connect directly with Starknet credentials
    func connectStarknetAccount(
        address: String = "0x0736bf796e70dad68a103682720dafb090f50065821971b33cbeeb3e3ff5af9f",
        privateKey: String = "0x04097f4f606ccf39f9c27c01acc14bb99679de225c86795ae811b46fa96b3390"
    ) async throws {
        
        guard let provider = starknetProvider else {
            throw StarknetError.providerNotInitialized
        }
        
        do {
            // Create Starknet account with private key
            let accountAddress = Felt(address)!
            let privateKeyFelt = Felt(privateKey)!
            
            userAccount = StarknetAccount(
                address: accountAddress,
                privateKey: privateKeyFelt,
                provider: provider,
                chainId: ContractConfig.chainId
            )
            
            userAddress = address
            isConnected = true
            
            // Load initial balances
            await loadBalances()
            
            isLoading = false
            
        } catch {
            isLoading = false
            throw StarknetError.accountCreationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Balance Management
    
    /// Load both wallet and vault balances using Starknet.swift
    func loadBalances() async {
        guard let provider = starknetProvider, let account = userAccount else { return }
        
        isLoading = true
        
        do {
            // Get STRK balance in wallet
            let walletBalanceCall = StarknetCall(
                contractAddress: ContractConfig.strkTokenAddress,
                entrypoint: starknetSelector(from: "balance_of"),
                calldata: [account.address]
            )
            
            let walletBalanceResult = try await provider.callContract(call: walletBalanceCall)
            let walletBalanceWei = walletBalanceResult[0]
            
            // Get vault balance
            let vaultBalanceCall = StarknetCall(
                contractAddress: ContractConfig.vaultContractAddress,
                entrypoint: starknetSelector(from: "balance_of"),
                calldata: [account.address]
            )
            
            let vaultBalanceResult = try await provider.callContract(call: vaultBalanceCall)
            let vaultBalanceWei = vaultBalanceResult[0]
            
            // Convert from wei to STRK and update UI
            strkBalance = weiToStrk(walletBalanceWei)
            vaultBalance = weiToStrk(vaultBalanceWei)
            
            isLoading = false
            
        } catch {
            errorMessage = "Failed to load balances: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Token Transfer Implementation
    
    /// Check current allowance for vault contract
    func checkAllowance() async throws -> Felt {
        guard let provider = starknetProvider, let account = userAccount else {
            throw StarknetError.accountNotConnected
        }
        
        let allowanceCall = StarknetCall(
            contractAddress: ContractConfig.strkTokenAddress,
            entrypoint: starknetSelector(from: "allowance"),
            calldata: [account.address, ContractConfig.vaultContractAddress]
        )
        
        let result = try await provider.callContract(call: allowanceCall)
        return result[0]
    }
    
    /// Approve vault contract to spend STRK tokens
    func approveVaultContract(amount: Double) async throws -> String {
        guard let account = userAccount else {
            throw StarknetError.accountNotConnected
        }
        
        let amountWei = strkToWei(amount)
        
        let approveCall = StarknetCall(
            contractAddress: ContractConfig.strkTokenAddress,
            entrypoint: starknetSelector(from: "approve"),
            calldata: [ContractConfig.vaultContractAddress, amountWei, Felt.zero]
        )
        
        let response = try await account.executeV1(calls: [approveCall])
        
        return response.transactionHash.toHex()
    }
    
    /// Deposit STRK tokens to vault contract - THE MAIN FUNCTION
    func depositToVault(amount: Double) async -> Bool {
        guard let account = userAccount else {
            errorMessage = "Account not connected"
            return false
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            // Step 1: Check if user has sufficient balance
            if strkBalance < amount {
                throw StarknetError.insufficientBalance
            }
            
            // Step 2: Check current allowance
            let currentAllowance = try await checkAllowance()
            let requiredAllowance = strkToWei(amount)
            
            // Step 3: Approve if necessary
            if currentAllowance < requiredAllowance {
                print("Approving vault contract for \(amount) STRK...")
                let approveTxHash = try await approveVaultContract(amount: amount)
                print("Approval transaction: \(approveTxHash)")
                
                lastTransactionHash = approveTxHash
                
                // Wait for approval confirmation
                try await waitForTransaction(txHash: approveTxHash)
            }
            
            // Step 4: Execute deposit
            print("Depositing \(amount) STRK to vault...")
            let depositTxHash = try await executeDeposit(amount: amount)
            print("Deposit transaction: \(depositTxHash)")
            
            lastTransactionHash = depositTxHash
            
            // Wait for deposit confirmation
            try await waitForTransaction(txHash: depositTxHash)
            
            // Step 5: Reload balances
            await loadBalances()
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Deposit failed: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Execute the actual deposit transaction
    private func executeDeposit(amount: Double) async throws -> String {
        guard let account = userAccount else {
            throw StarknetError.accountNotConnected
        }
        
        let amountWei = strkToWei(amount)
        
        let depositCall = StarknetCall(
            contractAddress: ContractConfig.vaultContractAddress,
            entrypoint: starknetSelector(from: "deposit"),
            calldata: [amountWei, Felt.zero]
        )
        
        let response = try await account.executeV1(calls: [depositCall])
        
        return response.transactionHash.toHex()
    }
    
    // MARK: - Withdrawal and Transfer
    
    /// Withdraw STRK from vault back to wallet
    func withdrawFromVault(amount: Double) async -> Bool {
        guard let account = userAccount else {
            errorMessage = "Account not connected"
            return false
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            if vaultBalance < amount {
                throw StarknetError.insufficientBalance
            }
            
            let amountWei = strkToWei(amount)
            
            let withdrawCall = StarknetCall(
                contractAddress: ContractConfig.vaultContractAddress,
                entrypoint: starknetSelector(from: "withdraw"),
                calldata: [amountWei, Felt.zero]
            )
            
            let response = try await account.executeV1(calls: [withdrawCall])
            lastTransactionHash = response.transactionHash.toHex()
            
            try await waitForTransaction(txHash: lastTransactionHash)
            await loadBalances()
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Withdrawal failed: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Transfer STRK from vault to another user
    func transferToUser(toAddress: String, amount: Double) async -> Bool {
        guard let account = userAccount else {
            errorMessage = "Account not connected"
            return false
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            if vaultBalance < amount {
                throw StarknetError.insufficientBalance
            }
            
            let amountWei = strkToWei(amount)
            let recipientAddress = Felt(toAddress)!
            
            let transferCall = StarknetCall(
                contractAddress: ContractConfig.vaultContractAddress,
                entrypoint: starknetSelector(from: "transfer_to_user"),
                calldata: [recipientAddress, amountWei, Felt.zero]
            )
            
            let response = try await account.executeV1(calls: [transferCall])
            lastTransactionHash = response.transactionHash.toHex()
            
            try await waitForTransaction(txHash: lastTransactionHash)
            await loadBalances()
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Transfer failed: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Transaction Monitoring
    
    /// Wait for transaction confirmation using Starknet.swift
    private func waitForTransaction(txHash: String, maxAttempts: Int = 30) async throws {
        guard let provider = starknetProvider else {
            throw StarknetError.providerNotInitialized
        }
        
        let transactionHash = Felt(txHash)!
        
        for attempt in 1...maxAttempts {
            do {
                let receipt = try await provider.getTransactionReceipt(transactionHash: transactionHash)
                
                switch receipt.executionStatus {
                case .succeeded:
                    print("Transaction confirmed: \(txHash)")
                    return
                case .reverted:
                    throw StarknetError.transactionFailed("Transaction reverted")
                }
                
            } catch {
                print("Attempt \(attempt): Waiting for transaction confirmation...")
                try await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds
                
                if attempt == maxAttempts {
                    throw StarknetError.transactionFailed("Transaction confirmation timeout")
                }
            }
        }
    }
    
    // MARK: - Utility Functions
    
    func disconnectWallet() {
        userAddress = ""
        userAccount = nil
        vaultBalance = 0.0
        strkBalance = 0.0
        isConnected = false
        errorMessage = ""
        lastTransactionHash = ""
    }
    
    private func strkToWei(_ strk: Double) -> Felt {
        let wei = strk * 1e18
        return Felt(wei)!
    }
    
    private func weiToStrk(_ wei: Felt) -> Double {
        let weiValue = wei.toDecimal()
        return Double(weiValue) / 1e18
    }
}

// MARK: - Error Types
enum StarknetError: Error, LocalizedError {
    case sdkNotInitialized
    case providerNotInitialized
    case accountNotConnected
    case accountCreationFailed(String)
    case connectionFailed(String)
    case insufficientBalance
    case transactionFailed(String)
    case invalidAddress
    
    var errorDescription: String? {
        switch self {
        case .sdkNotInitialized:
            return "SDK not initialized"
        case .providerNotInitialized:
            return "Starknet provider not initialized"
        case .accountNotConnected:
            return "Starknet account not connected"
        case .accountCreationFailed(let message):
            return "Account creation failed: \(message)"
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .insufficientBalance:
            return "Insufficient balance for this transaction"
        case .transactionFailed(let message):
            return "Transaction failed: \(message)"
        case .invalidAddress:
            return "Invalid address format"
        }
*/
    }
}