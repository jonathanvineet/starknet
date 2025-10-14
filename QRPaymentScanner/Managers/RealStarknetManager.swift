import Foundation
import Combine

// MARK: - Real Starknet Implementation
class RealStarknetManager: ObservableObject {
    static let shared = RealStarknetManager()
    
    // Contract Configuration
    struct ContractConfig {
        static let vaultContractAddress = "0x029961c5af1520f4a4ad57dccc66370b92ff7a0c47fbf00764e354c17156d7db"
        static let strkTokenAddress = "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d"
    static let rpcUrl = "https://starknet-sepolia.public.blastapi.io/rpc/v0_9"
        static let networkId = "sepolia"
    }
    
    // Published properties for UI updates
    @Published var isConnected = false
    @Published var userAddress = ""
    @Published var vaultBalance: Double = 0.0
    @Published var strkBalance: Double = 0.0
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var lastTransactionHash = ""
    
    // User credentials (stored securely in keychain in production)
    private var privateKey = ""
    private var publicKey = ""
    private var accountFilePath = ""
    private var keystoreFilePath = ""
    
    private init() {}
    
    // MARK: - Connection Management
    
    func connectWallet(address: String, privateKey: String, publicKey: String) {
        self.userAddress = address
        self.privateKey = privateKey
        self.publicKey = publicKey
        self.isConnected = true
        
        // Create temporary account files for starkli
        setupAccountFiles()
        
        // Load initial balances
        Task {
            await loadBalances()
        }
    }
    
    func disconnectWallet() {
        userAddress = ""
        privateKey = ""
        publicKey = ""
        vaultBalance = 0.0
        strkBalance = 0.0
        isConnected = false
        errorMessage = ""
        
        // Clean up temporary files
        cleanupAccountFiles()
    }
    
    // MARK: - Real Token Transfer Implementation
    
