//
//  ErrorAlertModifier.swift
//  Brrow
//
//  Global error alert modifier for consistent error handling
//

import SwiftUI

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: String?
    var title: String = "Error"
    var dismissAction: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                    dismissAction?()
                }
                
                Button("Report Issue") {
                    reportError()
                    error = nil
                }
            } message: {
                Text(error ?? "An unexpected error occurred")
            }
    }
    
    private func reportError() {
        // Send error report to analytics
        if let errorMessage = error {
            let event = AnalyticsEvent(
                eventName: "user_error_reported",
                eventType: "error",
                userId: AuthManager.shared.currentUser?.apiId,
                sessionId: AuthManager.shared.sessionId,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                metadata: [
                    "error_message": errorMessage,
                    "view_context": title
                ]
            )
            
            Task {
                try? await APIClient.shared.trackAnalytics(event: event)
            }
        }
    }
}

extension View {
    func errorAlert(error: Binding<String?>, title: String = "Error", dismissAction: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlertModifier(error: error, title: title, dismissAction: dismissAction))
    }
}

// Enhanced loading overlay with timeout handling
struct LoadingOverlay: ViewModifier {
    @Binding var isLoading: Bool
    var message: String = "Loading..."
    var timeout: TimeInterval = 30
    @State private var hasTimedOut = false
    @State private var timer: Timer?
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                // Allow dismissing stuck loading screens
                                if hasTimedOut {
                                    isLoading = false
                                    hasTimedOut = false
                                }
                            }
                        
                        VStack(spacing: 20) {
                            if !hasTimedOut {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                
                                Text(message)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.yellow)
                                
                                Text("This is taking longer than expected")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Tap to dismiss")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(40)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.85))
                        )
                    }
                    .onAppear {
                        startTimeout()
                    }
                    .onDisappear {
                        cancelTimeout()
                    }
                } else {
                    EmptyView()
                        .onAppear {
                            cancelTimeout()
                            hasTimedOut = false
                        }
                }
            }
    }
    
    private func startTimeout() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
            hasTimedOut = true
        }
    }
    
    private func cancelTimeout() {
        timer?.invalidate()
        timer = nil
    }
}

extension View {
    func loadingOverlay(isLoading: Binding<Bool>, message: String = "Loading...", timeout: TimeInterval = 30) -> some View {
        modifier(LoadingOverlay(isLoading: isLoading, message: message, timeout: timeout))
    }
}

// Toast notification for non-blocking errors
struct ToastModifier: ViewModifier {
    @Binding var message: String?
    var type: ToastType = .error
    
    enum ToastType {
        case success, error, info, warning
        
        var backgroundColor: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .blue
            case .warning: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    @State private var workItem: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message = message {
                    HStack(spacing: 12) {
                        Image(systemName: type.icon)
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        Text(message)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Button {
                            dismissToast()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(type.backgroundColor)
                            .shadow(radius: 10)
                    )
                    .padding(.horizontal)
                    .padding(.top, 50)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        scheduleAutoDismiss()
                    }
                    .onTapGesture {
                        dismissToast()
                    }
                }
            }
            .animation(.spring(), value: message)
    }
    
    private func dismissToast() {
        withAnimation {
            message = nil
        }
        workItem?.cancel()
    }
    
    private func scheduleAutoDismiss() {
        workItem?.cancel()
        
        workItem = DispatchWorkItem {
            dismissToast()
        }
        
        if let workItem = workItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: workItem)
        }
    }
}

extension View {
    func toast(message: Binding<String?>, type: ToastModifier.ToastType = .error) -> some View {
        modifier(ToastModifier(message: message, type: type))
    }
}

// Network error handler
class NetworkErrorHandler: ObservableObject {
    static let shared = NetworkErrorHandler()
    
    @Published var currentError: String?
    @Published var isShowingError = false
    
    func handle(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            if let apiError = error as? BrrowAPIError {
                switch apiError {
                case .networkError:
                    self?.currentError = "Network connection error. Please check your internet connection."
                case .serverError(let message):
                    self?.currentError = message
                case .serverErrorCode(let code):
                    self?.currentError = "Server error (Code: \(code))"
                case .unauthorized:
                    self?.currentError = "Your session has expired. Please log in again."
                case .invalidResponse:
                    self?.currentError = "Received invalid response from server."
                case .decodingError:
                    self?.currentError = "Error processing server response."
                case .validationError(let message):
                    self?.currentError = message
                case .addressConflict(let message):
                    self?.currentError = message
                }
            } else {
                self?.currentError = error.localizedDescription
            }
            self?.isShowingError = true
        }
    }
    
    func clearError() {
        currentError = nil
        isShowingError = false
    }
}