import Foundation
import Combine

class ForgotPasswordViewModel: ObservableObject {
    @Published var email = ""
    @Published var isLoading = false
    @Published var showSuccessAlert = false
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    @Published var emailError: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Validate email as user types
        $email
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] email in
                self?.validateEmail(email)
            }
            .store(in: &cancellables)
    }
    
    private func validateEmail(_ email: String) {
        if email.isEmpty {
            emailError = nil
        } else if !isValidEmail(email) {
            emailError = "Please enter a valid email address"
        } else {
            emailError = nil
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPred.evaluate(with: email)
    }
    
    func sendResetLink() {
        guard !email.isEmpty, emailError == nil else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await APIClient.shared.requestPasswordReset(email: email)

                await MainActor.run {
                    self.isLoading = false
                    self.showSuccessAlert = true
                    HapticManager.notification(type: .success)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                    HapticManager.notification(type: .error)
                }
            }
        }
    }
}

class ResetPasswordViewModel: ObservableObject {
    @Published var email = ""
    @Published var resetCode = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var showSuccessAlert = false
    @Published var errorMessage: String?

    @Published var passwordValidation = PasswordValidation()

    private var cancellables = Set<AnyCancellable>()
    
    var isValid: Bool {
        !resetCode.isEmpty &&
        passwordValidation.isValid &&
        newPassword == confirmPassword
    }
    
    init() {
        // Validate password as user types
        $newPassword
            .sink { [weak self] password in
                self?.validatePassword(password)
            }
            .store(in: &cancellables)
        
        // Check if passwords match
        Publishers.CombineLatest($newPassword, $confirmPassword)
            .sink { [weak self] (password, confirm) in
                if !confirm.isEmpty && password != confirm {
                    self?.errorMessage = "Passwords do not match"
                } else {
                    self?.errorMessage = nil
                }
            }
            .store(in: &cancellables)
    }
    
    private func validatePassword(_ password: String) {
        passwordValidation.hasMinLength = password.count >= 8
        passwordValidation.hasUppercase = password.contains(where: { $0.isUppercase })
        passwordValidation.hasLowercase = password.contains(where: { $0.isLowercase })
        passwordValidation.hasNumber = password.contains(where: { $0.isNumber })
        passwordValidation.isValid = passwordValidation.hasMinLength &&
                                    passwordValidation.hasUppercase &&
                                    passwordValidation.hasLowercase &&
                                    passwordValidation.hasNumber
    }
    
    func resetPassword() {
        guard isValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await APIClient.shared.resetPassword(
                    email: email,
                    token: resetCode,
                    newPassword: newPassword
                )

                await MainActor.run {
                    self.isLoading = false
                    self.showSuccessAlert = true
                    HapticManager.notification(type: .success)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    HapticManager.notification(type: .error)
                }
            }
        }
    }
    
    func resendCode(email: String) {
        Task {
            do {
                _ = try await APIClient.shared.requestPasswordReset(email: email)
                HapticManager.notification(type: .success)
            } catch {
                print("Failed to resend code: \(error)")
            }
        }
    }
}

struct PasswordValidation {
    var hasMinLength = false
    var hasUppercase = false
    var hasLowercase = false
    var hasNumber = false
    var isValid = false
}