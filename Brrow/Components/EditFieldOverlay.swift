//
//  EditFieldOverlay.swift
//  Brrow
//
//  Created by Claude Code on 11/13/25.
//

import SwiftUI

/// Main overlay container for inline field editing
struct EditFieldOverlay: View {
    let field: EditableField
    @ObservedObject var viewModel: InlineEditViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        ZStack {
            // Blurred background - tap to dismiss
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.cancelEditing()
                }

            // Editor card
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Edit \(field.displayName)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.Colors.text)

                    Spacer()

                    Button(action: {
                        viewModel.cancelEditing()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .frame(width: 32, height: 32)
                            .background(Theme.Colors.secondaryBackground)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.md)

                Divider()
                    .background(Theme.Colors.border)

                // Field-specific editor
                ScrollView {
                    editorContent
                        .padding(Theme.Spacing.lg)
                }
                .frame(minHeight: 200, maxHeight: .infinity) // Give more space to editor content

                Divider()
                    .background(Theme.Colors.border)

                // Save state indicator or action buttons
                saveSection
            }
            .background(Theme.Colors.background)
            .cornerRadius(Theme.CornerRadius.xl)
            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
            .padding(.horizontal, Theme.Spacing.md) // Reduced padding for more width
            .padding(.vertical, Theme.Spacing.xl) // Added vertical padding
            .frame(maxWidth: 700, maxHeight: .infinity) // Increased maxWidth and allow full height
        }
        .padding(.bottom, keyboardHeight) // Adjust for keyboard
        .transition(.scale(scale: 0.95).combined(with: .opacity))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.editingField)
        .onAppear {
            // Listen for keyboard notifications
            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillShowNotification,
                object: nil,
                queue: .main
            ) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation(.easeOut(duration: 0.3)) {
                        keyboardHeight = keyboardFrame.height * 0.3 // Adjust by 30% to give breathing room
                    }
                }
            }

            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    keyboardHeight = 0
                }
            }
        }
    }

    // MARK: - Editor Content

    @ViewBuilder
    private var editorContent: some View {
        switch field {
        case .title, .description, .tags:
            InlineTextEditor(field: field, viewModel: viewModel)

        case .price, .dailyRate, .securityDeposit:
            InlinePriceEditor(field: field, viewModel: viewModel)

        case .category, .condition:
            InlinePickerEditor(field: field, viewModel: viewModel)

        case .location:
            InlineLocationEditor(viewModel: viewModel)

        case .images:
            InlineImageCarouselEditor(viewModel: viewModel)

        case .deliveryOptions, .negotiable:
            InlineToggleEditor(field: field, viewModel: viewModel)
        }
    }

    // MARK: - Save Section

    @ViewBuilder
    private var saveSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Validation error
            if let validationError = viewModel.validate(field: field) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.error)

                    Text(validationError)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.error)

                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.sm)
            }

            // Save state message
            if let message = viewModel.saveState.message {
                HStack(spacing: Theme.Spacing.sm) {
                    switch viewModel.saveState {
                    case .saving:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primary))
                    case .saved:
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    case .error:
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.Colors.error)
                    case .idle:
                        EmptyView()
                    }

                    Text(message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(
                            viewModel.saveState == .error("") ? Theme.Colors.error :
                            viewModel.saveState == .saved ? .green :
                            Theme.Colors.text
                        )
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.sm)
            }

            // Action buttons
            HStack(spacing: Theme.Spacing.md) {
                Button(action: {
                    viewModel.cancelEditing()
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(Theme.CornerRadius.md)
                }

                Button(action: {
                    viewModel.saveEdit()
                }) {
                    HStack(spacing: 8) {
                        if viewModel.saveState == .saving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                        }

                        Text(viewModel.saveState == .saving ? "Saving..." : "Save")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        viewModel.validate(field: field) == nil ?
                        Theme.Colors.primary : Theme.Colors.secondaryText
                    )
                    .cornerRadius(Theme.CornerRadius.md)
                    .shadow(
                        color: viewModel.validate(field: field) == nil ?
                        Theme.Colors.primary.opacity(0.3) : .clear,
                        radius: 8,
                        y: 4
                    )
                }
                .disabled(viewModel.validate(field: field) != nil || viewModel.saveState == .saving)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
        }
    }
}
