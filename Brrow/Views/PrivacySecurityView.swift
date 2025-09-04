//
//  PrivacySecurityView.swift
//  Brrow
//
//  Privacy and security settings
//

import SwiftUI

struct PrivacySecurityView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var faceIDEnabled = true
    @State private var autoLockEnabled = true
    @State private var showLocationToContacts = true
    @State private var allowDataSharing = false
    
    var body: some View {
        List {
            Section("Security") {
                Toggle(isOn: $faceIDEnabled) {
                    HStack {
                        Image(systemName: "faceid")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Face ID / Touch ID")
                                .foregroundColor(Theme.Colors.text)
                            Text("Use biometrics to unlock app")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
                
                Toggle(isOn: $autoLockEnabled) {
                    HStack {
                        Image(systemName: "lock.rotation")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Auto-Lock")
                                .foregroundColor(Theme.Colors.text)
                            Text("Lock app when in background")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
            }
            
            Section("Privacy") {
                Toggle(isOn: $showLocationToContacts) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Share Location")
                                .foregroundColor(Theme.Colors.text)
                            Text("Show approximate distance to other users")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
                
                Toggle(isOn: $allowDataSharing) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Analytics")
                                .foregroundColor(Theme.Colors.text)
                            Text("Help improve Brrow with anonymous data")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
            }
            
            Section("Account Security") {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)
                        
                        Text("Change Password")
                            .foregroundColor(Theme.Colors.text)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "iphone.and.arrow.forward")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)
                        
                        Text("Active Sessions")
                            .foregroundColor(Theme.Colors.text)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Privacy & Security")
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

#Preview {
    NavigationView {
        PrivacySecurityView()
    }
}