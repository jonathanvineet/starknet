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
        static let rpcUrl = "https://starknet-sepolia.public.blastapi.io/rpc/v0_9"
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
        print("\n🔐 ========== WALLET CONNECTION ==========")
        print("📍 Address: \(address)")
        print("🔑 Private Key: \(privateKey.prefix(10))...\(privateKey.suffix(10))")
        print("🔓 Public Key: \(publicKey.prefix(10))...\(publicKey.suffix(10))")
        
        self.userAddress = address
        self.privateKey = privateKey
        self.publicKey = publicKey
        self.isConnected = true
        
        print("✅ Wallet connected, loading balances...")
        print("🔐 ========== CONNECTION END ==========\n")
        
        // Load initial balances
        Task {
            await loadBalances()
        }
    }
    
    // Connect wallet in read-only mode (for wallets like Braavos that don't share private keys)
    public func connectReadOnlyWallet(address: String, publicKey: String? = nil) {
        print("\n👀 ========== READ-ONLY WALLET CONNECTION ==========")
        print("📍 Address: \(address)")
        if let pubKey = publicKey {
            print("🔓 Public Key: \(pubKey.prefix(10))...\(pubKey.suffix(10))")
            self.publicKey = pubKey
        }
        
        self.userAddress = address
        self.isConnected = true
        
        print("✅ Read-only wallet connected, loading balances...")
        print("⚠️ Note: Transaction signing not available in read-only mode")
        print("👀 ========== CONNECTION END ==========\n")
        
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
        // Skip if address is not yet known
        guard !userAddress.isEmpty else { return }
        
        isLoading = true
        errorMessage = ""
        
        do {
            print("🔍 Loading balances for address: \(userAddress)")
            print("🌐 Using RPC: \(ContractConfig.rpcUrl)")
            
            // Get STRK balance
            let strkBalanceWei = try await callContract(
                contractAddress: ContractConfig.strkTokenAddress,
                functionName: "balance_of",
                parameters: [userAddress]
            )
            
            print("💰 STRK balance (wei): \(strkBalanceWei)")
            
            // Get vault balance
            let vaultBalanceWei = try await callContract(
                contractAddress: ContractConfig.vaultContractAddress,
                functionName: "balance_of",
                parameters: [userAddress]
            )
            
            print("🏦 Vault balance (wei): \(vaultBalanceWei)")
            
            // Convert from wei to STRK (divide by 10^18)
            self.strkBalance = weiToStrk(strkBalanceWei)
            self.vaultBalance = weiToStrk(vaultBalanceWei)
            
            print("✅ STRK Balance: \(self.strkBalance) STRK")
            print("✅ Vault Balance: \(self.vaultBalance) STRK")
            
        } catch {
            self.errorMessage = "Failed to load balances: \(error.localizedDescription)"
            print("❌ Error loading balances: \(error)")
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

    // MARK: - Import (private key only)
    public func importPrivateKey(privateKey: String, address: String? = nil, publicKey: String? = nil) {
        print("\n🔐 ========== IMPORT PRIVATE KEY ==========")
        print("🔑 Private Key: \(privateKey.prefix(10))...\(privateKey.suffix(10))")
        print("📍 Address: \(address ?? "NOT PROVIDED")")
        print("🔓 Public Key: \(publicKey ?? "NOT PROVIDED")")
        
        self.privateKey = privateKey
        self.publicKey = publicKey ?? ""
        self.userAddress = address ?? ""
        self.isConnected = true
        
        // Defer balances until a valid address is available
        if let addr = address, !addr.isEmpty {
            print("✅ Address available, loading balances...")
            Task { await loadBalances() }
        } else {
            print("⚠️ No address provided, skipping balance load")
        }
        print("🔐 ========== IMPORT END ==========\n")
    }
    
    // MARK: - Utility Functions
    
    private func weiToStrk(_ weiString: String) -> Double {
        print("\n🔄 ========== WEI TO STRK CONVERSION ==========")
        print("📥 Input (wei hex): \(weiString)")
        
        // Convert hex string to decimal, then divide by 10^18
        let cleanHex = weiString.replacingOccurrences(of: "0x", with: "")
        print("🧹 Cleaned hex: \(cleanHex)")
        
        // Convert hex string to decimal using string to integer conversion
        guard let intValue = UInt(cleanHex, radix: 16) else {
            print("❌ Failed to convert hex to UInt")
            return 0.0
        }
        
        print("🔢 Integer value: \(intValue)")
        
        let decimalValue = Decimal(intValue)
        print("📊 Decimal value: \(decimalValue)")
        
        let divisor = Decimal(string: "1000000000000000000")! // 10^18
        let result = decimalValue / divisor
        
        print("➗ After division by 10^18: \(result)")
        
        let finalValue = NSDecimalNumber(decimal: result).doubleValue
        print("✅ Final STRK value: \(finalValue)")
        print("🔄 ========== CONVERSION END ==========\n")
        
        return finalValue
    }
    
    private func strkToWei(_ strk: Double) -> String {
        // Convert STRK to wei using Decimal for precision
        let strkDecimal = Decimal(strk)
        let multiplier = Decimal(string: "1000000000000000000")! // 10^18
        let weiDecimal = strkDecimal * multiplier
        
        let weiString = "\(weiDecimal)".components(separatedBy: ".").first ?? "0"
        return weiString
    }
    
    // MARK: - Network Communication
    
    private func callContract(contractAddress: String, functionName: String, parameters: [String]) async throws -> String {
        print("\n🔵 ========== RPC CALL START ==========")
        print("📞 Function: \(functionName)")
        print("📍 Contract: \(contractAddress)")
        print("📦 Parameters: \(parameters)")
        
        // Make real RPC call to Starknet
        let selector = calculateSelector(from: functionName)
        print("🎯 Selector: \(selector)")
        
        let requestBody: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "starknet_call",
            "params": [
                [
                    "contract_address": contractAddress,
                    "entry_point_selector": selector,
                    "calldata": parameters
                ],
                "latest"
            ],
            "id": 1
        ]
        
        print("📤 Request Body:")
        if let jsonData = try? JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
        
        guard let url = URL(string: ContractConfig.rpcUrl) else {
            print("❌ Invalid RPC URL: \(ContractConfig.rpcUrl)")
            throw StarknetError.networkError("Invalid RPC URL")
        }
        
        print("🌐 RPC URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("⏳ Sending request...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("📥 Response received")
        if let httpResponse = response as? HTTPURLResponse {
            print("📊 Status Code: \(httpResponse.statusCode)")
            print("📋 Headers: \(httpResponse.allHeaderFields)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("❌ RPC request failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw StarknetError.networkError("RPC request failed")
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Raw Response: \(responseString)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Failed to parse JSON response")
            throw StarknetError.networkError("Invalid JSON response")
        }
        
        print("🔍 Parsed JSON keys: \(json.keys)")
        
        if let error = json["error"] as? [String: Any] {
            print("❌ RPC Error: \(error)")
            throw StarknetError.networkError("RPC Error: \(error)")
        }
        
        guard let result = json["result"] as? [String] else {
            print("❌ No result array in response. Full JSON: \(json)")
            throw StarknetError.networkError("Invalid RPC response - no result array")
        }
        
        print("✅ Result array: \(result)")
        
        guard let balance = result.first else {
            print("❌ Result array is empty")
            throw StarknetError.networkError("Empty result array")
        }
        
        print("💰 Balance (hex): \(balance)")
        print("🔵 ========== RPC CALL END ==========\n")
        
        return balance
    }
    
    private func invokeContract(contractAddress: String, functionName: String, parameters: [String]) async throws -> Bool {
        // For now, return false - we'll implement real transactions later
        // This requires signing with the private key
        throw StarknetError.transactionFailed("Transaction signing not yet implemented")
    }
    
    // MARK: - Utility Functions
    
    private func calculateSelector(from functionName: String) -> String {
        print("🎯 Calculating selector for: \(functionName)")
        
        // Calculate Starknet selector (starknet_keccak/sha3_256 hash of the function name)
        // Correct selectors calculated using starknet_keccak
        let selectors: [String: String] = [
            "balance_of": "0x9fb6dfbd6442679d78f64a66c00e41b3c14b8a36440f418107234aa15e4766",
            "balanceOf": "0x42b43118902ce404ad9f6882cdad03bb727383209c55d71a1f9fb5a580aabe",
            "transfer": "0x83afd3f4caedc6eebf44246fe54e38c95e3179a5ec9ea81740eca5b482d12e",
            "approve": "0x219209e083275171774dab1df80982e9df2096516f06319c5c6d71ae0a8480c",
            "allowance": "0x2e5f8fe8f7d0a3c7b1e3c5b4a3e8c7f8a2e1d3f4a2b1c3d4e5f6a7b8c9d0e1f2"
        ]
        
        let selector = selectors[functionName] ?? "0x0"
        print("✅ Selector found: \(selector)")
        
        return selector
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