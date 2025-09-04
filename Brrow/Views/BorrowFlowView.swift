//
//  BorrowFlowView.swift
//  Brrow
//
//  Modern borrowing flow with swipe tutorial
//

import SwiftUI

struct BorrowFlowView: View {
    let listing: Listing
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var showTutorial = true
    @State private var selectedDates: Set<DateComponents> = []
    @State private var selectedStartDate: Date?
    @State private var selectedEndDate: Date?
    @State private var message = ""
    @State private var offerAmount = ""
    @State private var agreedToTerms = false
    @State private var isProcessing = false
    
    // Check if user has seen tutorial before
    @AppStorage("hasSeenBorrowTutorial") private var hasSeenTutorial = false
    
    var body: some View {
        ZStack {
            if showTutorial && !hasSeenTutorial {
                BorrowTutorialView(showTutorial: $showTutorial) {
                    hasSeenTutorial = true
                }
            } else {
                borrowFlowContent
            }
        }
    }
    
    private var borrowFlowContent: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Progress indicator
            progressView
            
            // Content
            TabView(selection: $currentStep) {
                // Step 1: Select Dates
                dateSelectionStep
                    .tag(0)
                
                // Step 2: Add Message/Offer
                messageStep
                    .tag(1)
                
                // Step 3: Review & Confirm
                reviewStep
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Bottom buttons
            bottomButtons
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
            }
            
            Spacer()
            
