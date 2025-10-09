import UIKit
import AVFoundation
import metamask_ios_sdk

class QRScannerViewController: UIViewController {
    
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var previewView: UIView!
    // Programmatic connect wallet button
    private var connectWalletButton: UIButton!
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var isScanning = false
    // Shared MetaMask SDK instance
    private lazy var metamaskSDK: MetaMaskSDK = {
        let appMetadata = AppMetadata(name: "StarknetQR", url: "https://starknet.example")
        // transport .deeplinking requires Info.plist CFBundleURLSchemes = "starknet"
        return MetaMaskSDK.shared(
            appMetadata,
            transport: .deeplinking(dappScheme: "starknet"),
            sdkOptions: SDKOptions(infuraAPIKey: "INFURA_API_KEY")
        )
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkCameraPermission()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
    
    private func setupUI() {
        title = "QR Scanner"
        
        scanButton.setTitle("Scan QR Code", for: .normal)
        scanButton.backgroundColor = .systemBlue
        scanButton.setTitleColor(.white, for: .normal)
        scanButton.layer.cornerRadius = 10
        scanButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        
        resultLabel.text = "Tap 'Scan QR Code' to begin scanning"
        resultLabel.textAlignment = .center
        resultLabel.numberOfLines = 0
        resultLabel.font = UIFont.systemFont(ofSize: 16)
        resultLabel.textColor = .label
        
        previewView.backgroundColor = .black
        previewView.layer.cornerRadius = 10
        previewView.isHidden = true

        // Create connect wallet button
        connectWalletButton = UIButton(type: .system)
        connectWalletButton.translatesAutoresizingMaskIntoConstraints = false
        connectWalletButton.setTitle("Connect Wallet", for: .normal)
        connectWalletButton.setTitleColor(.white, for: .normal)
        connectWalletButton.backgroundColor = .systemGreen
        connectWalletButton.layer.cornerRadius = 10
        connectWalletButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        connectWalletButton.addTarget(self, action: #selector(connectWalletTapped(_:)), for: .touchUpInside)

        view.addSubview(connectWalletButton)

        // Layout: place below scanButton (if connected via storyboard) or at top-right corner
        NSLayoutConstraint.activate([
            connectWalletButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            connectWalletButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            connectWalletButton.widthAnchor.constraint(equalToConstant: 140),
            connectWalletButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if !granted {
                        self?.showPermissionAlert()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert()
        @unknown default:
            showPermissionAlert()
        }
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please enable camera access in Settings to scan QR codes.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func setupScanner() {
        guard !isScanning else { return }
        
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showError("Unable to access camera")
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            showError("Unable to create camera input: \(error.localizedDescription)")
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            showError("Unable to add camera input to session")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            showError("Unable to add metadata output to session")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = previewView.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewView.layer.addSublayer(previewLayer)
        
        isScanning = true
        previewView.isHidden = false
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.scanButton.setTitle("Stop Scanning", for: .normal)
            self?.scanButton.backgroundColor = .systemRed
            self?.resultLabel.text = "Point camera at QR code to scan"
        }
    }
    
    private func stopScanner() {
        guard isScanning else { return }
        
        captureSession.stopRunning()
        previewLayer.removeFromSuperlayer()
        previewView.isHidden = true
        isScanning = false
        
        scanButton.setTitle("Scan QR Code", for: .normal)
        scanButton.backgroundColor = .systemBlue
        resultLabel.text = "Tap 'Scan QR Code' to begin scanning"
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @IBAction func scanButtonTapped(_ sender: UIButton) {
        if isScanning {
            stopScanner()
        } else {
            checkCameraPermission()
            if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
                setupScanner()
            }
        }
    }

    // MARK: - MetaMask SDK integration

    @objc private func connectWalletTapped(_ sender: UIButton) {
        // Update UI immediately
        connectWalletButton.isEnabled = false
        connectWalletButton.setTitle("Connecting...", for: .normal)

        Task {
            let connectResult = await metamaskSDK.connect()
            DispatchQueue.main.async {
                switch connectResult {
                case .success:
                    self.connectWalletButton.setTitle("Connected", for: .normal)
                    self.connectWalletButton.backgroundColor = .systemBlue
                    self.resultLabel.text = "Connected: \(self.metamaskSDK.account)"
                case .failure(let error):
                    self.connectWalletButton.setTitle("Connect Wallet", for: .normal)
                    self.connectWalletButton.backgroundColor = .systemGreen
                    self.showError("Failed to connect: \(error.localizedDescription)")
                }
                self.connectWalletButton.isEnabled = true
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let previewLayer = previewLayer {
            previewLayer.frame = previewView.layer.bounds
        }
    }
}

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            stopScanner()
            showQRResult(stringValue)
        }
    }
    
    private func showQRResult(_ result: String) {
        resultLabel.text = "QR Code Result:\n\n\(result)"
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        let alert = UIAlertController(
            title: "QR Code Scanned",
            message: result,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Copy", style: .default) { _ in
            UIPasteboard.general.string = result
        })
        
        alert.addAction(UIAlertAction(title: "Scan Another", style: .default) { [weak self] _ in
            self?.setupScanner()
        })
        
        alert.addAction(UIAlertAction(title: "Done", style: .cancel))
        present(alert, animated: true)
    }
}