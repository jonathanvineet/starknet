import SwiftUI
import AVFoundation

struct LiveQRScannerView: View {
    @Binding var isPresented: Bool
    var onScan: (String) -> Void

    @State private var permissionDenied = false

    var body: some View {
        ZStack {
            CameraPreview(onScan: { code in
                onScan(code)
                isPresented = false
            }, permissionDenied: $permissionDenied)
            .ignoresSafeArea()

            // Top bar overlay
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

            // Frame guide overlay
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.8), lineWidth: 3)
                .frame(width: 260, height: 260)
        }
        .alert("Camera Access Required", isPresented: $permissionDenied) {
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { isPresented = false }
        } message: {
            Text("Please enable camera access in Settings to scan QR codes.")
        }
    }
}

// MARK: - Camera Preview Representable
private struct CameraPreview: UIViewRepresentable {
    let onScan: (String) -> Void
    @Binding var permissionDenied: Bool

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan, permissionDenied: $permissionDenied) }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        context.coordinator.configureSession(preview: view)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // no-op
    }

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
                if output.availableMetadataObjectTypes.contains(.qr) {
                    output.metadataObjectTypes = [.qr]
                }
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

// MARK: - Preview Layer Host
private final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}
