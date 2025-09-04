//
//  EmailPreferencesView.swift
//  Brrow
//
//  Email notification preferences
//

import SwiftUI

struct EmailPreferencesView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var marketingEmails = true
    @State private var rentalUpdates = true
    @State private var newMessages = true
    @State private var weeklyDigest = false
    @State private var priceAlerts = true
    @State private var communityNews = true
    
    var body: some View {
        List {
            Section("Rental Activity") {
                Toggle(isOn: $rentalUpdates) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Rental Updates")
                                .foregroundColor(Theme.Colors.text)
                            Text("Booking confirmations and reminders")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
                
                Toggle(isOn: $newMessages) {
                    HStack {
                        Image(systemName: "message.fill")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("New Messages")
                                .foregroundColor(Theme.Colors.text)
                            Text("Get notified when you receive messages")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
                
                Toggle(isOn: $priceAlerts) {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Price Alerts")
                                .foregroundColor(Theme.Colors.text)
                            Text("Price drops on saved items")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
            }
            
            Section("Marketing & News") {
                Toggle(isOn: $marketingEmails) {
                    HStack {
                        Image(systemName: "megaphone.fill")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Promotional Emails")
                                .foregroundColor(Theme.Colors.text)
                            Text("Special offers and new features")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
                
                Toggle(isOn: $weeklyDigest) {
                    HStack {
                        Image(systemName: "newspaper.fill")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Weekly Digest")
                                .foregroundColor(Theme.Colors.text)
                            Text("Popular items in your area")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
                
                Toggle(isOn: $communityNews) {
                    HStack {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Community Updates")
                                .foregroundColor(Theme.Colors.text)
                            Text("Local events and announcements")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
            }
            
            Section {
                Button(action: {}) {
                    HStack {
                        Spacer()
                        Text("Unsubscribe from all emails")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Email Preferences")
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
        EmailPreferencesView()
    }
}