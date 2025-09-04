//
//  ColorSchemeManager.swift
//  Brrow
//
//  Dark/Light Mode Management
//

import SwiftUI
import Combine

class ColorSchemeManager: ObservableObject {
    static let shared = ColorSchemeManager()
    
    @Published var colorScheme: ColorScheme?
    @Published var appearanceMode: AppearanceMode = .light {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
            updateColorScheme()
        }
    }
    
    enum AppearanceMode: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
        
        var displayName: String { rawValue }
    }
    
    private init() {
        // Load saved preference, default to light if not set
        if let savedMode = UserDefaults.standard.string(forKey: "appearanceMode"),
           let mode = AppearanceMode(rawValue: savedMode) {
            appearanceMode = mode
        } else {
            // First time - default to light mode
            appearanceMode = .light
        }
        updateColorScheme()
    }
    
    private func updateColorScheme() {
        switch appearanceMode {
        case .system:
            colorScheme = nil // Use system default
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        }
    }
}

// MARK: - View Modifier for Color Scheme
struct ColorSchemeModifier: ViewModifier {
    @ObservedObject var manager = ColorSchemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(manager.colorScheme)
    }
}

extension View {
    func applyColorScheme() -> some View {
        modifier(ColorSchemeModifier())
    }
}