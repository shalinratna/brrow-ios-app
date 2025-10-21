//
//  IdentityVerificationGuideView.swift
//  Brrow
//
//  Created by Claude on 1/21/25.
//  Interactive preparation screen with animated instructions
//

import SwiftUI

struct IdentityVerificationGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = IdentityVerificationGuideViewModel()
    @State private var currentStep = 0
    @State private var showingWebView = false

    private let steps: [GuideStep] = [
        GuideStep(
            icon: "doc.text.fill",
            title: "Get Your ID Ready",
            description: "Have your driver's license, passport, or government-issued ID card nearby",
            animation: .document
        ),
        GuideStep(
            icon: "sun.max.fill",
            title: "Find Good Lighting",
            description: "Make sure you're in a well-lit area so your ID and face are clearly visible",
            animation: .light
        ),
        GuideStep(
            icon: "camera.viewfinder",
            title: "Position Your Face",
            description: "Follow the on-screen guides to take a live selfie for verification",
            animation: .face
        )
    ]

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Theme.Colors.primary.opacity(0.03)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    ProgressBar(currentStep: currentStep, totalSteps: steps.count)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    TabView(selection: $currentStep) {
                        ForEach(steps.indices, id: \.self) { index in
                            GuideStepView(step: steps[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    // Navigation Buttons
                    VStack(spacing: 16) {
                        if currentStep < steps.count - 1 {
                            // Next button
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    currentStep += 1
                                }
                            }) {
                                Text("Next")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Theme.Colors.primary)
                                    .cornerRadius(16)
                            }
                        } else {
                            // Start Verification button
                            Button(action: {
                                viewModel.startVerification()
                            }) {
                                HStack(spacing: 12) {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Start Verification")
                                            .font(.system(size: 18, weight: .semibold))
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.system(size: 20))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                            }
                            .disabled(viewModel.isLoading)
                        }

                        // Skip button
                        Button(action: {
                            dismiss()
                        }) {
                            Text("I'll Do This Later")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if currentStep > 0 {
                            withAnimation(.spring(response: 0.3)) {
                                currentStep -= 1
                            }
                        } else {
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text(currentStep > 0 ? "Back" : "Cancel")
                        }
                        .foregroundColor(Theme.Colors.primary)
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $showingWebView) {
                if let url = viewModel.verificationURL {
                    IdentityVerificationWebView(verificationURL: url, sessionId: viewModel.sessionId ?? "")
                }
            }
            .onChange(of: viewModel.verificationURL) { url in
                if url != nil {
                    showingWebView = true
                }
            }
        }
    }
}

// MARK: - Guide Step View
struct GuideStepView: View {
    let step: GuideStep
    @State private var animateIcon = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Animated Icon
            ZStack {
                // Pulsing circles
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Theme.Colors.primary.opacity(0.2), lineWidth: 2)
                        .frame(width: 160 + CGFloat(index * 40), height: 160 + CGFloat(index * 40))
                        .scaleEffect(animateIcon ? 1.2 : 1.0)
                        .opacity(animateIcon ? 0.0 : 0.5)
                        .animation(
                            Animation.easeOut(duration: 2.0)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.3),
                            value: animateIcon
                        )
                }

                // Main icon container
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.Colors.primary.opacity(0.2),
                                    Theme.Colors.primary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)

                    step.animation.animatedView
                        .font(.system(size: 60))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            .frame(height: 280)

            // Text content
            VStack(spacing: 16) {
                Text(step.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(step.description)
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .onAppear {
            animateIcon = true
        }
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index <= currentStep ? Theme.Colors.primary : Color.gray.opacity(0.2))
                    .frame(height: 4)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Models
struct GuideStep {
    let icon: String
    let title: String
    let description: String
    let animation: AnimationType

    enum AnimationType {
        case document
        case light
        case face

        @ViewBuilder
        var animatedView: some View {
            switch self {
            case .document:
                DocumentAnimation()
            case .light:
                LightAnimation()
            case .face:
                FaceAnimation()
            }
        }
    }
}

// MARK: - Animations
struct DocumentAnimation: View {
    @State private var animate = false

    var body: some View {
        Image(systemName: "doc.text.fill")
            .rotationEffect(.degrees(animate ? 5 : -5))
            .animation(
                Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                value: animate
            )
            .onAppear { animate = true }
    }
}

struct LightAnimation: View {
    @State private var animate = false

    var body: some View {
        Image(systemName: "sun.max.fill")
            .scaleEffect(animate ? 1.1 : 0.9)
            .opacity(animate ? 1.0 : 0.7)
            .animation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: animate
            )
            .onAppear { animate = true }
    }
}

struct FaceAnimation: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Image(systemName: "camera.viewfinder")
            Circle()
                .stroke(Theme.Colors.primary.opacity(0.5), lineWidth: 2)
                .frame(width: 60, height: 60)
                .scaleEffect(animate ? 1.2 : 1.0)
                .opacity(animate ? 0.0 : 1.0)
                .animation(
                    Animation.easeOut(duration: 1.5).repeatForever(autoreverses: false),
                    value: animate
                )
        }
        .onAppear { animate = true }
    }
}

// MARK: - View Model
@MainActor
class IdentityVerificationGuideViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var verificationURL: URL?
    @Published var sessionId: String?
    @Published var showError = false
    @Published var errorMessage = ""

    private let service = IdentityVerificationService.shared

    func startVerification() {
        isLoading = true

        Task {
            do {
                let response = try await service.startVerification()

                if response.alreadyVerified == true {
                    errorMessage = "You are already verified!"
                    showError = true
                    isLoading = false
                } else {
                    sessionId = response.sessionId
                    verificationURL = URL(string: response.verificationUrl)
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isLoading = false
            }
        }
    }
}

#Preview {
    IdentityVerificationGuideView()
}
