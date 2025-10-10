//
//  QRScannerView.swift
//  QRPaymentScanner
//
//  Created by Rehaan John on 09/10/25.
//

import SwiftUI
import UIKit

struct QRScannerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onScanComplete: ((String) -> Void)?
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let scannerVC = storyboard.instantiateViewController(withIdentifier: "QRScannerViewController") as! QRScannerViewController
        
        // Create a navigation controller to wrap the scanner
        let navController = UINavigationController(rootViewController: scannerVC)
        
        // Add a close button
        scannerVC.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: context.coordinator,
            action: #selector(Coordinator.dismissScanner)
        )
        
        context.coordinator.parent = self
        context.coordinator.scannerVC = scannerVC
        
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: QRScannerView
        weak var scannerVC: QRScannerViewController?
        
        init(_ parent: QRScannerView) {
            self.parent = parent
        }
        
        @objc func dismissScanner() {
            parent.isPresented = false
        }
    }
}
