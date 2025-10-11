//
//  StarknetManager.swift
//  QRPaymentScanner
//
//  Starknet integration for User Vault contract
//

import Foundation
import Combine

public class StarknetManager: ObservableObject {
    public static let shared = StarknetManager()
    
    // Contract Configuration
    struct ContractConfig {
        static let vaultContractAddress = "0x029961c5af1520f4a4ad57dccc66370b92ff7a0c47fbf00764e354c17156d7db"
        static let strkTokenAddress = "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d"
        static let rpcUrl = "https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_6"
        static let networkId = "sepolia"
    }
    
    // Published properties for UI updates
    @Published public var isConnected = false
    @Published public var userAddress = ""
    @Published public var vaultBalance: Double = 0.0
    @Published public var strkBalance: Double = 0.0
    @Published public var isLoading = false
    @Published public var errorMessage = ""
    
    // User credentials (in a real app, these should be stored securely)
    private var privateKey = ""
    private var publicKey = ""
    
    private init() {}
    
    // MARK: - Connection Management
    
    public func connectWallet(address: String, privateKey: String, publicKey: String) {
        self.userAddress = address
        self.privateKey = privateKey
        self.publicKey = publicKey
        self.isConnected = true
        
        // Load initial balances
        Task {
            await loadBalances()
        }
    }
    
    public func disconnectWallet() {
        userAddress = ""
        privateKey = ""
        publicKey = ""
        isConnected = false
        vaultBalance = 0.0
        strkBalance = 0.0
    }
    
    // MARK: - Balance Management
    
    @MainActor
    public func loadBalances() async {
        guard isConnected else { return }
        
        isLoading = true
        errorMessage = ""
        
        do {
            // Get STRK balance
            let strkBalanceWei = try await callContract(
                contractAddress: ContractConfig.strkTokenAddress,
                functionName: "balance_of",
                parameters: [userAddress]
            )
            
            // Get vault balance
            let vaultBalanceWei = try await callContract(
                contractAddress: ContractConfig.vaultContractAddress,
                functionName: "balance_of",
                parameters: [userAddress]
            )
            
            // Convert from wei to STRK (divide by 10^18)
            self.strkBalance = weiToStrk(strkBalanceWei)
            self.vaultBalance = weiToStrk(vaultBalanceWei)
            
        } catch {
            self.errorMessage = "Failed to load balances: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Contract Interactions
    
    public func depositToVault(amount: Double) async -> Bool {
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
            let amountWei = strkToWei(amount)
            
            // First approve the vault contract to spend STRK tokens
            let approveSuccess = try await invokeContract(
                contractAddress: ContractConfig.strkTokenAddress,
                functionName: "approve",
                parameters: [ContractConfig.vaultContractAddress, amountWei, "0"]
            )
            
            guard approveSuccess else {
                throw StarknetError.transactionFailed("Approval failed")
            }
            
            // Then deposit the tokens
            let depositSuccess = try await invokeContract(
                contractAddress: ContractConfig.vaultContractAddress,
                functionName: "deposit",
                parameters: [amountWei, "0"]
            )
            
            if depositSuccess {
                // Reload balances after successful deposit
                await loadBalances()
                return true
            } else {
                throw StarknetError.transactionFailed("Deposit failed")
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Deposit failed: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
        return false
    }
    
    public func withdrawFromVault(amount: Double, toAddress: String) async -> Bool {
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
            let amountWei = strkToWei(amount)
            
            let success = try await invokeContract(
                contractAddress: ContractConfig.vaultContractAddress,
                functionName: "withdraw",
                parameters: [toAddress, amountWei, "0"]
            )
            
            if success {
                await loadBalances()
                return true
            } else {
                throw StarknetError.transactionFailed("Withdrawal failed")
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Withdrawal failed: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
        return false
    }
    
    public func transferToUser(toAddress: String, amount: Double) async -> Bool {
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
            let amountWei = strkToWei(amount)
            
            let success = try await invokeContract(
                contractAddress: ContractConfig.vaultContractAddress,
                functionName: "transfer_to_user",
                parameters: [toAddress, amountWei, "0"]
            )
            
            if success {
                await loadBalances()
                return true
            } else {
                throw StarknetError.transactionFailed("Transfer failed")
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Transfer failed: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
        return false
    }
    
    // MARK: - Utility Functions
    
    private func weiToStrk(_ weiString: String) -> Double {
        // Convert hex string to decimal, then divide by 10^18
        guard let weiValue = UInt64(weiString.replacingOccurrences(of: "0x", with: ""), radix: 16) else {
            return 0.0
        }
        return Double(weiValue) / 1_000_000_000_000_000_000.0
    }
    
    private func strkToWei(_ strk: Double) -> String {
        let wei = UInt64(strk * 1_000_000_000_000_000_000.0)
        return String(wei)
    }
    
    // MARK: - Network Communication
    
    private func callContract(contractAddress: String, functionName: String, parameters: [String]) async throws -> String {
        // Simulate starkli call command
        let command = """
        starkli call \(contractAddress) \(functionName) \(parameters.joined(separator: " ")) --network sepolia
        """
        
        // In a real implementation, this would execute the starkli command or use a Starknet SDK
        // For now, we'll simulate the response
        return await simulateStarkliCall(command: command)
    }
    
    private func invokeContract(contractAddress: String, functionName: String, parameters: [String]) async throws -> Bool {
        // Simulate starkli invoke command
        let command = """
        starkli invoke \(contractAddress) \(functionName) \(parameters.joined(separator: " ")) --network sepolia --private-key \(privateKey) --account \(userAddress)
        """
        
        // In a real implementation, this would execute the starkli command or use a Starknet SDK
        // For now, we'll simulate the response
        return await simulateStarkliInvoke(command: command)
    }
    
    // MARK: - Simulation Functions (Replace with real implementation)
    
    private func simulateStarkliCall(command: String) async -> String {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Return mock balance (0.5 STRK in wei)
        return "0x00000000000000000000000000000000000000000000000006f05b59d3b20000"
    }
    
    private func simulateStarkliInvoke(command: String) async -> Bool {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Simulate 90% success rate
        return Double.random(in: 0...1) > 0.1
    }
}

// MARK: - Error Types

enum StarknetError: Error, LocalizedError {
    case networkError(String)
    case transactionFailed(String)
    case invalidAddress
    case insufficientBalance
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .transactionFailed(let message):
            return "Transaction failed: \(message)"
        case .invalidAddress:
            return "Invalid address"
        case .insufficientBalance:
            return "Insufficient balance"
        }
    }
}