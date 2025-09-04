import SwiftUI

struct BecomeCreatorView: View {
    @StateObject private var viewModel = BecomeCreatorViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccessAlert = false
    
    var body: some View {
        NavigationView {
            Form {
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
    
    var isValid: Bool {
        !preferredCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !introduction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        preferredCode.count >= 3 &&
        preferredCode.count <= 20 &&
        introduction.count >= 50
    }
    
    func submitApplication() async {
        guard isValid else { return }
        
        isLoading = true
        error = nil
        
        do {
            let response = try await APIClient.shared.submitCreatorApplication(
                preferredCode: preferredCode.trimmingCharacters(in: .whitespacesAndNewlines),
                introduction: introduction.trimmingCharacters(in: .whitespacesAndNewlines),
                socialMediaLinks: socialMediaLinks.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : socialMediaLinks,
                promotionStrategy: promotionStrategy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : promotionStrategy
            )
            
            if response.success {
                applicationSubmitted = true
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