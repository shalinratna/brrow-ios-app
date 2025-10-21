//
//  AboutBrrowView.swift
//  Brrow
//
//  Created by Claude Code on 9/24/25.
//

import SwiftUI

struct AboutBrrowView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingTermsOfService = false
    @State private var showingPrivacyPolicy = false
    @State private var showingLicenses = false

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // App Logo and Title
                    appHeaderSection

                    // App Description
                    appDescriptionSection

                    // Features Section
                    featuresSection

                    // Team Section
                    teamSection

                    // Legal Section
                    legalSection
                    
                    // Contact Section
                    contactSection

                    // Version Info
                    versionSection

                    Spacer(minLength: Theme.Spacing.xl)
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.background)
            .navigationTitle("About Brrow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingTermsOfService) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingLicenses) {
            LicensesView()
        }
    }

    // MARK: - App Header Section
    private var appHeaderSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // App Icon
            if let appIcon = Bundle.main.icon {
                Image(uiImage: appIcon)
                    .resizable()
                    .frame(width: 120, height: 120)
                    .cornerRadius(Theme.CornerRadius.lg)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            } else {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Text("B")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text("Brrow")
                    .font(Theme.Typography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.text)

                Text("Peer-to-Peer Rental Marketplace")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
    }

    // MARK: - App Description Section
    private var appDescriptionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("About Brrow")
                .font(Theme.Typography.headline)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.text)

            Text("Brrow is a revolutionary peer-to-peer rental marketplace that connects people who want to rent items with those who have them. Whether you need a power drill for a weekend project or want to earn money from items you rarely use, Brrow makes it simple, safe, and profitable.")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Theme.Colors.cardBackground)
        )
    }

    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("Key Features")
                .font(Theme.Typography.headline)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.text)

            VStack(spacing: Theme.Spacing.md) {
                AboutFeatureRow(
                    icon: "magnifyingglass.circle.fill",
                    title: "Smart Search",
                    description: "Find exactly what you need with advanced filters and location-based results",
                    color: Theme.Colors.primary
                )

                AboutFeatureRow(
                    icon: "shield.checkered",
                    title: "Secure Transactions",
                    description: "Protected payments and verified users ensure safe and reliable rentals",
                    color: .green
                )

                AboutFeatureRow(
                    icon: "message.circle.fill",
                    title: "Easy Communication",
                    description: "Built-in messaging system to coordinate pickup, delivery, and support",
                    color: .blue
                )

                AboutFeatureRow(
                    icon: "dollarsign.circle.fill",
                    title: "Earn Money",
                    description: "Turn your unused items into a steady income stream with our rental platform",
                    color: .orange
                )
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Theme.Colors.cardBackground)
        )
    }

    // MARK: - Team Section
    private var teamSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("Our Mission")
                .font(Theme.Typography.headline)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.text)

            Text("We believe in a sustainable future where sharing resources benefits everyone. By making it easy to rent instead of buy, we're reducing waste, saving money, and building stronger communities.")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Theme.Colors.cardBackground)
        )
    }

    // MARK: - Legal Section
    private var legalSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Legal")
                .font(Theme.Typography.headline)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.text)

            VStack(spacing: Theme.Spacing.xs) {
                LegalRow(title: "Terms of Service") {
                    showingTermsOfService = true
                }

                LegalRow(title: "Privacy Policy") {
                    showingPrivacyPolicy = true
                }

                LegalRow(title: "Open Source Licenses") {
                    showingLicenses = true
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Theme.Colors.cardBackground)
        )
    }
    
    // MARK: - Version Section
    private var versionSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text("Version \(appVersion) (\(buildNumber))")
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)

            Text("Made with ❤️ in California's Bay Area.")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.tertiaryText)
        }
    }

    // MARK: - Contact Section
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Get in Touch")
                .font(Theme.Typography.headline)
                .fontWeight(.bold)
                .foregroundColor(Theme.Colors.text)

            VStack(spacing: Theme.Spacing.sm) {
                ContactRow(
                    icon: "shield.checkmark",
                    title: "Safety Center",
                    subtitle: "Learn about staying safe",
                    action: {
                        if let url = URL(string: "https://brrowapp.com/safety") {
                            UIApplication.shared.open(url)
                        }
                    }
                )

                ContactRow(
                    icon: "questionmark.circle.fill",
                    title: "Help Center",
                    subtitle: "FAQs and support",
                    action: {
                        if let url = URL(string: "https://brrowapp.com/help") {
                            UIApplication.shared.open(url)
                        }
                    }
                )

                ContactRow(
                    icon: "envelope.fill",
                    title: "Email Support",
                    subtitle: "help@brrowapp.com",
                    action: {
                        if let url = URL(string: "mailto:help@brrow.com") {
                            UIApplication.shared.open(url)
                        }
                    }
                )

                ContactRow(
                    icon: "globe",
                    title: "Website",
                    subtitle: "www.brrowapp.com",
                    action: {
                        if let url = URL(string: "https://www.brrowapp.com") {
                            UIApplication.shared.open(url)
                        }
                    }
                )
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Theme.Colors.cardBackground)
        )
    }
}

// MARK: - Feature Row
struct AboutFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.text)

                Text(description)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Legal Row
struct LegalRow: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(.vertical, Theme.Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Contact Row
struct ContactRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(Theme.Colors.primary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.callout)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.text)

                    Text(subtitle)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.primary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(.vertical, Theme.Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Licenses View
struct LicensesView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Text("This app uses the following open source libraries:")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.text)

                    ForEach(openSourceLibraries, id: \.name) { library in
                        LibraryRow(library: library)
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Open Source Licenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private let openSourceLibraries = [
        OpenSourceLibrary(name: "Alamofire", description: "HTTP networking library", license: "MIT"),
        OpenSourceLibrary(name: "SDWebImage", description: "Image loading and caching", license: "MIT"),
        OpenSourceLibrary(name: "Socket.IO", description: "Real-time communication", license: "MIT"),
        OpenSourceLibrary(name: "Stripe SDK", description: "Payment processing", license: "MIT"),
        OpenSourceLibrary(name: "Firebase", description: "Backend services", license: "Apache 2.0")
    ]
}

// MARK: - Open Source Library Model
struct OpenSourceLibrary {
    let name: String
    let description: String
    let license: String
}

// MARK: - Library Row
struct LibraryRow: View {
    let library: OpenSourceLibrary

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(library.name)
                    .font(Theme.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.text)

                Spacer()

                Text(library.license)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.primary)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Theme.Colors.primary.opacity(0.1))
                    )
            }

            Text(library.description)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.cardBackground)
        )
    }
}

// MARK: - Bundle Extension
extension Bundle {
    var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
}

// MARK: - Preview
#Preview {
    AboutBrrowView()
}
