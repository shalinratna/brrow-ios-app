//
//  ComplianceAgreementView.swift
//  Brrow
//
//  Compliance agreement for new users
//

import SwiftUI

struct ComplianceAgreementView: View {
    @Binding var hasAgreedToTerms: Bool
    @State private var agreedToTerms = false
    @State private var agreedToPrivacy = false
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Logo and Welcome
            VStack(spacing: 20) {
                Image(systemName: "cube.box.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.Colors.primary)
                
                Text("Welcome to Brrow")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Please review and accept our policies to continue")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 50)
            
            Spacer()
            
            // Agreement Checkboxes
            VStack(spacing: 20) {
                // Terms of Service
                HStack(alignment: .top, spacing: 15) {
                    Button(action: {
                        agreedToTerms.toggle()
                    }) {
                        Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                            .foregroundColor(agreedToTerms ? Theme.Colors.primary : .gray)
                            .font(.title2)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("I agree to the Terms of Service")
                            .font(.body)
                        
                        Button(action: {
                            showingTerms = true
                        }) {
                            Text("Read Terms of Service")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.primary)
                                .underline()
                        }
                    }
                    
                    Spacer()
                }
                
                // Privacy Policy
                HStack(alignment: .top, spacing: 15) {
                    Button(action: {
                        agreedToPrivacy.toggle()
                    }) {
                        Image(systemName: agreedToPrivacy ? "checkmark.square.fill" : "square")
                            .foregroundColor(agreedToPrivacy ? Theme.Colors.primary : .gray)
                            .font(.title2)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("I agree to the Privacy Policy")
                            .font(.body)
                        
                        Button(action: {
                            showingPrivacy = true
                        }) {
                            Text("Read Privacy Policy")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.primary)
                                .underline()
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 30)
            
            // Age Confirmation
            VStack(spacing: 10) {
                Image(systemName: "person.badge.shield.checkmark")
                    .font(.title)
                    .foregroundColor(.secondary)
                
                Text("By continuing, you confirm that you are at least 18 years old")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Continue Button
            Button(action: {
                if agreedToTerms && agreedToPrivacy {
                    UserDefaults.standard.set(true, forKey: "HasAgreedToTerms")
                    UserDefaults.standard.set(Date(), forKey: "TermsAgreementDate")
                    hasAgreedToTerms = true
                }
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(agreedToTerms && agreedToPrivacy ? Theme.Colors.primary : Color.gray)
                    )
            }
            .disabled(!agreedToTerms || !agreedToPrivacy)
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
        .sheet(isPresented: $showingTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyPolicyView()
        }
    }
}

struct ComplianceAgreementView_Previews: PreviewProvider {
    static var previews: some View {
        ComplianceAgreementView(hasAgreedToTerms: .constant(false))
    }
}