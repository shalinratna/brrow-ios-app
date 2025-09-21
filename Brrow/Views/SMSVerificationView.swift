//
//  SMSVerificationView.swift
//  Brrow
//
//  Complete SMS verification interface with modern design
//

import SwiftUI

struct SMSVerificationView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var smsService = SMSVerificationService.shared

    @State private var phoneNumber: String = ""
    @State private var verificationCode: String = ""
    @State private var showingCodeEntry = false
    @State private var countdown = 60
    @State private var canResend = false
    @State private var timer: Timer?

    let onVerificationComplete: ((User) -> Void)?

    init(initialPhoneNumber: String = "", onVerificationComplete: ((User) -> Void)? = nil) {
        self._phoneNumber = State(initialValue: initialPhoneNumber)
        self.onVerificationComplete = onVerificationComplete
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header
                    headerSection

                    Spacer()

                    if !showingCodeEntry {
                        // Phone Number Entry
                        phoneNumberSection
                    } else {
                        // Verification Code Entry
                        verificationCodeSection
                    }

                    Spacer()

                    // Action Button
                    actionButton

                    // Error/Success Messages
                    if let errorMessage = smsService.errorMessage {
                        ErrorMessageView(message: errorMessage)
                    }

                    if let successMessage = smsService.successMessage {
                        SuccessMessageView(message: successMessage)
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .onReceive(smsService.$verificationSent) { sent in
            if sent {
                showingCodeEntry = true
                startCountdown()
            }
        }
        .onReceive(smsService.$verificationSuccessful) { successful in
            if successful {
                // Verification complete
                if let user = AuthManager.shared.currentUser {
                    onVerificationComplete?(user)
                }
                presentationMode.wrappedValue.dismiss()
            }
        }
        .onAppear {
            smsService.resetState()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Close button
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                        .frame(width: 36, height: 36)
                        .background(Theme.Colors.secondaryBackground)
                        .clipShape(Circle())
                }

                Spacer()
            }

            // Icon
            VStack(spacing: 12) {
                Image(systemName: showingCodeEntry ? "message.fill" : "phone.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)

                VStack(spacing: 8) {
                    Text(showingCodeEntry ? "Enter Verification Code" : "Verify Phone Number")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.text)

                    Text(showingCodeEntry ?
                         "We sent a verification code to \(formattedPhoneNumber)" :
                         "We'll send you a text with a verification code")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    // MARK: - Phone Number Section

    private var phoneNumberSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Phone Number")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.text)

                HStack {
                    Text("+1")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 12)

                    TextField("(555) 123-4567", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .font(.title2)
                        .onChange(of: phoneNumber) { _, newValue in
                            // Format phone number as user types
                            phoneNumber = formatPhoneNumberInput(newValue)
                        }
                }
                .padding()
                .background(Theme.Colors.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }

            Text("Standard message and data rates may apply")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Verification Code Section

    private var verificationCodeSection: some View {
        VStack(spacing: 20) {
            // Code input
            VStack(alignment: .leading, spacing: 8) {
                Text("Verification Code")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.text)

                TextField("Enter 6-digit code", text: $verificationCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                    .onChange(of: verificationCode) { _, newValue in
                        // Limit to 6 digits
                        if newValue.count > 6 {
                            verificationCode = String(newValue.prefix(6))
                        }
                        // Auto-verify when 6 digits entered
                        if newValue.count == 6 {
                            Task {
                                await verifyCode()
                            }
                        }
                    }
            }

            // Resend section
            HStack {
                Text("Didn't receive a code?")
                    .foregroundColor(.secondary)

                if canResend {
                    Button("Resend") {
                        Task {
                            await sendVerificationCode()
                        }
                    }
                    .foregroundColor(.blue)
                } else {
                    Text("Resend in \(countdown)s")
                        .foregroundColor(.secondary)
                }
            }
            .font(.subheadline)

            // Change number
            Button("Change Phone Number") {
                showingCodeEntry = false
                verificationCode = ""
                smsService.resetState()
                timer?.invalidate()
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button(action: {
            Task {
                if showingCodeEntry {
                    await verifyCode()
                } else {
                    await sendVerificationCode()
                }
            }
        }) {
            HStack {
                if smsService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(showingCodeEntry ? "Verify Code" : "Send Code")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(actionButtonColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!isActionButtonEnabled)
    }

    // MARK: - Helper Views

    private var actionButtonColor: Color {
        isActionButtonEnabled ? .blue : .gray
    }

    private var isActionButtonEnabled: Bool {
        if smsService.isLoading {
            return false
        }

        if showingCodeEntry {
            return verificationCode.count >= 4
        } else {
            return smsService.isValidPhoneNumber(formattedPhoneNumber)
        }
    }

    private var formattedPhoneNumber: String {
        smsService.formatPhoneNumber(phoneNumber)
    }

    // MARK: - Actions

    private func sendVerificationCode() async {
        do {
            try await smsService.sendVerificationCode(to: formattedPhoneNumber)
        } catch {
            // Error handling is done in the service
        }
    }

    private func verifyCode() async {
        do {
            try await smsService.verifyCode(verificationCode, for: formattedPhoneNumber)
        } catch {
            // Error handling is done in the service
        }
    }

    private func startCountdown() {
        countdown = 60
        canResend = false

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1
            } else {
                canResend = true
                timer?.invalidate()
            }
        }
    }

    private func formatPhoneNumberInput(_ input: String) -> String {
        // Remove all non-numeric characters
        let numbers = input.filter { $0.isNumber }

        // Limit to 10 digits
        let limited = String(numbers.prefix(10))

        // Format as (XXX) XXX-XXXX
        let formatted = limited.formattedPhoneNumber()
        return formatted
    }
}

// MARK: - Supporting Views

struct ErrorMessageView: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .foregroundColor(.red)
                .font(.subheadline)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SuccessMessageView: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(message)
                .foregroundColor(.green)
                .font(.subheadline)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - String Extension

extension String {
    func formattedPhoneNumber() -> String {
        let numbers = self.filter { $0.isNumber }

        switch numbers.count {
        case 0...3:
            return numbers
        case 4...6:
            let first = String(numbers.prefix(3))
            let second = String(numbers.dropFirst(3))
            return "(\(first)) \(second)"
        case 7...10:
            let first = String(numbers.prefix(3))
            let second = String(numbers.dropFirst(3).prefix(3))
            let third = String(numbers.dropFirst(6))
            return "(\(first)) \(second)-\(third)"
        default:
            return numbers
        }
    }
}

// MARK: - Preview

struct SMSVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        SMSVerificationView()
    }
}