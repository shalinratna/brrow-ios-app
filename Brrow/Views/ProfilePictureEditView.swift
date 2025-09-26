//
//  ProfilePictureEditView.swift
//  Brrow
//
//  Profile picture upload and editing view
//

import SwiftUI
import PhotosUI

struct ProfilePictureEditView: View {
    @StateObject private var viewModel = ProfilePictureEditViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: Theme.Spacing.xl) {
                    // Current Profile Picture
                    profilePictureSection
                    
                    // Upload Options
                    uploadOptionsSection
                    
                    // Guidelines
                    guidelinesSection
                    
                    Spacer()
                    
                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Update Profile Picture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
            .photosPicker(
                isPresented: $viewModel.showPhotoPicker,
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let newItem = newItem {
                        await viewModel.loadPhoto(from: newItem)
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView { image in
                    viewModel.selectedImage = image
                    showCamera = false
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .fullScreenCover(isPresented: $viewModel.showFullscreenPreview) {
                FullscreenImagePreview(
                    image: viewModel.selectedImage,
                    imageUrl: viewModel.currentProfilePicture
                )
            }
        }
    }
    
    // MARK: - Profile Picture Section
    private var profilePictureSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text("Profile Picture")
                .font(.headline)
                .foregroundColor(Theme.Colors.text)
            
            ZStack {
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Theme.Colors.primary, lineWidth: 3)
                        )
                        .onTapGesture {
                            viewModel.showFullscreenPreview = true
                        }
                } else if let currentPicture = viewModel.currentProfilePicture {
                    BrrowAsyncImage(url: currentPicture) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Theme.Colors.border, lineWidth: 2)
                    )
                    .onTapGesture {
                        viewModel.showFullscreenPreview = true
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(Theme.Colors.secondaryText)
                        .frame(width: 200, height: 200)
                }
                
                // Edit Badge
                Circle()
                    .fill(Theme.Colors.primary)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                    )
                    .offset(x: 70, y: 70)
            }
            
            if viewModel.selectedImage != nil {
                Text("New photo selected")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.success)
            }
        }
    }
    
    // MARK: - Upload Options
    private var uploadOptionsSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button {
                viewModel.showPhotoPicker = true
            } label: {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("Choose from Library")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(Theme.CornerRadius.md)
            }
            .foregroundColor(Theme.Colors.text)
            
            Button {
                showCamera = true
            } label: {
                HStack {
                    Image(systemName: "camera")
                    Text("Take Photo")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(Theme.CornerRadius.md)
            }
            .foregroundColor(Theme.Colors.text)
        }
    }
    
    // MARK: - Guidelines
    private var guidelinesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Photo Guidelines")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.text)
            
            VStack(alignment: .leading, spacing: 4) {
                guidelineItem("Clear photo of your face")
                guidelineItem("Well-lit and in focus")
                guidelineItem("No inappropriate content")
                guidelineItem("Maximum size: 10MB")
            }
        }
        .padding()
        .background(Theme.Colors.secondaryBackground.opacity(0.5))
        .cornerRadius(Theme.CornerRadius.md)
    }
    
    private func guidelineItem(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Theme.Colors.success)
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundColor(Theme.Colors.secondaryText)
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: Theme.Spacing.md) {
            Button {
                Task {
                    await viewModel.uploadProfilePicture()
                    if viewModel.uploadSuccess {
                        dismiss()
                    }
                }
            } label: {
                if viewModel.isUploading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                } else {
                    Text("Upload Photo")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
            }
            .background(viewModel.selectedImage != nil ? Theme.Colors.primary : Color.gray)
            .cornerRadius(Theme.CornerRadius.md)
            .disabled(viewModel.selectedImage == nil || viewModel.isUploading)
            
            if viewModel.currentProfilePicture != nil {
                Button {
                    Task {
                        await viewModel.removeProfilePicture()
                        if viewModel.uploadSuccess {
                            dismiss()
                        }
                    }
                } label: {
                    Text("Remove Current Photo")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.Colors.error)
                }
            }
        }
    }
}

// MARK: - View Model
class ProfilePictureEditViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var currentProfilePicture: String?
    @Published var showPhotoPicker = false
    @Published var isUploading = false
    @Published var uploadSuccess = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showFullscreenPreview = false
    
    private let apiClient = APIClient.shared
    private let authManager = AuthManager.shared
    
    init() {
        loadCurrentProfilePicture()
    }
    
    private func loadCurrentProfilePicture() {
        currentProfilePicture = authManager.currentUser?.profilePicture
    }
    
    func loadPhoto(from item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.selectedImage = image
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load photo"
                self.showError = true
            }
        }
    }
    
    func uploadProfilePicture() async {
        guard let image = selectedImage else { return }
        
        await MainActor.run {
            isUploading = true
            showError = false
        }
        
        do {
            // Compress image
            let maxSize: CGFloat = 1000
            guard let resizedImage = image.resized(to: CGSize(width: maxSize, height: maxSize)),
                  let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
                throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
            }
            
            // Upload to server
            let fileName = "profile_\(Date().timeIntervalSince1970).jpg"
            let response = try await apiClient.uploadProfilePicture(imageData, fileName: fileName)
            
            // Update the current user with the new profile picture URL
            await MainActor.run {
                if var currentUser = authManager.currentUser {
                    currentUser.profilePicture = response.data?.url ?? response.data?.thumbnailUrl
                    authManager.updateUser(currentUser)

                    // Clear all image cache to ensure the new profile picture is shown
                    ImageCacheManager.shared.clearCache()
                }
            }
            
            await MainActor.run {
                self.uploadSuccess = true
                self.isUploading = false
                // Small delay to show success before dismissing
                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                    self.uploadSuccess = false
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isUploading = false
            }
        }
    }
    
    func removeProfilePicture() async {
        // Implement profile picture removal
        // This would call an API to remove the profile picture
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    let completion: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.completion(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}


// MARK: - Fullscreen Image Preview
struct FullscreenImagePreview: View {
    let image: UIImage?
    let imageUrl: String?
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                            .tint(.white)
                    }
                }
            }
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                SimultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = max(1.0, min(value, 4.0))
                        },
                    DragGesture()
                        .onChanged { value in
                            offset = value.translation
                        }
                        .onEnded { _ in
                            withAnimation(.spring()) {
                                offset = .zero
                            }
                        }
                )
            )

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onTapGesture(count: 2) {
            withAnimation(.spring()) {
                if scale > 1.0 {
                    scale = 1.0
                    offset = .zero
                } else {
                    scale = 2.0
                }
            }
        }
    }
}

// MARK: - Preview
struct ProfilePictureEditView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilePictureEditView()
    }
}