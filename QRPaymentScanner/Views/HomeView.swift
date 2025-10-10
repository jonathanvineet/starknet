//
//  HomeView.swift
//  QRPaymentScanner
//
//  Created by Rehaan John on 09/10/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @State private var showQRScanner = false
    @State private var showProfile = false
    @State private var animateQRButton = false
    @State private var pulseAnimation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0, blue: 0),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Main Content
                ScrollView {
                    VStack(spacing: 25) {
                        // Welcome Section
                        VStack(spacing: 15) {
                            Image("deadpool")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.red, lineWidth: 3)
                                )
                                .shadow(color: .red.opacity(0.5), radius: 20)
                            
                            Text("Welcome Back!")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Ready for action?")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                        }
                        .padding(.top, 40)
                        
                        // Feature Cards
                        VStack(spacing: 20) {
                            FeatureCard(
                                icon: "qrcode.viewfinder",
                                title: "Quick Scan",
                                subtitle: "Scan QR codes instantly",
                                color: .red
                            )
                            
                            FeatureCard(
                                icon: "creditcard.fill",
                                title: "Payments",
                                subtitle: "Send & receive money",
                                color: .orange
                            )
                            
                            FeatureCard(
                                icon: "clock.fill",
                                title: "History",
                                subtitle: "View recent transactions",
                                color: .purple
                            )
                            
                            FeatureCard(
                                icon: "shield.fill",
                                title: "Security",
                                subtitle: "Your data is protected",
                                color: .green
                            )
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 100)
                    }
                }
                
                // Floating QR Button
                VStack {
                    Spacer()
                    
                    Button(action: {
                        showQRScanner = true
                        withAnimation(.spring()) {
                            animateQRButton.toggle()
                        }
                    }) {
                        ZStack {
                            // Pulse animation circles
                            if pulseAnimation {
                                Circle()
                                    .stroke(Color.red.opacity(0.3), lineWidth: 2)
                                    .frame(width: 80, height: 80)
                                    .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                                    .opacity(pulseAnimation ? 0 : 0.8)
                                    .animation(
                                        .easeInOut(duration: 1.5)
                                        .repeatForever(autoreverses: false),
                                        value: pulseAnimation
                                    )
                                
                                Circle()
                                    .stroke(Color.red.opacity(0.2), lineWidth: 2)
                                    .frame(width: 80, height: 80)
                                    .scaleEffect(pulseAnimation ? 1.5 : 1.0)
                                    .opacity(pulseAnimation ? 0 : 0.6)
                                    .animation(
                                        .easeInOut(duration: 1.5)
                                        .repeatForever(autoreverses: false)
                                        .delay(0.2),
                                        value: pulseAnimation
                                    )
                            }
                            
                            // Main button
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.9, green: 0, blue: 0),
                                            Color(red: 0.6, green: 0, blue: 0)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.red, Color.red.opacity(0.5)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .shadow(color: .red.opacity(0.8), radius: 20, x: 0, y: 5)
                            
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(animateQRButton ? 360 : 0))
                        }
                    }
                    .padding(.bottom, 30)
                }
                .onAppear {
                    pulseAnimation = true
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showProfile = true }) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            try? await supabase.signOut()
                        }
                    }) {
                        Image(systemName: "arrow.right.square.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $showQRScanner) {
            QRScannerModal()
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct QRScannerModal: View {
    @Environment(\.dismiss) var dismiss
    @State private var useNativeScanner = false
    
    var body: some View {
        if useNativeScanner {
            // Use your existing UIKit QR Scanner
            QRScannerView(isPresented: .constant(true)) { scannedCode in
                print("Scanned QR Code: \(scannedCode)")
                dismiss()
            }
        } else {
            // Fancy SwiftUI UI that triggers the native scanner
            NavigationView {
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 100))
                            .foregroundColor(.red)
                        
                        Text("QR Scanner")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Scan QR codes for quick payments")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        // Placeholder scanner view
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.red, lineWidth: 2)
                            .frame(width: 250, height: 250)
                            .overlay(
                                VStack {
                                    HStack {
                                        scannerCorner()
                                        Spacer()
                                        scannerCorner()
                                            .rotationEffect(.degrees(90))
                                    }
                                    Spacer()
                                    HStack {
                                        scannerCorner()
                                            .rotationEffect(.degrees(-90))
                                        Spacer()
                                        scannerCorner()
                                            .rotationEffect(.degrees(180))
                                    }
                                }
                                .padding(10)
                            )
                        
                        Button(action: {
                            useNativeScanner = true
                        }) {
                            Text("Start Scanning")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.8, green: 0, blue: 0), Color(red: 0.6, green: 0, blue: 0)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(15)
                                .shadow(color: .red.opacity(0.6), radius: 15)
                                .padding(.horizontal, 40)
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func scannerCorner() -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(Color.red, lineWidth: 3)
        .frame(width: 20, height: 20)
    }
}

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var supabase = SupabaseManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.black, Color(red: 0.1, green: 0, blue: 0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Profile Image
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
                    
                    // User Info
                    VStack(spacing: 10) {
                        Text("Deadpool")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if let email = supabase.session?.user.email {
                            Text(email)
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                    }
                    
                    // Profile Options
                    VStack(spacing: 15) {
                        ProfileOption(icon: "person.fill", title: "Edit Profile", color: .blue)
                        ProfileOption(icon: "bell.fill", title: "Notifications", color: .orange)
                        ProfileOption(icon: "shield.fill", title: "Privacy", color: .green)
                        ProfileOption(icon: "questionmark.circle.fill", title: "Help", color: .purple)
                        ProfileOption(icon: "info.circle.fill", title: "About", color: .cyan)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Sign Out Button
                    Button(action: {
                        Task {
                            try? await supabase.signOut()
                            dismiss()
                        }
                    }) {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}

struct ProfileOption: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.5))
                .font(.system(size: 14))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
        )
    }
}