    /// Step 1: Check user's STRK balance
    func checkSTRKBalance() async -> Double {
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            let balanceHex = try await callContract(
                contractAddress: ContractConfig.strkTokenAddress,
                functionName: "balance_of",
                parameters: [userAddress]
            )
            
            let balance = weiToStrk(balanceHex)
            
            await MainActor.run {
                strkBalance = balance
                isLoading = false
            }
            
            return balance
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to check balance: \(error.localizedDescription)"
                isLoading = false
            }
            return 0.0
        }
    }
    
    /// Step 2: Check current allowance for vault contract
    func checkAllowance() async -> Double {
        do {
            let allowanceHex = try await callContract(
                contractAddress: ContractConfig.strkTokenAddress,
                functionName: "allowance",
                parameters: [userAddress, ContractConfig.vaultContractAddress]
            )
            
            return weiToStrk(allowanceHex)
            
        } catch {
            print("Failed to check allowance: \(error)")
            return 0.0
        }
    }
    
    /// Step 3: Approve vault contract to spend STRK tokens
    func approveVaultContract(amount: Double) async throws -> String {
        let amountWei = strkToWei(amount)
        
        let txHash = try await invokeContract(
            contractAddress: ContractConfig.strkTokenAddress,
            functionName: "approve",
            parameters: [ContractConfig.vaultContractAddress, amountWei, "0"]
        )
        
        return txHash
    }
    
    /// Step 4: Deposit STRK tokens to vault contract
    func depositToVault(amount: Double) async -> Bool {
        guard isConnected else {
            await MainActor.run {
                errorMessage = "Wallet not connected"
            }
            return false
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            // Check if user has enough balance
            let currentBalance = await checkSTRKBalance()
            guard currentBalance >= amount else {
                throw StarknetError.insufficientBalance
            }
            
            // Check current allowance
            let currentAllowance = await checkAllowance()
            
            // If allowance is insufficient, approve first
            if currentAllowance < amount {
                print("Insufficient allowance (\(currentAllowance)). Approving \(amount) STRK...")
                let approveTxHash = try await approveVaultContract(amount: amount)
                print("Approval transaction hash: \(approveTxHash)")
                
                // Wait for approval transaction to be confirmed
                try await waitForTransaction(txHash: approveTxHash)
            }
            
            // Now deposit the tokens
            let amountWei = strkToWei(amount)
            let depositTxHash = try await invokeContract(
                contractAddress: ContractConfig.vaultContractAddress,
                functionName: "deposit",
                parameters: [amountWei, "0"]
            )
            
            print("Deposit transaction hash: \(depositTxHash)")
            
            await MainActor.run {
                lastTransactionHash = depositTxHash
            }
            
            // Wait for transaction confirmation
            try await waitForTransaction(txHash: depositTxHash)
            
            // Reload balances after successful deposit
            await loadBalances()
            
            await MainActor.run {
                isLoading = false
            }
            
            return true
            
        } catch {
            await MainActor.run {
                errorMessage = "Deposit failed: \(error.localizedDescription)"
                isLoading = false
            }
            return false
        }
    }
    
    /// Load both wallet and vault balances
    func loadBalances() async {
        await MainActor.run {
            isLoading = true
        }
        
        async let walletBalance = checkSTRKBalance()
        async let vaultBalanceValue = checkVaultBalance()
        
        let (wallet, vault) = await (walletBalance, vaultBalanceValue)
        
        await MainActor.run {
            strkBalance = wallet
            vaultBalance = vault
            isLoading = false
        }
    }
    
    /// Check vault balance for user
    func checkVaultBalance() async -> Double {
        do {
            let balanceHex = try await callContract(
                contractAddress: ContractConfig.vaultContractAddress,
                functionName: "balance_of",
                parameters: [userAddress]
            )
            
            return weiToStrk(balanceHex)
            
        } catch {
            print("Failed to check vault balance: \(error)")
            return 0.0
        }
    }
    
    // MARK: - Withdrawal and Transfer Functions
    
    func withdrawFromVault(amount: Double) async -> Bool {
        guard isConnected else { return false }
        
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            let amountWei = strkToWei(amount)
            let txHash = try await invokeContract(
                contractAddress: ContractConfig.vaultContractAddress,
                functionName: "withdraw",
                parameters: [amountWei, "0"]
            )
            
            await MainActor.run {
                lastTransactionHash = txHash
            }
            
            try await waitForTransaction(txHash: txHash)
            await loadBalances()
            
            await MainActor.run {
                isLoading = false
            }
            
            return true
            
        } catch {
            await MainActor.run {
                errorMessage = "Withdrawal failed: \(error.localizedDescription)"
                isLoading = false
            }
            return false
        }
    }
    
    func transferToUser(toAddress: String, amount: Double) async -> Bool {
        guard isConnected else { return false }
        
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            let amountWei = strkToWei(amount)
            let txHash = try await invokeContract(
                contractAddress: ContractConfig.vaultContractAddress,
                functionName: "transfer_to_user",
                parameters: [toAddress, amountWei, "0"]
            )
            
            await MainActor.run {
                lastTransactionHash = txHash
            }
            
            try await waitForTransaction(txHash: txHash)
            await loadBalances()
            
            await MainActor.run {
                isLoading = false
            }
            
            return true
            
        } catch {
            await MainActor.run {
                errorMessage = "Transfer failed: \(error.localizedDescription)"
                isLoading = false
            }
            return false
        }
    }
    
    // MARK: - Low-level Starknet Functions
    
    private func callContract(contractAddress: String, functionName: String, parameters: [String]) async throws -> String {
        let command = [
            "starkli", "call",
            contractAddress,
            functionName
        ] + parameters + [
            "--network", "sepolia"
        ]
        
        return try await executeShellCommand(command)
    }
    
    private func invokeContract(contractAddress: String, functionName: String, parameters: [String]) async throws -> String {
        let command = [
            "starkli", "invoke",
            contractAddress,
            functionName
        ] + parameters + [
            "--network", "sepolia",
            "--account", accountFilePath,
            "--keystore", keystoreFilePath
        ]
        
        let output = try await executeShellCommand(command)
        
        // Extract transaction hash from output
        return extractTransactionHash(from: output)
    }
    
    private func executeShellCommand(_ command: [String]) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = command
            
            let pipe = Pipe()
            let errorPipe = Pipe()
            
            process.standardOutput = pipe
            process.standardError = errorPipe
            
            process.terminationHandler = { _ in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                    continuation.resume(returning: output.trimmingCharacters(in: .whitespacesAndNewlines))
                } else if let error = String(data: errorData, encoding: .utf8), !error.isEmpty {
                    continuation.resume(throwing: StarknetError.networkError(error))
                } else {
                    continuation.resume(throwing: StarknetError.networkError("Unknown error"))
                }
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func waitForTransaction(txHash: String, maxAttempts: Int = 30) async throws {
        for attempt in 1...maxAttempts {
            do {
                let command = [
                    "starkli", "transaction",
                    txHash,
                    "--network", "sepolia"
                ]
                
                let output = try await executeShellCommand(command)
                
                if output.contains("ACCEPTED_ON_L2") || output.contains("success") {
                    print("Transaction confirmed: \(txHash)")
                    return
                }
                
                print("Attempt \(attempt): Transaction pending...")
                try await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds
                
            } catch {
                if attempt == maxAttempts {
                    throw error
                }
                try await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
        
        throw StarknetError.transactionFailed("Transaction confirmation timeout")
    }
    
    // MARK: - Helper Functions
    
    private func setupAccountFiles() {
        // In a real implementation, you would create temporary account and keystore files
        // For now, we'll use the demo files from your contracts folder
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        accountFilePath = documentsPath.appendingPathComponent("account.json").path
        keystoreFilePath = documentsPath.appendingPathComponent("keystore.json").path
        
        // Create account.json
        let accountData = """
        {
            "version": 1,
            "variant": {
                "type": "open_zeppelin",
                "version": 1,
                "public_key": "\(publicKey)",
                "legacy": false
            },
            "deployment": {
                "status": "deployed",
                "class_hash": "0x061dac032f228abef9c6626f995015233097ae253a7f72d68552db02f2971b8f",
                "address": "\(userAddress)"
            }
        }
        """
        
        // Create keystore.json
        let keystoreData = """
        {
            "crypto": {
                "cipher": "aes-128-ctr",
                "cipherparams": {
                    "iv": "0x0000000000000000000000000000000000000000000000000000000000000000"
                },
                "ciphertext": "\(privateKey)",
                "kdf": "scrypt",
                "kdfparams": {
                    "dklen": 32,
                    "n": 8192,
                    "p": 1,
                    "r": 8,
                    "salt": "0x0000000000000000000000000000000000000000000000000000000000000000"
                },
                "mac": "0x0000000000000000000000000000000000000000000000000000000000000000"
            },
            "id": "00000000-0000-0000-0000-000000000000",
            "version": 3
        }
        """
        
        try? accountData.write(toFile: accountFilePath, atomically: true, encoding: .utf8)
        try? keystoreData.write(toFile: keystoreFilePath, atomically: true, encoding: .utf8)
    }
    
    private func cleanupAccountFiles() {
        try? FileManager.default.removeItem(atPath: accountFilePath)
        try? FileManager.default.removeItem(atPath: keystoreFilePath)
    }
    
    private func extractTransactionHash(from output: String) -> String {
        // Extract transaction hash from starkli output
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("transaction_hash") || line.contains("Transaction hash:") {
                // Extract hex hash
                let components = line.components(separatedBy: " ")
                for component in components {
                    if component.hasPrefix("0x") && component.count > 10 {
                        return component
                    }
                }
            }
        }
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func strkToWei(_ strk: Double) -> String {
        let wei = strk * 1e18
        return String(format: "%.0f", wei)
    }
    
    private func weiToStrk(_ weiHex: String) -> Double {
        guard let weiValue = UInt64(weiHex.dropFirst(2), radix: 16) else {
            return 0.0
        }
        return Double(weiValue) / 1e18
    }
}

// MARK: - Error Types

enum StarknetError: Error, LocalizedError {
    case networkError(String)
    case transactionFailed(String)
    case invalidAddress
    case insufficientBalance
    case commandNotFound
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .transactionFailed(let message):
            return "Transaction failed: \(message)"
        case .invalidAddress:
            return "Invalid address"
        case .insufficientBalance:
            return "Insufficient balance for this transaction"
        case .commandNotFound:
            return "starkli command not found. Please install starkli."
        }
    }
}