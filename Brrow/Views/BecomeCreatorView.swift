import SwiftUI

/*
 * CREATOR SYSTEM STATUS: HIDDEN BUT FUNCTIONAL
 *
 * This Creator Application System is fully implemented and functional but intentionally hidden from the main UI.
 * The system includes:
 * - Complete database schema (creator_applications table)
 * - Full backend API endpoints (/api/creators/apply, /api/creators/application, etc.)
 * - Discord webhook integration for notifications
 * - iOS models and services with proper encoding/decoding
 * - Caching and preloading functionality
 *
 * To re-enable the Creator system in the future:
 * 1. Add navigation to BecomeCreatorView in settings or profile
 * 2. Add Creator dashboard access for approved creators
 * 3. Uncomment any Creator-related navigation code
 *
 * All functionality remains intact and ready for production use.
 */

struct BecomeCreatorView: View {
    @StateObject private var viewModel = BecomeCreatorViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccessAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // Header Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "star.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(Color(hex: "#2ABF5A"))

                            VStack(alignment: .leading) {
                                Text("Become a Creator")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text("Earn 1% on all referrals")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 8)

                        Text("Join our creator program and earn commission when people sign up using your unique code!")
                            .font(.callout)
                            .foregroundColor(.gray)
                    }
                }

                // Application Status Section (if exists)
                if viewModel.hasExistingApplication {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: viewModel.applicationStatus == "APPROVED" ? "checkmark.circle.fill" :
                                     viewModel.applicationStatus == "PENDING" ? "clock.circle.fill" : "x.circle.fill")
                                    .foregroundColor(viewModel.applicationStatus == "APPROVED" ? .green :
                                                   viewModel.applicationStatus == "PENDING" ? .orange : .red)

                                VStack(alignment: .leading) {
                                    Text("Application Status")
                                        .font(.headline)
                                    Text(viewModel.applicationStatus.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }

                            if let errorMessage = viewModel.error, !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.callout)
                                    .foregroundColor(viewModel.applicationStatus == "APPROVED" ? .green : .primary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                // Only show application form if user can apply
                if viewModel.canApply {
                
                Section(header: Text("PREFERRED CREATOR CODE")) {
                    TextField("Enter your desired code", text: $viewModel.preferredCode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    Text("This will be your unique referral code (e.g., JOHN123)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("TELL US ABOUT YOURSELF")) {
                    TextEditor(text: $viewModel.introduction)
                        .frame(minHeight: 100)
                    
                    Text("Why do you want to be a Brrow creator? How will you promote Brrow?")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("SOCIAL MEDIA (OPTIONAL)")) {
                    TextField("Instagram, TikTok, YouTube, etc.", text: $viewModel.socialMediaLinks)
                        .textInputAutocapitalization(.never)
                    
                    Text("Share your social media profiles or website")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("PROMOTION STRATEGY")) {
                    TextEditor(text: $viewModel.promotionStrategy)
                        .frame(minHeight: 80)
                    
                    Text("How do you plan to promote Brrow to your audience?")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section {
                    VStack(spacing: 16) {
                        Text("By applying, you agree to:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Promote Brrow responsibly", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Label("Not use misleading marketing", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Label("Follow Brrow's creator guidelines", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button {
                        Task {
                            await viewModel.submitApplication()
                        }
                    } label: {
                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Submitting...")
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Text("Submit Application")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(Color(hex: "#2ABF5A"))
                    .disabled(viewModel.isLoading || !viewModel.isValid)
                }

                } // End of canApply conditional
            }
            .navigationTitle("Creator Application")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Application Submitted!", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for applying! We'll review your application and email you within 24-48 hours.")
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error ?? "")
            }
            .onChange(of: viewModel.applicationSubmitted) { _, submitted in
                if submitted {
                    showSuccessAlert = true
                }
            }
        }
    }
}

// MARK: - View Model

@MainActor
class BecomeCreatorViewModel: ObservableObject {
    @Published var preferredCode = ""
    @Published var introduction = ""
    @Published var socialMediaLinks = ""
    @Published var promotionStrategy = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published var applicationSubmitted = false

    // Application status tracking (one per account limit)
    @Published var hasExistingApplication = false
    @Published var applicationStatus = ""
    @Published var canApply = true

    private let apiClient = APIClient.shared

    init() {
        Task {
            await checkExistingApplication()
        }
    }

    var isValid: Bool {
        !introduction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        introduction.count >= 50 &&
        canApply
    }

    // Check if user already has an application (one per account limit)
    func checkExistingApplication() async {
        isLoading = true
        error = nil

        do {
            let response = try await apiClient.getCreatorApplicationStatus()

            hasExistingApplication = response.hasApplication
            canApply = response.canApply

            if let application = response.application {
                applicationStatus = application.status.rawValue

                // Show status-specific messages
                if !canApply {
                    switch application.status {
                    case .pending:
                        error = "You already have a pending creator application. Please wait for our review."
                    case .approved:
                        error = "Congratulations! You're already a Brrow creator."
                    case .rejected:
                        if let reason = application.rejectionReason {
                            error = "Previous application was rejected: \(reason). Please contact support to reapply."
                        } else {
                            error = "Previous application was rejected. Please contact support to reapply."
                        }
                    case .underReview:
                        error = "Your application is under review. Please wait for our response."
                    }
                }
            }
        } catch {
            print("Failed to check application status: \(error)")
        }

        isLoading = false
    }

    func submitApplication() async {
        guard isValid else { return }
        guard canApply else {
            error = "You already have an application submitted."
            return
        }

        isLoading = true
        error = nil

        do {
            let response = try await apiClient.submitCreatorApplication(
                motivation: introduction.trimmingCharacters(in: .whitespacesAndNewlines),
                experience: introduction.trimmingCharacters(in: .whitespacesAndNewlines),
                businessName: nil,
                businessDescription: nil,
                experienceYears: nil,
                portfolioLinks: socialMediaLinks.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : socialMediaLinks,
                expectedMonthlyRevenue: nil,
                platform: socialMediaLinks.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : socialMediaLinks,
                followers: nil,
                contentType: nil,
                referralStrategy: promotionStrategy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : promotionStrategy
            )

            applicationSubmitted = true
            hasExistingApplication = true
            canApply = false
            applicationStatus = "PENDING"
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}