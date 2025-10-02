import SwiftUI

struct TwoFactorSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiClient = APIClient.shared
    @AppStorage("userToken") private var userToken: String = ""

    @State private var qrCodeImage: UIImage?
    @State private var manualEntryKey: String = ""
    @State private var verificationCode: String = ""
    @State private var backupCodes: [String] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var currentStep: SetupStep = .generate
    @State private var showBackupCodes = false
    @State private var copiedBackupCodes = false

    enum SetupStep {
        case generate, verify, complete
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Two-Factor Authentication")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Add an extra layer of security to your account")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)

                    // Content based on current step
                    switch currentStep {
                    case .generate:
                        generateQRView
                    case .verify:
                        verifyCodeView
                    case .complete:
                        backupCodesView
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if currentStep == .generate && qrCodeImage == nil {
                setupTwoFactor()
            }
        }
    }

    // MARK: - Generate QR Code View

    private var generateQRView: some View {
        VStack(spacing: 20) {
            Text("Step 1: Scan QR Code")
                .font(.headline)

            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            } else if let qrImage = qrCodeImage {
                VStack(spacing: 16) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(radius: 5)

                    VStack(spacing: 12) {
                        Text("Scan this QR code with your authenticator app")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Text("Recommended apps:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 16) {
                            AppBadge(name: "Google Authenticator")
                            AppBadge(name: "Authy")
                            AppBadge(name: "Microsoft Authenticator")
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Can't scan? Enter this key manually:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            Text(manualEntryKey)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)

                            Button(action: {
                                UIPasteboard.general.string = manualEntryKey
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    Button(action: {
                        currentStep = .verify
                    }) {
                        Text("Next: Verify Code")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.top)
                }
            } else {
                Button(action: setupTwoFactor) {
                    Text("Generate QR Code")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Verify Code View

    private var verifyCodeView: some View {
        VStack(spacing: 20) {
            Text("Step 2: Verify Code")
                .font(.headline)

            Text("Enter the 6-digit code from your authenticator app")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            TextField("000000", text: $verificationCode)
                .keyboardType(.numberPad)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 200)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .onChange(of: verificationCode) { newValue in
                    // Auto-submit when 6 digits are entered
                    if newValue.count == 6 {
                        verifyTwoFactor()
                    }
                }

            if isLoading {
                ProgressView()
                    .padding()
            } else {
                VStack(spacing: 12) {
                    Button(action: verifyTwoFactor) {
                        Text("Verify & Enable 2FA")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(verificationCode.count == 6 ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(verificationCode.count != 6)

                    Button(action: {
                        currentStep = .generate
                        verificationCode = ""
                    }) {
                        Text("Back to QR Code")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }

    // MARK: - Backup Codes View

    private var backupCodesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("2FA Enabled Successfully!")
                .font(.title2)
                .fontWeight(.bold)

            Text("Save these backup codes in a safe place. You can use them to access your account if you lose your authenticator device.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(backupCodes, id: \.self) { code in
                    Text(code)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.vertical)

            HStack(spacing: 12) {
                Button(action: {
                    let codesText = backupCodes.joined(separator: "\n")
                    UIPasteboard.general.string = codesText
                    copiedBackupCodes = true
                }) {
                    HStack {
                        Image(systemName: copiedBackupCodes ? "checkmark" : "doc.on.doc")
                        Text(copiedBackupCodes ? "Copied!" : "Copy All")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }

                Button(action: {
                    shareBackupCodes()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }

            Button(action: {
                dismiss()
            }) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.top)
        }
    }

    // MARK: - Helper Views

    private struct AppBadge: View {
        let name: String

        var body: some View {
            Text(name)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(4)
        }
    }

    // MARK: - API Methods

    private func setupTwoFactor() {
        isLoading = true
        errorMessage = ""

        Task {
            do {
                let response = try await apiClient.setupTwoFactor()

                await MainActor.run {
                    isLoading = false

                    if let data = response.data {
                        if let imageData = Data(base64Encoded: data.qrCode.replacingOccurrences(of: "data:image/png;base64,", with: "")),
                           let image = UIImage(data: imageData) {
                            self.qrCodeImage = image
                        }

                        self.manualEntryKey = data.secret
                        self.backupCodes = data.backupCodes
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func verifyTwoFactor() {
        isLoading = true
        errorMessage = ""

        Task {
            do {
                let response = try await apiClient.verifyTwoFactor(code: verificationCode)

                await MainActor.run {
                    isLoading = false

                    if response.success {
                        // Note: Backend should return backup codes in setupTwoFactor, not verifyTwoFactor
                        // For now, we'll show completion
                        self.currentStep = .complete
                    } else {
                        errorMessage = response.message ?? "Verification failed"
                        verificationCode = ""
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    verificationCode = ""
                }
            }
        }
    }

    private func shareBackupCodes() {
        let codesText = "Brrow 2FA Backup Codes\n\n" + backupCodes.joined(separator: "\n")

        let activityVC = UIActivityViewController(
            activityItems: [codesText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

#Preview {
    TwoFactorSetupView()
}
