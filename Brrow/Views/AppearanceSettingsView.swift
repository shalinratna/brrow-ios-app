//
//  AppearanceSettingsView.swift
//  Brrow
//
//  Settings for app appearance, theme, and language
//

import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager

    // App Storage for persistent settings
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("textSizeIndex") private var textSizeIndex = 1 // 0=Small, 1=Medium, 2=Large
    @AppStorage("selectedLanguage") private var selectedLanguage = "en"

    // State for UI updates
    @State private var isSaving = false
    @State private var showSuccess = false

    private let textSizes = ["Small", "Medium", "Large"]
    private let languages = [
        ("en", "English"),
        ("es", "Español"),
        ("fr", "Français"),
        ("de", "Deutsch"),
        ("zh", "中文"),
        ("ja", "日本語")
    ]

    var body: some View {
        NavigationView {
            List {
                // Dark Mode Section
                Section {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purple.opacity(0.2))
                                .frame(width: 32, height: 32)

                            Image(systemName: isDarkMode ? "moon.fill" : "moon")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.purple)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dark Mode")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.Colors.text)

                            Text("Use dark appearance")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.Colors.secondaryText)
                        }

                        Spacer()

                        Toggle("", isOn: $isDarkMode)
                            .tint(Theme.Colors.primary)
                            .onChange(of: isDarkMode) { newValue in
                                saveUserPreferences()
                            }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Theme")
                }

                // Text Size Section
                Section {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 32, height: 32)

                            Image(systemName: "textformat.size")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.orange)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Text Size")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.Colors.text)

                            Text("Current: \(textSizes[textSizeIndex])")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.Colors.secondaryText)
                        }

                        Spacer()

                        Picker("Text Size", selection: $textSizeIndex) {
                            ForEach(0..<textSizes.count, id: \.self) { index in
                                Text(textSizes[index])
                                    .tag(index)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .tint(Theme.Colors.primary)
                        .onChange(of: textSizeIndex) { _ in
                            saveUserPreferences()
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Typography")
                }

                // Language Section
                Section {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 32, height: 32)

                            Image(systemName: "globe")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Language")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.Colors.text)

                            Text("Current: \(currentLanguageName)")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.Colors.secondaryText)
                        }

                        Spacer()

                        Picker("Language", selection: $selectedLanguage) {
                            ForEach(languages, id: \.0) { code, name in
                                Text(name)
                                    .tag(code)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .tint(Theme.Colors.primary)
                        .onChange(of: selectedLanguage) { _ in
                            saveUserPreferences()
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Localization")
                }

                // Save to Account Section
                Section {
                    Button(action: syncSettingsToAccount) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .frame(width: 20, height: 20)
                            } else {
                                Image(systemName: "icloud.and.arrow.up")
                                    .foregroundColor(Theme.Colors.primary)
                            }

                            Text("Sync Settings to Account")
                                .foregroundColor(isSaving ? Theme.Colors.secondaryText : Theme.Colors.primary)

                            Spacer()
                        }
                    }
                    .disabled(isSaving)
                } header: {
                    Text("Cloud Sync")
                } footer: {
                    Text("Save your appearance preferences to your account so they sync across all your devices.")
                }
            }
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Settings Synced", isPresented: $showSuccess) {
                Button("OK") { }
            } message: {
                Text("Your appearance settings have been saved to your account and will sync across all your devices.")
            }
        }
    }

    private var currentLanguageName: String {
        languages.first { $0.0 == selectedLanguage }?.1 ?? "English"
    }

    private func saveUserPreferences() {
        // Preferences are automatically saved via @AppStorage
        // This function can be used for additional logic if needed

        // Apply dark mode immediately (if using a theme manager)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
        }
    }

    private func syncSettingsToAccount() {
        guard let user = authManager.currentUser else { return }

        isSaving = true

        Task {
            do {
                // Create user preferences object
                let preferences = APIClient.UserPreferences(
                    isDarkMode: isDarkMode,
                    textSize: textSizes[textSizeIndex].lowercased(),
                    language: selectedLanguage
                )

                // Save to backend
                try await APIClient.shared.saveUserPreferences(preferences)

                await MainActor.run {
                    isSaving = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    print("Failed to sync settings: \(error)")
                }
            }
        }
    }
}


#Preview {
    AppearanceSettingsView()
        .environmentObject(AuthManager.shared)
}