//
//  ToastManager.swift
//  Brrow
//
//  Toast notification system for user feedback
//

import SwiftUI
import Combine

// MARK: - Toast Types
enum ToastType {
    case success
    case error
    case info
    case warning
    
    var color: Color {
        switch self {
        case .success: return Theme.Colors.success
        case .error: return Theme.Colors.accent
        case .info: return Theme.Colors.accentBlue
        case .warning: return Theme.Colors.accentOrange
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.circle.fill"
        }
    }
}

// MARK: - Toast Item
struct ToastItem: Identifiable, Equatable {
    let id = UUID()
    let type: ToastType
    let title: String
    let message: String?
    let duration: TimeInterval
    
    var icon: String {
        type.icon
    }
    
    var color: Color {
        type.color
    }
    
    init(type: ToastType, title: String, message: String? = nil, duration: TimeInterval = 3.0) {
        self.type = type
        self.title = title
        self.message = message
        self.duration = duration
    }
}

// MARK: - Toast Manager
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var currentToast: ToastItem?
    
    private var cancellables = Set<AnyCancellable>()
    private var dismissTimer: Timer?
    
    private init() {}
    
    func showToast(_ toast: ToastItem) {
        // Dismiss current timer
        dismissTimer?.invalidate()
        
        // Show new toast
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentToast = toast
        }
        
        // Haptic feedback
        HapticManager.notification(type: toast.type == .success ? .success : 
                                         toast.type == .error ? .error : .warning)
        
        // Auto dismiss
        dismissTimer = Timer.scheduledTimer(withTimeInterval: toast.duration, repeats: false) { _ in
            self.dismissToast()
        }
    }
    
    func showSuccess(title: String, message: String? = nil, duration: TimeInterval = 3.0) {
        let toast = ToastItem(type: .success, title: title, message: message, duration: duration)
        showToast(toast)
    }
    
    func showError(title: String, message: String? = nil, duration: TimeInterval = 4.0) {
        let toast = ToastItem(type: .error, title: title, message: message, duration: duration)
        showToast(toast)
    }
    
    func showInfo(title: String, message: String? = nil, duration: TimeInterval = 3.0) {
        let toast = ToastItem(type: .info, title: title, message: message, duration: duration)
        showToast(toast)
    }
    
    func showWarning(title: String, message: String? = nil, duration: TimeInterval = 3.5) {
        let toast = ToastItem(type: .warning, title: title, message: message, duration: duration)
        showToast(toast)
    }
    
    func dismissToast() {
        dismissTimer?.invalidate()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentToast = nil
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let toast: ToastItem
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: toast.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                if let message = toast.message {
                    Text(message)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Dismiss button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(toast.type.color)
                .shadow(color: toast.type.color.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
    }
}

// MARK: - Toast Overlay Modifier
struct ToastOverlay: ViewModifier {
    @ObservedObject private var toastManager = ToastManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                if let toast = toastManager.currentToast {
                    ToastView(toast: toast) {
                        toastManager.dismissToast()
                    }
                }
                
                Spacer()
            }
        }
    }
}

extension View {
    func toastOverlay() -> some View {
        modifier(ToastOverlay())
    }
}