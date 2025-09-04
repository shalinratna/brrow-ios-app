//
//  PrivacyPolicyView.swift
//  Brrow
//
//  Privacy Policy display for compliance
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    Text("Last Updated: January 2025")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Introduction
                    Section {
                        Text("Brrow (\"we\", \"our\", or \"us\") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.")
                            .font(.body)
                    }
                    
                    // Information We Collect
                    sectionHeader("Information We Collect")
                    
                    Text("**Personal Information**")
                        .font(.subheadline.bold())
                    Text("• Name and email address\n• Phone number\n• Profile picture\n• Location data\n• Payment information (processed by Stripe)")
                        .font(.body)
                        .padding(.bottom)
                    
                    Text("**Usage Data**")
                        .font(.subheadline.bold())
                    Text("• App usage patterns\n• Listings viewed and created\n• Transaction history\n• Device information")
                        .font(.body)
                    
                    // How We Use Information
                    sectionHeader("How We Use Your Information")
                    Text("We use your information to:\n• Facilitate peer-to-peer rentals\n• Process payments securely\n• Send notifications about your rentals\n• Improve our services\n• Ensure platform safety\n• Comply with legal obligations")
                        .font(.body)
                    
                    // Data Sharing
                    sectionHeader("Data Sharing")
                    Text("We may share your information with:\n• Other users (limited profile data)\n• Payment processors (Stripe)\n• Service providers (OneSignal for notifications)\n• Law enforcement when required")
                        .font(.body)
                    
                    // Data Security
                    sectionHeader("Data Security")
                    Text("We implement appropriate technical and organizational measures to protect your personal information, including:\n• Encryption of sensitive data\n• Secure authentication\n• Regular security audits\n• Limited access controls")
                        .font(.body)
                    
                    // Your Rights
                    sectionHeader("Your Rights")
                    Text("You have the right to:\n• Access your personal data\n• Correct inaccurate data\n• Delete your account\n• Export your data\n• Opt-out of marketing communications")
                        .font(.body)
                    
                    // Data Retention
                    sectionHeader("Data Retention")
                    Text("We retain your personal information for as long as necessary to provide our services and comply with legal obligations. Transaction records are kept for 7 years for tax purposes.")
                        .font(.body)
                    
                    // Children's Privacy
                    sectionHeader("Children's Privacy")
                    Text("Our service is not intended for users under 18 years of age. We do not knowingly collect personal information from children.")
                        .font(.body)
                    
                    // Contact Information
                    sectionHeader("Contact Us")
                    Text("If you have questions about this Privacy Policy, please contact us at:\n\nEmail: privacy@brrowapp.com\nAddress: Brrow Inc.\n123 Main Street\nSan Francisco, CA 94105")
                        .font(.body)
                    
                    // Changes to Policy
                    sectionHeader("Changes to This Policy")
                    Text("We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the \"Last Updated\" date.")
                        .font(.body)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .padding(.top)
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyView()
    }
}