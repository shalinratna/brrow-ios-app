//
//  PasswordStrengthIndicator.swift
//  Brrow
//
//  Password strength indicator with real-time validation
//

import SwiftUI

struct PasswordStrength {
    let level: Level
    let percentage: CGFloat
    let color: Color
    let message: String

    enum Level: String {
        case weak = "Weak"
        case fair = "Fair"
        case good = "Good"
        case strong = "Strong"
    }

    static func evaluate(_ password: String) -> PasswordStrength {
        var score = 0
        var checks = 0

        // Length check
        if password.count >= 8 {
            score += 1
            checks += 1
        }
        if password.count >= 12 {
            score += 1
        }
        if password.count >= 16 {
            score += 1
        }

        // Character variety
        if password.range(of: "[A-Z]", options: .regularExpression) != nil {
            score += 1
            checks += 1
        }

        if password.range(of: "[a-z]", options: .regularExpression) != nil {
            score += 1
            checks += 1
        }

        if password.range(of: "[0-9]", options: .regularExpression) != nil {
            score += 1
            checks += 1
        }

        if password.range(of: "[!@#$%^&*()_+\\-=\\[\\]{}|;:,.<>?]", options: .regularExpression) != nil {
            score += 1
            checks += 1
        }

        // Additional complexity
        let numbers = password.filter { $0.isNumber }
        if numbers.count >= 2 {
            score += 1
        }

        // Determine level
        let level: Level
        let color: Color
        let message: String
        let percentage: CGFloat

        if score < 4 {
            level = .weak
            color = .red
            message = "Too weak - add more characters"
            percentage = 0.25
        } else if score < 6 {
            level = .fair
            color = .orange
            message = "Fair - consider adding more variety"
            percentage = 0.50
        } else if score < 8 {
            level = .good
            color = .yellow
            message = "Good password"
            percentage = 0.75
        } else {
            level = .strong
            color = .green
            message = "Strong password"
            percentage = 1.0
        }

        return PasswordStrength(level: level, percentage: percentage, color: color, message: message)
    }
}

struct PasswordRequirements {
    var minLength: Bool = false
    var hasUppercase: Bool = false
    var hasLowercase: Bool = false
    var hasNumber: Bool = false
    var hasSpecialChar: Bool = false

    var allMet: Bool {
        minLength && hasUppercase && hasLowercase && hasNumber && hasSpecialChar
    }

    static func check(_ password: String) -> PasswordRequirements {
        var requirements = PasswordRequirements()

        requirements.minLength = password.count >= 8
        requirements.hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        requirements.hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        requirements.hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        requirements.hasSpecialChar = password.range(of: "[!@#$%^&*()_+\\-=\\[\\]{}|;:,.<>?]", options: .regularExpression) != nil

        return requirements
    }
}

struct PasswordStrengthIndicator: View {
    let password: String
    let showRequirements: Bool

    init(password: String, showRequirements: Bool = true) {
        self.password = password
        self.showRequirements = showRequirements
    }

    private var strength: PasswordStrength {
        PasswordStrength.evaluate(password)
    }

    private var requirements: PasswordRequirements {
        PasswordRequirements.check(password)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Strength bar
            if !password.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Password Strength:")
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.secondaryText)

                        Spacer()

                        Text(strength.level.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(strength.color)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)

                            // Progress
                            RoundedRectangle(cornerRadius: 4)
                                .fill(strength.color)
                                .frame(width: geometry.size.width * strength.percentage, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: strength.percentage)
                        }
                    }
                    .frame(height: 8)

                    Text(strength.message)
                        .font(.caption)
                        .foregroundColor(strength.color)
                }
                .padding(.bottom, 8)
            }

            // Requirements checklist
            if showRequirements {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Requirements:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.text)

                    RequirementRow(
                        text: "At least 8 characters",
                        met: requirements.minLength
                    )

                    RequirementRow(
                        text: "One uppercase letter",
                        met: requirements.hasUppercase
                    )

                    RequirementRow(
                        text: "One lowercase letter",
                        met: requirements.hasLowercase
                    )

                    RequirementRow(
                        text: "One number",
                        met: requirements.hasNumber
                    )

                    RequirementRow(
                        text: "One special character (!@#$%^&*)",
                        met: requirements.hasSpecialChar
                    )
                }
                .padding(12)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
}

struct RequirementRow: View {
    let text: String
    let met: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundColor(met ? .green : .gray)
                .font(.system(size: 16))

            Text(text)
                .font(.caption)
                .foregroundColor(met ? Theme.Colors.text : Theme.Colors.secondaryText)
        }
    }
}

// MARK: - Secure Text Field with Show/Hide Toggle
struct SecureInputField: View {
    let title: String
    @Binding var text: String
    @State private var isSecure: Bool = true
    let placeholder: String

    init(_ title: String, text: Binding<String>, placeholder: String = "") {
        self.title = title
        self._text = text
        self.placeholder = placeholder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Theme.Colors.text)

            HStack {
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .textFieldStyle(PlainTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)

                Button(action: {
                    isSecure.toggle()
                }) {
                    Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
            }
            .padding(12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PasswordStrengthIndicator(password: "weak", showRequirements: true)

        PasswordStrengthIndicator(password: "Better123", showRequirements: true)

        PasswordStrengthIndicator(password: "VeryStrong123!@#", showRequirements: true)
    }
    .padding()
}
