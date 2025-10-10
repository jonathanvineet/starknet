//
//  ConfirmEmailView.swift
//  QRPaymentScanner
//
//  Created by Rehaan John on 09/10/25.
//

import SwiftUI

struct ConfirmEmailView: View {
    @Environment(\.dismiss) var dismiss
    let email: String
    @State private var showAnimation = false
    
    var body: some View {
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
            
            VStack(spacing: 30) {
                Spacer()
                
                // Success Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.9, green: 0, blue: 0).opacity(0.2),
                                    Color(red: 0.6, green: 0, blue: 0).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 150, height: 150)
                        .scaleEffect(showAnimation ? 1.0 : 0.5)
                        .opacity(showAnimation ? 1 : 0)
                    
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 2)
                        .frame(width: 150, height: 150)
                        .scaleEffect(showAnimation ? 1.2 : 0.5)
                        .opacity(showAnimation ? 0.5 : 0)
                    
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                        .scaleEffect(showAnimation ? 1.0 : 0.5)
                        .opacity(showAnimation ? 1 : 0)
                }
                .padding(.top, 40)
                
                // Title
                VStack(spacing: 15) {
                    Text("Check Your Email")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(showAnimation ? 1 : 0)
                        .offset(y: showAnimation ? 0 : 20)
                    
                    Text("We've sent a confirmation link to")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .opacity(showAnimation ? 1 : 0)
                        .offset(y: showAnimation ? 0 : 20)
                    
                    Text(email)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                        .opacity(showAnimation ? 1 : 0)
                        .offset(y: showAnimation ? 0 : 20)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                
                // Info Box
                VStack(spacing: 15) {
                    HStack(spacing: 15) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("What's next?")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Click the link in your email to verify your account")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    // Tips
                    VStack(alignment: .leading, spacing: 10) {
                        TipRow(icon: "clock", text: "Link expires in 24 hours")
                        TipRow(icon: "questionmark.circle", text: "Check your spam folder")
                        TipRow(icon: "arrow.clockwise", text: "You can request a new link anytime")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.05))
                    )
                }
                .padding(.horizontal, 30)
                .opacity(showAnimation ? 1 : 0)
                .offset(y: showAnimation ? 0 : 30)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 15) {
                    Button(action: {
                        resendEmail()
                    }) {
                        Text("Resend Email")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.red, lineWidth: 2)
                            )
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Back to Login")
                            .font(.system(size: 16, weight: .semibold))
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
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                .opacity(showAnimation ? 1 : 0)
                .offset(y: showAnimation ? 0 : 30)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showAnimation = true
            }
        }
    }
    
    private func resendEmail() {
        Task {
            do {
                try await SupabaseManager.shared.resendConfirmationEmail(email: email)
                // Show success message
            } catch {
                // Show error
            }
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.red)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
}
