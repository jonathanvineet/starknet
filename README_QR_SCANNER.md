# QR Payment Scanner iOS App

A simple iOS application built with Swift that provides QR code scanning functionality for payment processing.

## Features

- **Simple Interface**: Clean, user-friendly interface with a single "Scan QR Code" button
- **Live Camera Preview**: Real-time camera preview when scanning
- **Instant Results**: Displays QR code content immediately after scanning
- **Permission Handling**: Proper camera permission requests with helpful alerts
- **Haptic Feedback**: Provides tactile feedback when QR codes are detected
- **Multiple Actions**: Copy result to clipboard or scan another code
- **Auto-stop Scanning**: Automatically stops scanning when QR code is found

## Requirements

- iOS 15.0 or later
- Xcode 15.0 or later
- Swift 5.0
- Physical device with camera (simulators have limited camera support)

## Getting Started

1. **Open the Project**
   ```bash
   open QRPaymentScanner.xcodeproj
   ```

2. **Configure Development Team**
   - Select the project in Xcode
   - Go to "Signing & Capabilities"
   - Select your development team
   - Update the bundle identifier if needed (currently set to `com.example.QRPaymentScanner`)

3. **Run the App**
   - Select your target device (physical device recommended for camera testing)
   - Press Cmd+R or click the Run button

## Project Structure

```
QRPaymentScanner/
├── QRPaymentScanner.xcodeproj/     # Xcode project file
├── QRPaymentScanner/
│   ├── AppDelegate.swift           # App lifecycle management
│   ├── SceneDelegate.swift         # Scene lifecycle management
│   ├── QRScannerViewController.swift # Main QR scanning functionality
│   ├── Info.plist                  # App configuration and permissions
│   └── Base.lproj/
│       ├── Main.storyboard         # Main UI layout
│       └── LaunchScreen.storyboard # Launch screen
```

## Key Components

### QRScannerViewController
- Main view controller handling QR scanning logic
- Uses `AVCaptureSession` for camera access
- Implements `AVCaptureMetadataOutputObjectsDelegate` for QR code detection
- Handles camera permissions and error states

### Camera Permissions
The app automatically requests camera permissions with a descriptive message:
> "This app needs camera access to scan QR codes for payment processing."

### UI Features
- **Scan Button**: Toggles between "Scan QR Code" (blue) and "Stop Scanning" (red)
- **Preview Area**: Shows live camera feed when scanning
- **Result Display**: Shows scanned QR code content
- **Alert Dialog**: Displays results with options to copy or scan another

## Usage

1. Launch the app
2. Tap "Scan QR Code" to start scanning
3. Point camera at a QR code
4. The app will automatically detect and display the result
5. Choose to copy the result or scan another code

## Customization

### Changing Bundle Identifier
1. Select the project in Xcode
2. Go to project settings
3. Update "Bundle Identifier" under "Signing & Capabilities"

### Modifying UI
- Edit `Main.storyboard` to change the interface layout
- Customize colors, fonts, and spacing in the storyboard or `QRScannerViewController.swift`

### Adding Features
- Extend `QRScannerViewController` to add payment processing logic
- Add validation for specific QR code formats
- Implement data persistence for scanned codes

## Troubleshooting

### Camera Not Working
- Ensure you're testing on a physical device
- Check that camera permissions are granted in device Settings
- Verify the camera is not being used by another app

### Build Issues
- Make sure development team is selected
- Update bundle identifier to be unique
- Check iOS deployment target compatibility

### Runtime Issues
- Check device logs in Xcode console
- Ensure Info.plist contains camera usage description
- Verify all IBOutlets are properly connected

## Next Steps

This is a basic QR scanner that you can extend for payment processing:

1. **Add Payment Logic**: Integrate with payment APIs
2. **Validate QR Codes**: Add validation for payment-specific QR formats
3. **Security**: Implement encryption and secure data handling
4. **UI Enhancement**: Add animations and improved visual feedback
5. **Testing**: Add unit tests and UI tests

## License

This is a sample project created for demonstration purposes.