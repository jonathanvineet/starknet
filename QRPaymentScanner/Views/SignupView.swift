//
//  SignupView.swift
//  QRPaymentScanner
//
//  Created by Rehaan John on 09/10/25.
//

import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var supabase = SupabaseManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var phone = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.1, green: 0, blue: 0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Logo/Image
                        Image("deadpool")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.red, lineWidth: 3)
                            )
                            .shadow(color: .red.opacity(0.5), radius: 20)
                            .padding(.top, 40)
                        
                        // Title
                        VStack(spacing: 10) {
                            Text("Create Account")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Sign up to get started")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        
                        // Signup Form
                        VStack(spacing: 20) {
                            // Full Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)
                                
                                TextField("", text: $fullName)
                                    .placeholder(when: fullName.isEmpty) {
                                        Text("Enter your full name")
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                    .autocorrectionDisabled()
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.white.opacity(0.05))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .foregroundColor(.white)
                            }
                            
                            // Phone Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Phone Number")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)
                                
                                TextField("", text: $phone)
                                    .placeholder(when: phone.isEmpty) {
                                        Text("Enter your phone number")
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                    .keyboardType(.phonePad)
                                    .autocorrectionDisabled()
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.white.opacity(0.05))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .foregroundColor(.white)
                            }
                            
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)
                                
                                TextField("", text: $email)
                                    .placeholder(when: email.isEmpty) {
                                        Text("Enter your email")
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.white.opacity(0.05))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .foregroundColor(.white)
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)
                                
                                SecureField("", text: $password)
                                    .placeholder(when: password.isEmpty) {
                                        Text("Enter your password")
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.white.opacity(0.05))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .foregroundColor(.white)
                                
                                // Password strength indicator
                                if !password.isEmpty {
                                    HStack(spacing: 5) {
                                        ForEach(0..<4) { index in
                                            Rectangle()
                                                .fill(passwordStrength > index ? strengthColor : Color.gray.opacity(0.3))
                                                .frame(height: 4)
                                                .cornerRadius(2)
                                        }
                                    }
                                    
                                    Text(strengthText)
                                        .font(.system(size: 12))
                                        .foregroundColor(strengthColor)
                                }
                            }
                            
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)
                                
                                SecureField("", text: $confirmPassword)
                                    .placeholder(when: confirmPassword.isEmpty) {
                                        Text("Confirm your password")
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.white.opacity(0.05))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 15)
                                                    .stroke(passwordsMatch ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .foregroundColor(.white)
                                
                                if !confirmPassword.isEmpty && !passwordsMatch {
                                    Text("Passwords don't match")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                }
                            }
                            
                            // Sign Up Button
                            Button(action: {
                                signUp()
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Sign Up")
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.9, green: 0, blue: 0),
                                            Color(red: 0.6, green: 0, blue: 0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(15)
                                .shadow(color: .red.opacity(0.5), radius: 15)
                            }
                            .disabled(isLoading || !isFormValid)
                            .opacity(isFormValid ? 1.0 : 0.6)
                        }
                        .padding(.horizontal, 30)
                        
                        // Terms and Conditions
                        Text("By signing up, you agree to our Terms & Privacy Policy")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        // Back to Login
                        Button(action: {
                            dismiss()
                        }) {
                            HStack {
                                Text("Already have an account?")
                                    .foregroundColor(.gray)
                                Text("Login")
                                    .foregroundColor(.red)
                                    .fontWeight(.semibold)
                            }
                            .font(.system(size: 16))
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Success! 🎉", isPresented: $showSuccess) {
                Button("Continue") {
                    dismiss() // Close signup view, ContentView will show HomePage
                }
            } message: {
                Text("Account created successfully! You're now logged in.")
            }
            .navigationBarHidden(true)
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !fullName.isEmpty &&
        !phone.isEmpty &&
        passwordsMatch &&
        password.count >= 6
    }
    
    private var passwordsMatch: Bool {
        password == confirmPassword
    }
    
    private var passwordStrength: Int {
        var strength = 0
        if password.count >= 6 { strength += 1 }
        if password.count >= 10 { strength += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { strength += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { strength += 1 }
        return strength
    }
    
    private var strengthColor: Color {
        switch passwordStrength {
        case 0...1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        default: return .gray
        }
    }
    
    private var strengthText: String {
        switch passwordStrength {
        case 0...1: return "Weak"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Strong"
        default: return ""
        }
    }
    
    private func signUp() {
        isLoading = true
        Task {
            do {
                try await supabase.signUp(email: email, password: password, username: fullName, phone: phone)
                // User is now logged in (session is set in SupabaseManager)
                // Show success message
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}
