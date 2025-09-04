//
//  TermsOfServiceView.swift
//  Brrow
//
//  Terms of Service display for compliance
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms of Service")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    Text("Last Updated: January 2025")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Agreement
                    Section {
                        Text("By using Brrow, you agree to these Terms of Service. If you do not agree, please do not use our service.")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    
                    // Use of Service
                    sectionHeader("1. Use of Service")
                    Text("Brrow is a peer-to-peer rental marketplace. You must:\n• Be at least 18 years old\n• Provide accurate information\n• Use the service lawfully\n• Not misuse or damage rented items\n• Respect other users")
                        .font(.body)
                    
                    // User Accounts
                    sectionHeader("2. User Accounts")
                    Text("• You are responsible for your account security\n• One account per person\n• Keep your login credentials confidential\n• Notify us of unauthorized access\n• We may suspend accounts that violate these terms")
                        .font(.body)
                    
                    // Listings and Rentals
                    sectionHeader("3. Listings and Rentals")
                    Text("**For Lenders:**\n• Ensure items are safe and as described\n• Honor confirmed rentals\n• Maintain item availability calendar\n• Respond to rental requests promptly")
                        .font(.body)
                        .padding(.bottom, 10)
                    
                    Text("**For Borrowers:**\n• Return items on time and in same condition\n• Report any damage immediately\n• Pay all fees and deposits\n• Use items responsibly")
                        .font(.body)
                    
                    // Fees and Payments
                    sectionHeader("4. Fees and Payments")
                    Text("• Brrow charges a 5% platform fee\n• Payments processed through Stripe\n• Refunds subject to our refund policy\n• You're responsible for applicable taxes\n• Late returns may incur additional fees")
                        .font(.body)
                    
                    // Prohibited Items
                    sectionHeader("5. Prohibited Items")
                    Text("You may NOT rent:\n• Weapons or firearms\n• Illegal items or substances\n• Hazardous materials\n• Stolen property\n• Items you don't own\n• Adult content")
                        .font(.body)
                    
                    // Liability and Insurance
                    sectionHeader("6. Liability and Insurance")
                    Text("• Users are responsible for damage/loss\n• We recommend insurance for high-value items\n• Brrow is not liable for user disputes\n• Maximum platform liability: $100\n• You indemnify Brrow from claims")
                        .font(.body)
                    
                    // Dispute Resolution
                    sectionHeader("7. Dispute Resolution")
                    Text("• Try to resolve disputes directly\n• Use our mediation service if needed\n• Binding arbitration for unresolved issues\n• No class action lawsuits\n• Disputes governed by California law")
                        .font(.body)
                    
                    // Privacy
                    sectionHeader("8. Privacy")
                    Text("Your use of Brrow is subject to our Privacy Policy. By using our service, you consent to our data practices.")
                        .font(.body)
                    
                    // Termination
                    sectionHeader("9. Termination")
                    Text("• Either party may terminate at any time\n• Complete pending transactions first\n• We may suspend service for violations\n• Some provisions survive termination")
                        .font(.body)
                    
                    // Disclaimers
                    sectionHeader("10. Disclaimers")
                    Text("• Service provided \"as is\"\n• No warranties of any kind\n• We don't guarantee item availability\n• Not responsible for user conduct\n• Use at your own risk")
                        .font(.body)
                    
                    // Changes to Terms
                    sectionHeader("11. Changes to Terms")
                    Text("We may update these terms. Continued use after changes means acceptance. Check this page regularly.")
                        .font(.body)
                    
                    // Contact
                    sectionHeader("12. Contact Information")
                    Text("Questions? Contact us at:\n\nEmail: legal@brrowapp.com\nAddress: Brrow Inc.\n123 Main Street\nSan Francisco, CA 94105")
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

struct TermsOfServiceView_Previews: PreviewProvider {
    static var previews: some View {
        TermsOfServiceView()
    }
}