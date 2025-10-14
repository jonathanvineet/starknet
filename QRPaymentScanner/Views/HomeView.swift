//
//  HomeView.swift
//  QRPaymentScanner
//
//  Banking-style UI with full backend functionality
//

import SwiftUI
import AVFoundation

struct HomeView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @StateObject private var starknet = StarknetManager.shared
    @State private var showQRScanner = false
    @State private var showQRPayment = false
    @State private var showProfile = false
    @State private var showStarknetConnect = false
    @State private var showDepositView = false
    @State private var showWithdrawView = false
    @State private var showTransferView = false
    @State private var showChippiPayServices = false
    @State private var balance: Double = 12453.89
    @State private var monthlyChange: Double = 432.12
    @State private var showChippiPayTest = false
    @State private var testResult = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("HELLO")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                if let email = supabase.userEmail {
                                    Text(email.components(separatedBy: "@").first ?? "User")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.primary)
                                } else {
                                    Text("User")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                                
                                Text("Last login: \(formattedDate())")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            // Starknet Connect Button
                            Button(action: {
                                if starknet.isConnected {
                                    starknet.disconnectWallet()
                                } else {
                                    showStarknetConnect = true
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: starknet.isConnected ? "bolt.fill" : "bolt.circle")
                                        .foregroundColor(starknet.isConnected ? .green : .orange)
                                    Text(starknet.isConnected ? "Connected" : "Connect")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(starknet.isConnected ? .green : .orange)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            // Profile Button
                            Button(action: {
                                showProfile = true
                            }) {
                                Circle()
                                    .fill(Color(red: 0.8, green: 0.3, blue: 0.3))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 22))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Vault Balance Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Starknet Vault")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            if starknet.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Button("Refresh") {
                                    Task {
                                        await starknet.loadBalances()
                                    }
                                }
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.8, green: 0.3, blue: 0.3))
                            }
                        }
                        
                        if starknet.isConnected {
                            Text("\(String(format: "%.4f", starknet.vaultBalance)) STRK")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(Color(red: 0.8, green: 0.3, blue: 0.3))
                            
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Wallet Balance")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Text("\(String(format: "%.4f", starknet.strkBalance)) STRK")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Network")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Text("Sepolia")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                            }
                        } else {
                            Text("Connect to view balance")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.gray)
                            
                            Text("Connect your Starknet wallet to access vault features")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(20)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    
                    // Vault Action Buttons Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 24) {
                        ActionButton(icon: "plus.circle.fill", title: "Deposit", color: .green) {
                            if starknet.isConnected {
                                showDepositView = true
                            } else {
                                showStarknetConnect = true
                            }
                        }
                        
                        ActionButton(icon: "minus.circle.fill", title: "Withdraw", color: .orange) {
                            if starknet.isConnected {
                                showWithdrawView = true
                            } else {
                                showStarknetConnect = true
                            }
                        }
                        
                        ActionButton(icon: "arrow.right.circle.fill", title: "Transfer", color: .blue) {
                            if starknet.isConnected {
                                showTransferView = true
                            } else {
                                showStarknetConnect = true
                            }
                        }
                        
                        ActionButton(icon: "qrcode.viewfinder", title: "QR Pay") {
                            showQRPayment = true
                        }
                        
                        ActionButton(icon: "bolt.circle.fill", title: "ChippiPay", color: .orange) {
                            showChippiPayServices = true
                        }
                        
                        ActionButton(icon: "chart.line.uptrend.xyaxis", title: "Analytics") {
                            print("Analytics tapped")
                        }
                        
                        ActionButton(icon: "gear", title: "Settings") {
                            print("Settings tapped")
                        }

                        // ChippiPay Test Button (Debug)
                        #if DEBUG
                        ActionButton(icon: "network", title: "Test API", color: .purple) {
                            showChippiPayTest = true
                        }
                        #endif
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    
                    // My Accounts Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("My Accounts")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: {
                                print("Add account tapped")
                            }) {
                                Text("Add Account")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.8, green: 0.3, blue: 0.3))
                            }
                        }
                        
                        AccountCard(
                            title: "User Account",
                            amount: "EUR (€) 352.75",
                            showPercentage: false
                        )
                        
                        AccountCard(
                            title: "Savings Account",
                            amount: "USD ($) 944.30",
                            showPercentage: true,
                            percentage: "+12.5%"
                        )
                        
                        AccountCard(
                            title: "Family Account",
                            amount: "EUR (€) 125.60",
                            showPercentage: false
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    
                    // Recent Activity Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recent Activity")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: {
                                print("View all activity tapped")
                            }) {
                                Text("View All")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.8, green: 0.3, blue: 0.3))
                            }
                        }
                        
                        ActivityRow(
                            title: "QR Payment",
                            time: "10:30 AM",
                            amount: "-$4.50",
                            isPositive: false,
                            showDot: true
                        )
                        
                        ActivityRow(
                            title: "Wallet Transfer",
                            time: "Yesterday",
                            amount: "+$200.00",
                            isPositive: true,
                            showDot: true
                        )
                        
                        ActivityRow(
                            title: "Cash Top-up",
                            time: "2 days ago",
                            amount: "+$100.00",
                            isPositive: true,
                            showDot: true
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .padding(.bottom, 100)
                }
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarHidden(true)
        }
        .overlay(
            // Floating QR Scanner Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showQRScanner = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.8, green: 0.3, blue: 0.3))
                                .frame(width: 60, height: 60)
                                .shadow(color: Color(red: 0.8, green: 0.3, blue: 0.3).opacity(0.4), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
        )
        .sheet(isPresented: $showQRScanner) {
            QRScannerModal()
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showStarknetConnect) {
            WalletConnectionView()
        }
        .sheet(isPresented: $showDepositView) {
            VaultActionView(actionType: .deposit)
        }
        .sheet(isPresented: $showWithdrawView) {
            VaultActionView(actionType: .withdraw)
        }
        .sheet(isPresented: $showTransferView) {
            VaultActionView(actionType: .transfer)
        }
        .sheet(isPresented: $showQRPayment) {
            QRPaymentView()
        }
        .sheet(isPresented: $showChippiPayServices) {
            ChippiPayServicesView()
        }
        .alert("ChippiPay API Test", isPresented: $showChippiPayTest) {
            Button("Run Test") {
                Task {
                    await runChippiPayTest()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if testResult.isEmpty {
                Text("Test the ChippiPay API connection and fetch available services.")
            } else {
                Text(testResult)
            }
        }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: Date())
    }

    @MainActor
    private func runChippiPayTest() async {
        let manager = ChippiPayManager(environment: .production)

        do {
            try await manager.fetchAvailableServices()

            if manager.availableServices.isEmpty {
                testResult = "⚠️ Connected but no services found"
            } else {
                testResult = "✅ Success! Found \(manager.availableServices.count) services"
            }
        } catch {
            testResult = "❌ Failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    init(icon: String, title: String, color: Color = Color(red: 0.8, green: 0.3, blue: 0.3), action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Circle()
                    .fill(color)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    )
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - Account Card

struct AccountCard: View {
    let title: String
    let amount: String
    let showPercentage: Bool
    var percentage: String = ""
    
    var body: some View {
        Button(action: {
            print("\(title) tapped")
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(amount)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    if showPercentage {
                        Text(percentage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            .padding(20)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(16)
        }
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let title: String
    let time: String
    let amount: String
    let isPositive: Bool
    let showDot: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if showDot {
                Circle()
                    .fill(isPositive ? Color.green : Color(red: 0.8, green: 0.3, blue: 0.3))
                    .frame(width: 8, height: 8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(time)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(amount)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isPositive ? .green : .primary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - QR Scanner Modal (Keep your existing implementation)

struct QRScannerModal: View {
    @Environment(\.dismiss) var dismiss
    @State private var livePresented = true
    
    var body: some View {
        EmbeddedLiveQRScannerView(isPresented: $livePresented) { scannedCode in
            print("Scanned QR Code: \(scannedCode)")
            dismiss()
        }
        .onChange(of: livePresented) { wasPresented, isNowPresented in
            if wasPresented && !isNowPresented { dismiss() }
        }
    }
}

// MARK: - Embedded Live QR Scanner (Your existing implementation)

private struct EmbeddedLiveQRScannerView: View {
    @Binding var isPresented: Bool
    var onScan: (String) -> Void

    @State private var permissionDenied = false

    var body: some View {
        ZStack {
            EmbeddedCameraPreview(onScan: { code in
                onScan(code)
                isPresented = false
            }, permissionDenied: $permissionDenied)
            .ignoresSafeArea()

            HStack {
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                }
                Spacer()
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity, alignment: .top)

            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.8, green: 0.3, blue: 0.3).opacity(0.8), lineWidth: 3)
                .frame(width: 260, height: 260)
        }
        .alert("Camera Access Required", isPresented: $permissionDenied) {
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            Button("Cancel", role: .cancel) { isPresented = false }
        } message: {
            Text("Please enable camera access in Settings to scan QR codes.")
        }
    }
}

// MARK: - Embedded Camera Preview (Your existing implementation)

private struct EmbeddedCameraPreview: UIViewRepresentable {
    let onScan: (String) -> Void
    @Binding var permissionDenied: Bool

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan, permissionDenied: $permissionDenied) }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        context.coordinator.configureSession(preview: view)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) { }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        private let onScan: (String) -> Void
        @Binding private var permissionDenied: Bool
        private let session = AVCaptureSession()

        init(onScan: @escaping (String) -> Void, permissionDenied: Binding<Bool>) {
            self.onScan = onScan
            self._permissionDenied = permissionDenied
        }

        func configureSession(preview: PreviewView) {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                setup(preview: preview)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        if granted { self.setup(preview: preview) }
                        else { self.permissionDenied = true }
                    }
                }
            case .denied, .restricted:
                permissionDenied = true
            @unknown default:
                permissionDenied = true
            }
        }

        private func setup(preview: PreviewView) {
            guard let device = AVCaptureDevice.default(for: .video) else { return }
            session.beginConfiguration()
            session.sessionPreset = .high

            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) { session.addInput(input) }
            } catch {
                print("Camera input error: \(error.localizedDescription)")
            }

            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: .main)
                if output.availableMetadataObjectTypes.contains(.qr) { output.metadataObjectTypes = [.qr] }
            }

            session.commitConfiguration()

            preview.videoPreviewLayer.session = session
            preview.videoPreviewLayer.videoGravity = .resizeAspectFill

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = object.stringValue else { return }
            session.stopRunning()
            onScan(value)
        }
    }
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

// MARK: - Profile View (Your existing implementation)

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var supabase = SupabaseManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Circle()
                        .fill(Color(red: 0.8, green: 0.3, blue: 0.3))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        )
                        .shadow(color: Color(red: 0.8, green: 0.3, blue: 0.3).opacity(0.3), radius: 20)
                    
                    VStack(spacing: 10) {
                        Text("User Profile")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if let email = supabase.session?.user.email {
                            Text(email)
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                    }
                    
                    VStack(spacing: 15) {
                        ProfileOption(icon: "person.fill", title: "Edit Profile", color: .blue)
                        ProfileOption(icon: "bell.fill", title: "Notifications", color: .orange)
                        ProfileOption(icon: "shield.fill", title: "Privacy", color: .green)
                        ProfileOption(icon: "questionmark.circle.fill", title: "Help", color: .purple)
                        ProfileOption(icon: "info.circle.fill", title: "About", color: .cyan)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            try? await supabase.signOut()
                            dismiss()
                        }
                    }) {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.8, green: 0.3, blue: 0.3))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 30)
                }
                .padding(.top, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.8, green: 0.3, blue: 0.3))
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
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.5))
                .font(.system(size: 14))
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
    }
}
