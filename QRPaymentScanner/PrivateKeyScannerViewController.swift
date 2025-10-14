import UIKit
import AVFoundation

class PrivateKeyScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onScanComplete: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let guidanceLabel: UILabel = {
        let label = UILabel()
        label.text = "Align QR within the frame"
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor(white: 0, alpha: 0.3)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupScanner()

        let close = UIButton(type: .system)
        close.setTitle("Close", for: .normal)
        close.tintColor = .white
        close.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        close.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(close)
        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12)
        ])

        view.addSubview(guidanceLabel)
        NSLayoutConstraint.activate([
            guidanceLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            guidanceLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            guidanceLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.9)
        ])
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

    private func setupScanner() {
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [.qr]

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.layer.bounds
        view.layer.insertSublayer(layer, at: 0)
        self.previewLayer = layer

        self.captureSession = session
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let text = obj.stringValue else { return }
        captureSession?.stopRunning()
        onScanComplete?(text)
        dismiss(animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
}
