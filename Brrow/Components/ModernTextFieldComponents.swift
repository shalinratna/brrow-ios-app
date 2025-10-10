//
//  ModernTextFieldComponents.swift
//  Brrow
//
//  Shared text field components for modern UI
//

import SwiftUI

struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    let keyboardType: UIKeyboardType
    let isValid: Bool
    var textContentType: UITextContentType? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .default))
                .foregroundColor(Theme.Colors.text)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(text.isEmpty ? Theme.Colors.secondaryText.opacity(0.6) : Theme.Colors.primary)
                    .frame(width: 24)

                TextField(placeholder, text: $text)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(Theme.Colors.text)
                    .textContentType(textContentType)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.Colors.surface)
                    .shadow(color: Theme.Colors.primary.opacity(text.isEmpty ? 0 : 0.08), radius: 6, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: text.isEmpty ? 1 : 2)
            )
            .keyboardType(keyboardType)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: text)
        }
    }

    private var borderColor: Color {
        if text.isEmpty {
            return Theme.Colors.border
        } else if isValid {
            return Theme.Colors.primary.opacity(0.6)
        } else {
            return Theme.Colors.error
        }
    }
}

struct ModernSecureField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    @Binding var showPassword: Bool
    let isValid: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(.system(size: 15, weight: .medium, design: .default))
                .foregroundColor(Theme.Colors.text)

            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "lock.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(text.isEmpty ? Theme.Colors.secondaryText : Theme.Colors.primary)
                    .frame(width: 20)

                Group {
                    if showPassword {
                        TextField(placeholder, text: $text)
                            .textContentType(.password)
                    } else {
                        SecureField(placeholder, text: $text)
                            .textContentType(.password)
                    }
                }
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(Theme.Colors.text)

                Button(action: {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        showPassword.toggle()
                    }
                }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .cornerRadius(Theme.CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: text)
        }
    }

    private var borderColor: Color {
        if text.isEmpty {
            return Theme.Colors.border
        } else if isValid {
            return Theme.Colors.primary.opacity(0.6)
        } else {
            return Theme.Colors.error
        }
    }
}
