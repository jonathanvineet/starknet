import SwiftUI

struct PrivateKeyScannerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onScan: (String) -> Void

    func makeUIViewController(context: Context) -> PrivateKeyScannerViewController {
        let vc = PrivateKeyScannerViewController()
        vc.onScanComplete = { text in
            DispatchQueue.main.async {
                onScan(text)
                isPresented = false
            }
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: PrivateKeyScannerViewController, context: Context) {}
}
