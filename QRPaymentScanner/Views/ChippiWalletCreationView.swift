import SwiftUI

struct ChippiWalletCreationView: View {
    @ObservedObject var chippiPayManager: ChippiPayManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var userPassword = ""
    @State private var confirmPassword = ""
    @State private var externalUserId = ""
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var creationStep = 1
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Step Indicator
                    stepIndicator
                    
                    // Content based on step
                    switch creationStep {
                    case 1:
                        userInfoStep
                    case 2:
                        securityStep
                    case 3:
                        confirmationStep
                    default:
                        EmptyView()
                    }
                    
                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Create Gasless Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(isCreating)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isCreating {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.checkerboard")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Gasless Wallet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Create a secure, self-custodial wallet for gasless transactions")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Step Indicator
    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(1...3, id: \.self) { step in
                HStack {
                    Circle()
                        .fill(step <= creationStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text("\(step)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(step <= creationStep ? .white : .gray)
                        )
                    
                    if step < 3 {
                        Rectangle()
                            .fill(step < creationStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - Step 1: User Info
    private var userInfoStep: some View {
        VStack(spacing: 20) {
            Text("Step 1: User Information")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("User ID")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Enter your unique user ID", text: $externalUserId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Text("This will be used to identify your wallet. Choose something unique.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Why do I need this?")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Text("• Your wallet will be linked to this ID\n• Used for authentication with ChippiPay\n• Ensures secure access to your gasless transactions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Step 2: Security
    private var securityStep: some View {
        VStack(spacing: 20) {
            Text("Step 2: Security Setup")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Wallet Password")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                SecureField("Create a secure password", text: $userPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Confirm your password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !userPassword.isEmpty && !confirmPassword.isEmpty {
                    HStack {
                        Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(passwordsMatch ? .green : .red)
                        Text(passwordsMatch ? "Passwords match" : "Passwords don't match")
                            .font(.caption)
                            .foregroundColor(passwordsMatch ? .green : .red)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.green)
                    Text("Security Features")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Text("• Your private key is encrypted with this password\n• Only you have access to your wallet\n• Password is never stored on our servers\n• Self-custodial = You control your funds")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Step 3: Confirmation
    private var confirmationStep: some View {
        VStack(spacing: 20) {
            Text("Step 3: Confirmation")
                .font(.headline)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("User ID:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(externalUserId)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wallet Features:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        FeatureRow(icon: "bolt.fill", text: "Gasless transactions", color: .orange)
                        FeatureRow(icon: "shield.fill", text: "Self-custodial security", color: .green)
                        FeatureRow(icon: "creditcard.fill", text: "Service payments", color: .blue)
                        FeatureRow(icon: "key.fill", text: "Encrypted private key", color: .purple)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Important")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Text("• Remember your password - it cannot be recovered\n• Keep your wallet information secure\n• This wallet will be created on Starknet mainnet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if creationStep < 3 {
                Button("Next") {
                    withAnimation {
                        if canProceedToNextStep {
                            creationStep += 1
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canProceedToNextStep)
                .frame(maxWidth: .infinity)
                
                if creationStep > 1 {
                    Button("Back") {
                        withAnimation {
                            creationStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
            } else {
                Button(action: createWallet) {
                    HStack {
                        if isCreating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }
                        Text(isCreating ? "Creating Wallet..." : "Create Wallet")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCreating || !isReadyToCreate)
                .frame(maxWidth: .infinity)
                
                Button("Back") {
                    withAnimation {
                        creationStep -= 1
                    }
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                .disabled(isCreating)
            }
        }
    }
    
    // MARK: - Helper Views
    private struct FeatureRow: View {
        let icon: String
        let text: String
        let color: Color
        
        var body: some View {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                Text(text)
                    .font(.caption)
                Spacer()
            }
        }
    }
    
    // MARK: - Computed Properties
    private var passwordsMatch: Bool {
        !userPassword.isEmpty && !confirmPassword.isEmpty && userPassword == confirmPassword
    }
    
    private var canProceedToNextStep: Bool {
        switch creationStep {
        case 1:
            return !externalUserId.isEmpty && externalUserId.count >= 3
        case 2:
            return passwordsMatch && userPassword.count >= 6
        default:
            return false
        }
    }
    
    private var isReadyToCreate: Bool {
        !externalUserId.isEmpty && passwordsMatch && userPassword.count >= 6
    }
    
    // MARK: - Actions
    private func createWallet() {
        isCreating = true
        
        Task {
            do {
                // Create mock auth token for demo
                let authToken = "demo_auth_token_\(UUID().uuidString)"
                
                _ = try await chippiPayManager.createGaslessWallet(
                    userPassword: userPassword,
                    authToken: authToken,
                    externalUserId: externalUserId
                )
                
                await MainActor.run {
                    isCreating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Preview
struct ChippiWalletCreationView_Previews: PreviewProvider {
    static var previews: some View {
        ChippiWalletCreationView(chippiPayManager: ChippiPayManager())
    }
}