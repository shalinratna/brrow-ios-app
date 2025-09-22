import SwiftUI

struct LanguageSettingsView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLanguage: LocalizationManager.Language
    @State private var showingRestartAlert = false

    init() {
        _selectedLanguage = State(initialValue: LocalizationManager.shared.currentLanguage)
    }

    var body: some View {
        ZStack {
                // Background
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header Info
                        VStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.system(size: 60))
                                .foregroundColor(Theme.Colors.primary)

                            Text("Language Settings")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Theme.Colors.text)

                            Text("Choose your preferred language")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 30)

                        // Current Language
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Language")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.secondaryText)
                                .padding(.horizontal)

                            HStack {
                                Text(localizationManager.currentLanguage.flag)
                                    .font(.system(size: 24))

                                Text(localizationManager.currentLanguage.displayName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Theme.Colors.text)

                                Spacer()

                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.Colors.primary)
                                    .font(.system(size: 20))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.Colors.primary.opacity(0.1))
                            )
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 30)

                        // Language List
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Available Languages")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.secondaryText)
                                .padding(.horizontal)

                            VStack(spacing: 0) {
                                ForEach(LocalizationManager.Language.allCases, id: \.self) { language in
                                    LanguageRow(
                                        language: language,
                                        isSelected: selectedLanguage == language,
                                        action: {
                                            withAnimation(.spring()) {
                                                selectedLanguage = language
                                            }
                                        }
                                    )

                                    if language != LocalizationManager.Language.allCases.last {
                                        Divider()
                                            .padding(.horizontal)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.Colors.secondaryBackground)
                            )
                            .padding(.horizontal)
                        }

                        // Apply Button
                        Button(action: applyLanguageChange) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("Apply Changes")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedLanguage != localizationManager.currentLanguage ?
                                          Theme.Colors.primary : Color.gray.opacity(0.3))
                            )
                        }
                        .disabled(selectedLanguage == localizationManager.currentLanguage)
                        .padding(.horizontal)
                        .padding(.top, 30)

                        // Info Text
                        Text("Language changes will be applied immediately")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding()
                            .padding(.bottom, 30)
                    }
                }
            }
        .navigationTitle("Language Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Language Changed", isPresented: $showingRestartAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your language preference has been updated")
        }
    }

    private func applyLanguageChange() {
        if selectedLanguage != localizationManager.currentLanguage {
            localizationManager.setLanguage(selectedLanguage)
            showingRestartAlert = true
        }
    }
}

struct LanguageRow: View {
    let language: LocalizationManager.Language
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(language.flag)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 4) {
                    Text(language.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.text)

                    Text(getLanguageNameInEnglish(language))
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.Colors.primary)
                        .font(.system(size: 22))
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(Color.gray.opacity(0.3))
                        .font(.system(size: 22))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func getLanguageNameInEnglish(_ language: LocalizationManager.Language) -> String {
        switch language {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .vietnamese: return "Vietnamese"
        case .punjabi: return "Punjabi"
        case .urdu: return "Urdu"
        case .french: return "French"
        case .german: return "German"
        case .chinese: return "Chinese (Simplified)"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .russian: return "Russian"
        case .arabic: return "Arabic"
        case .hindi: return "Hindi"
        case .portuguese: return "Portuguese"
        case .italian: return "Italian"
        }
    }
}

struct LanguageSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSettingsView()
    }
}