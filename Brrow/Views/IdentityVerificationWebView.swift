//
//  IdentityVerificationWebView.swift
//  Brrow
//
//  Created by Claude on 1/21/25.
//  WKWebView wrapper for Stripe Identity verification
//

import SwiftUI
import WebKit

struct IdentityVerificationWebView: View {
    let verificationURL: URL
    let sessionId: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var coordinator = WebViewCoordinator()

    var body: some View {
        NavigationView {
            ZStack {
                // WebView
                WebView(
                    url: verificationURL,
                    coordinator: coordinator
                )
                .ignoresSafeArea(edges: .bottom)

                // Loading overlay
                if coordinator.isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primary))

                        Text("Loading verification...")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.9))
                }

                // Success overlay
                if coordinator.verificationComplete {
                    VStack(spacing: 24) {
                        // Success checkmark
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.primary.opacity(0.1))
                                .frame(width: 100, height: 100)

                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(Theme.Colors.primary)
                        }

                        VStack(spacing: 8) {
                            Text("Verification Complete!")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)

                            Text("Your identity has been submitted for verification")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        Button(action: {
                            dismiss()
                        }) {
                            Text("Done")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Theme.Colors.primary)
                                .cornerRadius(16)
                                .padding(.horizontal, 32)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        coordinator.cancelVerification()
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if coordinator.canGoBack {
                        Button(action: {
                            coordinator.goBack()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                }
            }
            .alert("Verification Error", isPresented: $coordinator.showError) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(coordinator.errorMessage)
            }
        }
    }
}

// MARK: - WebView UIViewRepresentable
struct WebView: UIViewRepresentable {
    let url: URL
    @ObservedObject var coordinator: WebViewCoordinator

    func makeCoordinator() -> WebViewCoordinator {
        return coordinator
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url == nil {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}

// MARK: - WebView Coordinator
class WebViewCoordinator: NSObject, ObservableObject, WKNavigationDelegate {
    @Published var isLoading = true
    @Published var canGoBack = false
    @Published var verificationComplete = false
    @Published var showError = false
    @Published var errorMessage = ""

    private weak var webView: WKWebView?
    private let service = IdentityVerificationService.shared

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.webView = webView
        isLoading = true
        canGoBack = webView.canGoBack
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        canGoBack = webView.canGoBack

        // Check if we're on a completion/return URL
        if let url = webView.url?.absoluteString {
            print("🔵 [Identity WebView] Loaded URL: \(url)")

            // Check for deep link return (brrow://identity/verification/complete)
            if url.contains("brrow://") || url.contains("verification/complete") {
                handleVerificationComplete()
            }

            // Check for Stripe success indicators
            if url.contains("success") || url.contains("complete") || url.contains("verified") {
                handleVerificationComplete()
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        print("❌ [Identity WebView] Navigation failed: \(error.localizedDescription)")

        errorMessage = "Failed to load verification page. Please try again."
        showError = true
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        isLoading = false

        // Ignore cancelled errors (user navigated away)
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            return
        }

        print("❌ [Identity WebView] Provisional navigation failed: \(error.localizedDescription)")

        errorMessage = "Failed to load verification page. Please check your internet connection and try again."
        showError = true
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        // Handle deep links
        if let url = navigationAction.request.url,
           url.scheme == "brrow" || url.absoluteString.contains("brrow://") {
            print("🔵 [Identity WebView] Deep link detected: \(url.absoluteString)")

            handleVerificationComplete()
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    // MARK: - Actions

    func goBack() {
        webView?.goBack()
    }

    func cancelVerification() {
        print("🔵 [Identity WebView] User canceled verification")
        // Could call cancel endpoint here if needed
    }

    private func handleVerificationComplete() {
        print("✅ [Identity WebView] Verification flow complete")

        // Show success UI
        withAnimation(.spring(response: 0.5)) {
            verificationComplete = true
        }

        // Optionally: Poll for verification status to confirm
        // Task {
        //     try? await service.pollVerificationStatus(sessionId: sessionId)
        // }
    }
}

#Preview {
    IdentityVerificationWebView(
        verificationURL: URL(string: "https://verify.stripe.com/start/test_123")!,
        sessionId: "vs_test_123"
    )
}
