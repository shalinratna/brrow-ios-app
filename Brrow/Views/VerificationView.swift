//
//  VerificationView.swift
//  Brrow
//
//  Created by Claude on 1/6/25.
//

import SwiftUI
import AVFoundation
import CoreImage.CIFilterBuiltins
import Combine

struct VerificationView: View {
    let meetup: Meetup
    let onVerificationComplete: ((VerificationResult) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var meetupService = MeetupService.shared

    @State private var selectedTab = 0
    @State private var showError = false
    @State private var errorMessage = ""

    var isSeller: Bool {
        AuthManager.shared.currentUser?.id == meetup.sellerId
    }

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // PIN Tab
                PINVerificationView(
                    meetup: meetup,
                    isSeller: isSeller,
                    onVerificationComplete: { result in
                        onVerificationComplete?(result)
                    }
                )
                .tabItem {
                    Label("PIN Code", systemImage: "number")
                }
                .tag(0)

                // QR Tab
                QRVerificationView(
                    meetup: meetup,
                    isSeller: isSeller,
                    onVerificationComplete: { result in
                        onVerificationComplete?(result)
                    }
                )
                .tabItem {
                    Label("QR Code", systemImage: "qrcode")
                }
                .tag(1)
            }
            .navigationTitle(isSeller ? "Show Code" : "Verify Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.text)
                }
            }
        }
    }
}

// MARK: - PIN Verification View
struct PINVerificationView: View {
    let meetup: Meetup
    let isSeller: Bool
    let onVerificationComplete: ((VerificationResult) -> Void)?

