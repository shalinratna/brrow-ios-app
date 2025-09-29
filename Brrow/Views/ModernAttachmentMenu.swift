//
//  ModernAttachmentMenu.swift
//  Brrow
//
//  Enhanced attachment menu with smooth animations
//

import SwiftUI
import PhotosUI

struct ModernAttachmentMenu: View {
    let onSelection: (ModernAttachmentType) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isVisible = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingLocationPicker = false

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissMenu()
                }
                .opacity(isVisible ? 1 : 0)

            // Menu content
            VStack {
                Spacer()

                VStack(spacing: 0) {
                    // Handle indicator
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 36, height: 5)
                        .padding(.top, 12)
                        .padding(.bottom, 20)

                    // Menu title
                    Text("Add to message")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.bottom, 24)

                    // Attachment options
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 20) {
                        AttachmentOption(
                            icon: "photo.on.rectangle",
                            title: "Photo",
                            subtitle: "From library",
                            color: .blue,
                            action: {
                                selectedPhoto = nil
                                // Will trigger PhotosPicker
                            }
                        )

                        AttachmentOption(
                            icon: "camera.fill",
                            title: "Camera",
                            subtitle: "Take photo",
                            color: .green,
                            action: {
                                showingCamera = true
                            }
                        )

                        AttachmentOption(
                            icon: "location.fill",
                            title: "Location",
                            subtitle: "Share location",
                            color: .red,
                            action: {
                                showingLocationPicker = true
                            }
                        )

                        AttachmentOption(
                            icon: "doc.fill",
                            title: "Document",
                            subtitle: "PDF, files",
                            color: .orange,
                            action: {
                                // Handle document selection
                                onSelection(ModernAttachmentType.document)
                                dismissMenu()
                            }
                        )

                        AttachmentOption(
                            icon: "gift.fill",
                            title: "Payment",
                            subtitle: "Send money",
                            color: .purple,
                            action: {
                                // Handle payment
                                onSelection(ModernAttachmentType.payment)
                                dismissMenu()
                            }
                        )

                        AttachmentOption(
                            icon: "calendar",
                            title: "Event",
                            subtitle: "Schedule meet",
                            color: .teal,
                            action: {
                                // Handle event scheduling
                                onSelection(ModernAttachmentType.event)
                                dismissMenu()
                            }
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)

                    // Cancel button
                    Button(action: dismissMenu) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
                )
                .offset(y: isVisible ? 0 : 400)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
            }
        }
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
        .photosPicker(isPresented: .constant(selectedPhoto == nil), selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { newValue in
            if newValue != nil {
                onSelection(ModernAttachmentType.photo)
                dismissMenu()
            }
        }
        .sheet(isPresented: $showingCamera) {
            ModernCameraView { image in
                // Handle camera image
                onSelection(ModernAttachmentType.camera)
                dismissMenu()
            }
        }
        .sheet(isPresented: $showingLocationPicker) {
            ModernLocationPicker { location in
                // Handle location
                onSelection(ModernAttachmentType.location)
                dismissMenu()
            }
        }
    }

    private func dismissMenu() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}

// MARK: - Attachment Option
struct AttachmentOption: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                action()
                isPressed = false
            }
        }) {
            VStack(spacing: 8) {
                // Icon container
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                }
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)

                // Text
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Extended Attachment Types
enum ModernAttachmentType {
    case photo
    case camera
    case location
    case document
    case payment
    case event
}

// MARK: - Modern Camera View
struct ModernCameraView: View {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            // Camera interface would go here
            Text("Camera View")
                .font(.title)
                .padding()

            Button("Cancel") {
                dismiss()
            }
        }
    }
}

// MARK: - Modern Location Picker
struct ModernLocationPicker: View {
    let onLocationSelected: (CLLocation) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            // Location picker interface would go here
            Text("Location Picker")
                .font(.title)
                .padding()

            Button("Cancel") {
                dismiss()
            }
        }
    }
}