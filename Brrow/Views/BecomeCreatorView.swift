import SwiftUI

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
            let response = try await apiClient.getCreatorStatus()

            hasExistingApplication = response.status != nil && !response.status!.isEmpty
            canApply = !response.isCreator && (response.status == nil || response.status!.isEmpty)
            applicationStatus = response.status ?? ""

            // Show status-specific messages
            if !canApply {
                if applicationStatus == "PENDING" {
                    error = "You already have a pending creator application. Please wait for our review."
                } else if applicationStatus == "APPROVED" {
                    error = "Congratulations! You're already a Brrow creator."
                } else if applicationStatus == "REJECTED" {
                    error = "Previous application was rejected. Please contact support to reapply."
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

        let applicationData: [String: Any] = [
            "motivation": introduction.trimmingCharacters(in: .whitespacesAndNewlines),
            "experience": introduction.trimmingCharacters(in: .whitespacesAndNewlines),
            "platform": socialMediaLinks.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : socialMediaLinks,
            "referral_strategy": promotionStrategy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : promotionStrategy,
            "agreement_accepted": true
        ].compactMapValues { $0 }

        do {
            let response: CreatorApplicationResponse = try await apiClient.request(
                "/api/creators/apply",
                method: .POST,
                parameters: applicationData,
                responseType: CreatorApplicationResponse.self
            )

            if response.success {
                applicationSubmitted = true
                hasExistingApplication = true
                canApply = false
                applicationStatus = "PENDING"
            } else {
                error = response.message
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - API Response

struct CreatorApplicationResponse: Codable {
    let success: Bool
    let message: String
    let applicationId: Int?
    
    private enum CodingKeys: String, CodingKey {
        case success
        case message
        case applicationId = "application_id"
    }
}