    @StateObject private var meetupService = MeetupService.shared
    @State private var generatedCode: VerificationCode?
    @State private var pinInput = ""
    @State private var isGenerating = false
    @State private var isVerifying = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                if isSeller {
                    sellerView
                } else {
                    buyerView
                }
            }
            .padding(Theme.Spacing.md)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Success!", isPresented: $showSuccess) {
            Button("OK") {}
        } message: {
            Text("Verification successful! Payment has been captured.")
        }
    }

    // MARK: - Seller View
    private var sellerView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Instructions
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "number.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Theme.Colors.primary)

                Text("Generate a PIN code")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.text)

                Text("Share this 4-digit code with the buyer to complete verification.")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            // Generated PIN Display
            if let code = generatedCode, !code.isExpired {
                VStack(spacing: Theme.Spacing.md) {
                    Text("Your PIN Code:")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.secondaryText)

                    Text(code.codeValue)
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.primary)
                        .tracking(8)

                    // Expiration time
                    let timeRemaining = code.expiresAt.timeIntervalSince(Date())
                    if timeRemaining > 0 {
                        HStack {
                            Image(systemName: "clock")
                            Text("Expires in \(Int(timeRemaining / 60)) minutes")
                        }
                        .font(Theme.Typography.footnote)
                        .foregroundColor(Theme.Colors.secondaryText)
                    } else {
                        Text("Code expired")
                            .font(Theme.Typography.footnote)
                            .foregroundColor(Theme.Colors.error)
                    }
                }
                .padding(Theme.Spacing.lg)
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(Theme.CornerRadius.card)
            }

            // Generate Button
            Button(action: generatePIN) {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text(generatedCode == nil ? "Generate PIN" : "Generate New PIN")
                    }
                }
            }
            .primaryButtonStyle()
            .disabled(isGenerating)
        }
    }

    // MARK: - Buyer View
    private var buyerView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Instructions
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "number.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Theme.Colors.primary)

                Text("Enter PIN Code")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.text)

                Text("Enter the 4-digit code shown by the seller.")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            // PIN Input
            VStack(spacing: Theme.Spacing.md) {
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(0..<4) { index in
                        Text(pinInput.count > index ? String(pinInput[pinInput.index(pinInput.startIndex, offsetBy: index)]) : "")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.text)
                            .frame(width: 60, height: 80)
                            .background(Theme.Colors.secondaryBackground)
                            .cornerRadius(Theme.CornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                    .stroke(pinInput.count == index ? Theme.Colors.primary : Theme.Colors.border, lineWidth: 2)
                            )
                    }
                }

                // Hidden TextField for keyboard input
                TextField("", text: $pinInput)
                    .keyboardType(.numberPad)
                    .frame(width: 0, height: 0)
                    .opacity(0)
                    .onChange(of: pinInput) { newValue in
                        // Limit to 4 digits
                        if newValue.count > 4 {
                            pinInput = String(newValue.prefix(4))
                        }
                    }
            }

            // Number Pad
            numberPadView

            // Verify Button
            Button(action: verifyPIN) {
                if isVerifying {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Verify PIN")
                }
            }
            .primaryButtonStyle()
            .disabled(pinInput.count != 4 || isVerifying)
            .opacity(pinInput.count != 4 ? 0.5 : 1.0)
        }
    }

    // MARK: - Number Pad
    private var numberPadView: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(0..<3) { row in
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(1..<4) { col in
                        let number = row * 3 + col
                        Button(action: {
                            if pinInput.count < 4 {
                                pinInput += "\(number)"
                            }
                        }) {
                            Text("\(number)")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                                .frame(width: 70, height: 70)
                                .background(Theme.Colors.secondaryBackground)
                                .cornerRadius(Theme.CornerRadius.md)
                        }
                    }
                }
            }

            // Bottom row: Clear, 0, Delete
            HStack(spacing: Theme.Spacing.sm) {
                Button(action: {
                    pinInput = ""
                }) {
                    Text("Clear")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.text)
                        .frame(width: 70, height: 70)
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(Theme.CornerRadius.md)
                }

                Button(action: {
                    if pinInput.count < 4 {
                        pinInput += "0"
                    }
                }) {
                    Text("0")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                        .frame(width: 70, height: 70)
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(Theme.CornerRadius.md)
                }

                Button(action: {
                    if !pinInput.isEmpty {
                        pinInput.removeLast()
                    }
                }) {
                    Image(systemName: "delete.left")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.text)
                        .frame(width: 70, height: 70)
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(Theme.CornerRadius.md)
                }
            }
        }
    }

    // MARK: - Helper Functions
    private func generatePIN() {
        isGenerating = true

        meetupService.generateVerificationCode(meetupId: meetup.id, codeType: .pinCode)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isGenerating = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                },
                receiveValue: { code in
                    generatedCode = code
                }
            )
            .store(in: &cancellables)
    }

    private func verifyPIN() {
        isVerifying = true

        meetupService.verifyCode(meetupId: meetup.id, codeValue: pinInput)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isVerifying = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                },
                receiveValue: { result in
                    showSuccess = true
                    onVerificationComplete?(result)
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - QR Verification View
struct QRVerificationView: View {
    let meetup: Meetup
    let isSeller: Bool
    let onVerificationComplete: ((VerificationResult) -> Void)?

    @StateObject private var meetupService = MeetupService.shared
    @State private var generatedCode: VerificationCode?
    @State private var qrCodeImage: UIImage?
    @State private var isGenerating = false
    @State private var isVerifying = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var showScanner = false

    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                if isSeller {
                    sellerView
                } else {
                    buyerView
                }
            }
            .padding(Theme.Spacing.md)
        }
        .sheet(isPresented: $showScanner) {
            QRScannerView { scannedCode in
                showScanner = false
                verifyQRCode(scannedCode)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Success!", isPresented: $showSuccess) {
            Button("OK") {}
        } message: {
            Text("Verification successful! Payment has been captured.")
        }
    }

    // MARK: - Seller View
    private var sellerView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Instructions
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "qrcode")
                    .font(.system(size: 64))
                    .foregroundColor(Theme.Colors.primary)

                Text("Generate a QR Code")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.text)

                Text("Show this QR code to the buyer to complete verification.")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            // QR Code Display
            if let image = qrCodeImage, let code = generatedCode, !code.isExpired {
                VStack(spacing: Theme.Spacing.md) {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding(Theme.Spacing.md)
                        .background(Color.white)
                        .cornerRadius(Theme.CornerRadius.card)

                    // Expiration time
                    let timeRemaining = code.expiresAt.timeIntervalSince(Date())
                    if timeRemaining > 0 {
                        HStack {
                            Image(systemName: "clock")
                            Text("Expires in \(Int(timeRemaining / 60)) minutes")
                        }
                        .font(Theme.Typography.footnote)
                        .foregroundColor(Theme.Colors.secondaryText)
                    } else {
                        Text("Code expired")
                            .font(Theme.Typography.footnote)
                            .foregroundColor(Theme.Colors.error)
                    }
                }
            }

            // Generate Button
            Button(action: generateQRCode) {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text(generatedCode == nil ? "Generate QR Code" : "Generate New Code")
                    }
                }
            }
            .primaryButtonStyle()
            .disabled(isGenerating)
        }
    }

    // MARK: - Buyer View
    private var buyerView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Instructions
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 64))
                    .foregroundColor(Theme.Colors.primary)

                Text("Scan QR Code")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.text)

                Text("Scan the QR code shown by the seller to complete verification.")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            // Scan Button
            Button(action: {
                showScanner = true
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Open QR Scanner")
                }
            }
            .primaryButtonStyle()
        }
    }

    // MARK: - Helper Functions
    private func generateQRCode() {
        isGenerating = true

        meetupService.generateVerificationCode(meetupId: meetup.id, codeType: .qrCode)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isGenerating = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                },
                receiveValue: { code in
                    generatedCode = code
                    qrCodeImage = generateQRCodeImage(from: code.codeValue)
                }
            )
            .store(in: &cancellables)
    }

    private func generateQRCodeImage(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(string.utf8)
        filter.correctionLevel = "H"

        if let outputImage = filter.outputImage {
            let scaleX = 250 / outputImage.extent.width
            let scaleY = 250 / outputImage.extent.height
            let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

            if let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }

    private func verifyQRCode(_ code: String) {
        isVerifying = true

        meetupService.verifyCode(meetupId: meetup.id, codeValue: code)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isVerifying = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                },
                receiveValue: { result in
                    showSuccess = true
                    onVerificationComplete?(result)
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - QR Scanner View
struct QRScannerView: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onCodeScanned = onCodeScanned
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var onCodeScanned: ((String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning QR codes.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }

        dismiss(animated: true)
    }

    func found(code: String) {
        onCodeScanned?(code)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

// MARK: - Preview
struct VerificationView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Preview not available - requires real meetup data")
    }
}
