import SwiftUI

struct TwoFactorInputView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiClient = APIClient.shared

    let userId: String
    let onSuccess: (String) -> Void

    @State private var code: String = ""
    @State private var backupCode: String = ""
    @State private var useBackupCode = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showBackupCodeInfo = false

    @FocusState private var isCodeFieldFocused: Bool

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

                        Text("Enter the code from your authenticator app")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)

                    // Code Input
                    if !useBackupCode {
                        VStack(spacing: 16) {
                            TextField("000000", text: $code)
                                .keyboardType(.numberPad)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 250)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .focused($isCodeFieldFocused)
                                .onChange(of: code) { newValue in
                                    // Filter to only numbers
                                    code = String(newValue.filter { $0.isNumber }.prefix(6))

                                    // Auto-submit when 6 digits are entered
                                    if code.count == 6 {
                                        verifyCode()
                                    }
                                }

                            // Character indicators
                            HStack(spacing: 8) {
                                ForEach(0..<6, id: \.self) { index in
                                    Circle()
                                        .fill(index < code.count ? Color.blue : Color.gray.opacity(0.3))
                                        .frame(width: 12, height: 12)
                                }
                            }
                        }
                    } else {
                        // Backup Code Input
                        VStack(spacing: 16) {
                            Text("Enter Backup Code")
                                .font(.headline)

                            TextField("XXXX-XXXX", text: $backupCode)
                                .textCase(.uppercase)
                                .autocorrectionDisabled()
                                .font(.system(size: 24, weight: .semibold, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .focused($isCodeFieldFocused)
                        }
                    }

                    // Error Message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }

                    // Action Buttons
                    VStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                        } else {
                            Button(action: verifyCode) {
                                Text("Verify")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(canSubmit ? Color.blue : Color.gray)
                                    .cornerRadius(12)
                            }
                            .disabled(!canSubmit)

                            Divider()
                                .padding(.vertical)

                            // Backup Code Toggle
                            Button(action: {
                                useBackupCode.toggle()
                                code = ""
                                backupCode = ""
                                errorMessage = ""
                                isCodeFieldFocused = true
                            }) {
                                HStack {
                                    Image(systemName: useBackupCode ? "key.fill" : "questionmark.circle")
                                    Text(useBackupCode ? "Use Authenticator Code" : "Use Backup Code")
                                }
                                .foregroundColor(.blue)
                            }

                            if useBackupCode {
                                Button(action: {
                                    showBackupCodeInfo = true
                                }) {
                                    HStack {
                                        Image(systemName: "info.circle")
                                        Text("What are backup codes?")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.top)

                    Spacer()
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
            .sheet(isPresented: $showBackupCodeInfo) {
                BackupCodeInfoSheet()
            }
            .onAppear {
                isCodeFieldFocused = true
            }
        }
    }

    private var canSubmit: Bool {
        if useBackupCode {
            return !backupCode.isEmpty
        } else {
            return code.count == 6
        }
    }

    private func verifyCode() {
        guard canSubmit else { return }

        isLoading = true
        errorMessage = ""
        isCodeFieldFocused = false

        let codeToVerify = useBackupCode ? nil : code
        let backupCodeToVerify = useBackupCode ? backupCode : nil

        apiClient.verifyTwoFactorLogin(
            userId: userId,
            code: codeToVerify,
            backupCode: backupCodeToVerify
        ) { result in
            DispatchQueue.main.async {
                isLoading = false

                switch result {
                case .success(let response):
                    if let token = response["token"] as? String {
                        onSuccess(token)
                        dismiss()
                    } else {
                        errorMessage = "Invalid response from server"
                    }

                case .failure(let error):
                    errorMessage = error.localizedDescription
                    code = ""
                    backupCode = ""
                    isCodeFieldFocused = true
                }
            }
        }
    }
}

// MARK: - Backup Code Info Sheet

struct BackupCodeInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: "key.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Backup Codes")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Your safety net for 2FA")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom)

                    VStack(alignment: .leading, spacing: 16) {
                        InfoSection(
                            icon: "questionmark.circle.fill",
                            title: "What are backup codes?",
                            description: "Backup codes are one-time use codes that you can use to access your account if you lose access to your authenticator app."
                        )

                        InfoSection(
                            icon: "shield.lefthalf.filled",
                            title: "When to use them?",
                            description: "Use a backup code if you've lost your phone, switched devices, or can't access your authenticator app for any reason."
                        )

                        InfoSection(
                            icon: "exclamationmark.triangle.fill",
                            title: "Important",
                            description: "Each backup code can only be used once. After using a code, it becomes invalid. Make sure to save your backup codes in a secure location."
                        )

                        InfoSection(
                            icon: "arrow.clockwise",
                            title: "Generate new codes",
                            description: "You can generate a new set of backup codes at any time from your security settings. This will invalidate all previous backup codes."
                        )
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InfoSection: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    TwoFactorInputView(userId: "test-user-id") { token in
        print("Success: \(token)")
    }
}
