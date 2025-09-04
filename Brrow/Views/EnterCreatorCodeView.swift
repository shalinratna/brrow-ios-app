import SwiftUI

struct EnterCreatorCodeView: View {
    @StateObject private var viewModel = EnterCreatorCodeViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccessAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color(hex: "#2ABF5A"))
                    
                    Text("Have a Creator Code?")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter a creator code to support your favorite content creator. They'll earn 1% on all your future transactions!")
                        .font(.callout)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // Code Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("CREATOR CODE")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    TextField("Enter code", text: $viewModel.creatorCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.title3)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Submit Button
                Button {
                    Task {
                        await viewModel.submitCode()
                    }
                } label: {
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            Text("Applying Code...")
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("Apply Code")
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(viewModel.creatorCode.isEmpty || viewModel.isLoading ? Color.gray : Color(hex: "#2ABF5A"))
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(viewModel.creatorCode.isEmpty || viewModel.isLoading)
                .padding(.horizontal)
                
                // Skip Button
                Button("Skip for Now") {
                    dismiss()
                }
                .foregroundColor(.gray)
                .padding(.bottom, 30)
            }
            .navigationTitle("Creator Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success!", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(viewModel.successMessage ?? "Creator code applied successfully!")
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }
}

// MARK: - View Model

@MainActor
class EnterCreatorCodeViewModel: ObservableObject {
    @Published var creatorCode = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published var successMessage: String?
    
    func submitCode() async {
        guard !creatorCode.isEmpty else { return }
        
        isLoading = true
        error = nil
        
        do {
            let response = try await APIClient.shared.setCreatorReferral(
                code: creatorCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            )
            
            if response.success {
                successMessage = response.message
                
                // The user's referral code will be updated on next login/refresh
                // We can't update the immutable User struct directly
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

struct SetCreatorReferralResponse: Codable {
    let success: Bool
    let message: String
    let creatorUsername: String?
    
    private enum CodingKeys: String, CodingKey {
        case success
        case message
        case creatorUsername = "creator_username"
    }
}