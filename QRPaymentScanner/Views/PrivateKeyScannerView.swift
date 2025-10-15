import SwiftUI

struct PrivateKeyScannerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onScan: (String) -> Void

    func makeUIViewController(context: Context) -> PrivateKeyScannerViewController {
        print("🔍 [QR Scanner] Creating scanner view controller")
        let vc = PrivateKeyScannerViewController()
        vc.onScanComplete = { text in
            print("📱 [QR Scanner] QR code scanned successfully")
            print("📝 [QR Scanner] Scanned text length: \(text.count)")
            print("🔑 [QR Scanner] First 10 chars: \(String(text.prefix(10)))")
            DispatchQueue.main.async {
                print("🔄 [QR Scanner] Calling onScan callback")
                onScan(text)
                print("✅ [QR Scanner] Callback completed, NOT auto-closing scanner")
                // REMOVED: isPresented = false  -- Let user close it manually
            }
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: PrivateKeyScannerViewController, context: Context) {}
}
