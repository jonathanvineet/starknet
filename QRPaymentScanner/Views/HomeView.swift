//
//  HomeView.swift
//  QRPaymentScanner
//
//  Created by Rehaan John on 09/10/25.
//

import SwiftUI
import AVFoundation
import metamask_ios_sdk

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
        }
        .sheet(isPresented: $showQRScanner) {
            QRScannerModal()
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        // Show Connect button always, even with hidden navigation bar
        .overlay(alignment: .topTrailing) {
            ConnectWalletToolbarButton()
                .padding(.top, 12)
                .padding(.trailing, 16)
        }
    }
}

// MARK: - Inline Connect Wallet toolbar button
private struct ConnectWalletToolbarButton: View {
    @State private var isConnecting = false
    @State private var isConnected = false
    @State private var account: String = ""

    private let sdk: MetaMaskSDK = {
        let appMetadata = AppMetadata(name: "StarknetQR", url: "https://starknet.example")
        return MetaMaskSDK.shared(
            appMetadata,
            transport: .deeplinking(dappScheme: "starknet"),
            sdkOptions: SDKOptions(infuraAPIKey: "")
        )
    }()

    var body: some View {
        Button(action: connect) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                Text(buttonTitle)
            }
        }
        .disabled(isConnecting)
        .foregroundColor(isConnected ? .green : .red)
        .onAppear {
            if !sdk.account.isEmpty {
                isConnected = true
                account = sdk.account
            }
        }
    }

    private var buttonTitle: String {
        if isConnected { return "Connected" }
        if isConnecting { return "Connecting…" }
        return "Connect"
    }

    private var iconName: String {
        if isConnected { return "checkmark.seal.fill" }
        if isConnecting { return "hourglass" }
        return "link.circle.fill"
    }

    private func connect() {
        isConnecting = true
        Task {
            let result = await sdk.connect()
            await MainActor.run {
                switch result {
                case .success:
                    isConnected = true
                    account = sdk.account
                case .failure:
                    isConnected = false
                }
                isConnecting = false
            }
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
    @State private var livePresented = true
    
    var body: some View {
        // Use the live SwiftUI scanner immediately in the same UI
        EmbeddedLiveQRScannerView(isPresented: $livePresented) { scannedCode in
            print("Scanned QR Code: \(scannedCode)")
            dismiss()
        }
        .onChange(of: livePresented) { wasPresented, isNowPresented in
            if wasPresented && !isNowPresented { dismiss() }
        }
    }
    
    // scannerCorner no longer needed
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

// MARK: - Embedded Live QR Scanner (SwiftUI)
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
                .stroke(Color.red.opacity(0.8), lineWidth: 3)
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

// MARK: - Embedded Camera Preview
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