            Text(stepTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            Spacer()
            
            // Placeholder for balance
            Color.clear
                .frame(width: 24, height: 24)
        }
        .padding()
        .background(Theme.Colors.background)
    }
    
    private var stepTitle: String {
        switch currentStep {
        case 0: return "Select Dates"
        case 1: return "Add Details"
        case 2: return "Review & Confirm"
        default: return ""
        }
    }
    
    // MARK: - Progress View
    
    private var progressView: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step <= currentStep ? Theme.Colors.primary : Theme.Colors.secondary.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    // MARK: - Step 1: Date Selection
    
    private var dateSelectionStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Item info
                HStack(spacing: 12) {
                    CachedAsyncImage(url: listing.images.first)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(listing.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                        
                        Text("$\(String(format: "%.2f", listing.price))/\(listing.rentalPeriod ?? "day")")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.primary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Theme.Colors.cardBackground)
                .cornerRadius(12)
                
                // Calendar
                VStack(alignment: .leading, spacing: 12) {
                    Text("When do you need it?")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                    
                    DatePicker("Start Date", selection: Binding(
                        get: { selectedStartDate ?? Date() },
                        set: { selectedStartDate = $0 }
                    ), displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .accentColor(Theme.Colors.primary)
                    
                    if selectedStartDate != nil {
                        DatePicker("End Date", selection: Binding(
                            get: { selectedEndDate ?? Date() },
                            set: { selectedEndDate = $0 }
                        ), in: (selectedStartDate ?? Date())..., displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .padding()
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(12)
                    }
                }
                
                // Duration summary
                if let start = selectedStartDate, let end = selectedEndDate {
                    let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text("\(days + 1) \(days == 0 ? "day" : "days")")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        HStack {
                            Text("Total Cost")
                            Spacer()
                            Text("$\(String(format: "%.2f", listing.price * Double(days + 1)))")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                    .padding()
                    .background(Theme.Colors.primary.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Step 2: Message/Offer
    
    private var messageStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Message to owner
                VStack(alignment: .leading, spacing: 12) {
                    Text("Message to \(listing.ownerUsername ?? "owner")")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.Colors.text)
                    
                    Text("Introduce yourself and explain why you need this item")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    TextEditor(text: $message)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.Colors.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
                
                // Make an offer (optional)
                if listing.type == "rent" {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Make an offer (optional)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                        
                        Text("Suggest a different price if needed")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        HStack {
                            Text("$")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                            
                            TextField("0.00", text: $offerAmount)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 18))
                        }
                        .padding()
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.Colors.secondary.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                
                // Tips
                VStack(alignment: .leading, spacing: 8) {
                    Label("Be respectful and professional", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.primary)
                    
                    Label("Explain your intended use", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.primary)
                    
                    Label("Confirm pickup/return times", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.primary)
                }
                .padding()
                .background(Theme.Colors.primary.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
        }
    }
    
    // MARK: - Step 3: Review
    
    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Summary
                VStack(alignment: .leading, spacing: 16) {
                    Text("Booking Summary")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.Colors.text)
                    
                    // Item
                    HStack {
                        Text("Item")
                            .foregroundColor(Theme.Colors.secondaryText)
                        Spacer()
                        Text(listing.title)
                            .font(.system(size: 15, weight: .medium))
                    }
                    
                    // Dates
                    if let start = selectedStartDate, let end = selectedEndDate {
                        HStack {
                            Text("Dates")
                                .foregroundColor(Theme.Colors.secondaryText)
                            Spacer()
                            Text("\(start, formatter: dateFormatter) - \(end, formatter: dateFormatter)")
                                .font(.system(size: 15, weight: .medium))
                        }
                    }
                    
                    // Cost
                    if let start = selectedStartDate, let end = selectedEndDate {
                        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
                        
                        Divider()
                        
                        HStack {
                            Text("Total")
                                .font(.system(size: 18, weight: .semibold))
                            Spacer()
                            Text("$\(String(format: "%.2f", listing.price * Double(days + 1)))")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                }
                .padding()
                .background(Theme.Colors.cardBackground)
                .cornerRadius(12)
                
                // Terms
                HStack(alignment: .top, spacing: 12) {
                    Button(action: { agreedToTerms.toggle() }) {
                        Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                            .font(.system(size: 24))
                            .foregroundColor(agreedToTerms ? Theme.Colors.primary : Theme.Colors.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("I agree to the terms and conditions")
                            .font(.system(size: 14, weight: .medium))
                        
                        Text("I will take care of the item and return it on time in the same condition")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                // Protection info
                HStack(spacing: 12) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.Colors.primary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Brrow Protection")
                            .font(.system(size: 14, weight: .semibold))
                        
                        Text("Your booking is protected by our insurance policy")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                .padding()
                .background(Theme.Colors.primary.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
        }
    }
    
    // MARK: - Bottom Buttons
    
    private var bottomButtons: some View {
        HStack(spacing: 12) {
            if currentStep > 0 {
                Button(action: {
                    withAnimation {
                        currentStep -= 1
                    }
                }) {
                    Text("Back")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Theme.Colors.primary.opacity(0.1))
                        .cornerRadius(25)
                }
            }
            
            Button(action: {
                if currentStep < 2 {
                    withAnimation {
                        currentStep += 1
                    }
                } else {
                    submitRequest()
                }
            }) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Theme.Colors.primary)
                        .cornerRadius(25)
                } else {
                    Text(currentStep == 2 ? "Send Request" : "Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(canProceed ? Theme.Colors.primary : Theme.Colors.secondary)
                        .cornerRadius(25)
                }
            }
            .disabled(!canProceed || isProcessing)
        }
        .padding()
        .background(Theme.Colors.background)
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return selectedStartDate != nil && selectedEndDate != nil
        case 1:
            return !message.isEmpty
        case 2:
            return agreedToTerms
        default:
            return false
        }
    }
    
    private func submitRequest() {
        isProcessing = true
        
        Task {
            // Submit borrow request
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            isProcessing = false
            dismiss()
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

// MARK: - Tutorial View

struct BorrowTutorialView: View {
    @Binding var showTutorial: Bool
    let onComplete: () -> Void
    @State private var currentPage = 0
    
    var body: some View {
        VStack {
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    showTutorial = false
                    onComplete()
                }
                .foregroundColor(Theme.Colors.primary)
            }
            .padding()
            
            Spacer()
            
            // Tutorial content
            TabView(selection: $currentPage) {
                tutorialPage1
                    .tag(0)
                
                tutorialPage2
                    .tag(1)
                
                tutorialPage3
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle())
            
            // Get Started button
            if currentPage == 2 {
                Button(action: {
                    showTutorial = false
                    onComplete()
                }) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.Colors.primary)
                        .cornerRadius(28)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .background(Theme.Colors.background)
    }
    
    private var tutorialPage1: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 80))
                .foregroundColor(Theme.Colors.primary)
            
            Text("Choose Your Dates")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.Colors.text)
            
            Text("Select when you need the item and for how long. The owner will confirm availability.")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var tutorialPage2: some View {
        VStack(spacing: 24) {
            Image(systemName: "message.fill")
                .font(.system(size: 80))
                .foregroundColor(Theme.Colors.primary)
            
            Text("Send a Message")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.Colors.text)
            
            Text("Introduce yourself and explain why you need the item. Good communication builds trust!")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var tutorialPage3: some View {
        VStack(spacing: 24) {
            Image(systemName: "shield.fill")
                .font(.system(size: 80))
                .foregroundColor(Theme.Colors.primary)
            
            Text("Protected & Insured")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.Colors.text)
            
            Text("Every rental is protected by Brrow's insurance. Both parties are covered for peace of mind.")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}