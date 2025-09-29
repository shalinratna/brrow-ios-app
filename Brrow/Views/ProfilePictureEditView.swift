//
//  ProfilePictureEditView.swift
//  Brrow
//
//  Profile picture upload and editing view
//

import SwiftUI
import PhotosUI

// Helper struct for fullScreenCover with item
struct ImageWrapper: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ProfilePictureEditView: View {
    @StateObject private var viewModel = ProfilePictureEditViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showCircularCropper = false
    @State private var imageForCropping: UIImage?
    
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
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading:
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(Theme.Colors.primary)
            )
            .photosPicker(
                isPresented: $viewModel.showPhotoPicker,
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: selectedItem) { newItem in
                print("🖼️ ProfilePictureEdit: selectedItem changed, newItem: \(newItem != nil ? "present" : "nil")")
                Task {
                    if let newItem = newItem {
                        print("🖼️ ProfilePictureEdit: Starting photo loading task for newItem")
                        await loadPhotoForCropping(from: newItem)
                    } else {
                        print("🖼️ ProfilePictureEdit: newItem is nil, skipping photo loading")
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView { image in
                    imageForCropping = image
                    showCamera = false
                    showCircularCropper = true
                }
            }
            .fullScreenCover(item: Binding<ImageWrapper?>(
                get: {
                    if showCircularCropper, let image = imageForCropping {
                        return ImageWrapper(image: image)
                    }
                    return nil
                },
                set: { wrapper in
                    if wrapper == nil {
                        showCircularCropper = false
                        imageForCropping = nil
                    }
                }
            )) { wrapper in
                CircularImageCropper(
                    image: wrapper.image,
                    onCropComplete: { croppedImage, cropData in
                        print("🖼️ ProfilePictureEdit: Crop completed successfully")
                        viewModel.selectedImage = croppedImage
                        viewModel.cropData = cropData
                        showCircularCropper = false
                        imageForCropping = nil
                    },
                    onCancel: {
                        print("🖼️ ProfilePictureEdit: Crop cancelled")
                        showCircularCropper = false
                        imageForCropping = nil
                    }
                )
                .onAppear {
                    print("✅ ProfilePictureEdit: CircularImageCropper view appeared successfully!")
                    print("🖼️ ProfilePictureEdit: Image size: \(wrapper.image.size)")
                }
                .onDisappear {
                    print("🔄 ProfilePictureEdit: CircularImageCropper view disappeared")
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
                print("🖼️ ProfilePictureEdit: Choose from Library button pressed")
                viewModel.showPhotoPicker = true
                print("🖼️ ProfilePictureEdit: Set showPhotoPicker to true")
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
                    Text(viewModel.cropData != nil ? "Upload Cropped Photo" : "Select Photo to Upload")
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

    // MARK: - Photo Loading for Cropping
    private func loadPhotoForCropping(from item: PhotosPickerItem) async {
        print("🖼️ ProfilePictureEdit: Starting to load photo for cropping")
        do {
            print("🖼️ ProfilePictureEdit: Loading transferable data...")
            if let data = try await item.loadTransferable(type: Data.self) {
                print("🖼️ ProfilePictureEdit: Data loaded, size: \(data.count) bytes")
                if let image = UIImage(data: data) {
                    print("🖼️ ProfilePictureEdit: UIImage created successfully, size: \(image.size)")

                    // Resize large images for better performance in the cropper
                    let resizedImage = self.resizeImageForCropping(image)
                    print("🖼️ ProfilePictureEdit: Resized image to: \(resizedImage.size)")

                    await MainActor.run {
                        print("🖼️ ProfilePictureEdit: Setting imageForCropping and showing cropper")
                        self.imageForCropping = resizedImage
                        self.showCircularCropper = true
                        print("🖼️ ProfilePictureEdit: Both imageForCropping and showCircularCropper set")
                    }
                } else {
                    print("❌ ProfilePictureEdit: Failed to create UIImage from data")
                    await MainActor.run {
                        viewModel.errorMessage = "Failed to process selected image"
                        viewModel.showError = true
                    }
                }
            } else {
                print("❌ ProfilePictureEdit: Failed to load transferable data")
                await MainActor.run {
                    viewModel.errorMessage = "Failed to load selected photo"
                    viewModel.showError = true
                }
            }
        } catch {
            print("❌ ProfilePictureEdit: Error loading photo: \(error)")
            await MainActor.run {
                viewModel.errorMessage = "Failed to load photo for cropping: \(error.localizedDescription)"
                viewModel.showError = true
            }
        }
    }

    // MARK: - Image Resize Helper
    private func resizeImageForCropping(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1200 // Reasonable size for cropping UI
        let currentSize = image.size

        // Only resize if the image is larger than our max dimension
        if currentSize.width <= maxDimension && currentSize.height <= maxDimension {
            return image
        }

        let scale = min(maxDimension / currentSize.width, maxDimension / currentSize.height)
        let newSize = CGSize(width: currentSize.width * scale, height: currentSize.height * scale)

        return image.resized(to: newSize) ?? image
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

    // Crop data for Instagram-style cropping
    var cropData: CropData?
    
    private let apiClient = APIClient.shared
    private let authManager = AuthManager.shared
    
    init() {
        loadCurrentProfilePicture()
        setupNotificationListeners()
    }

    private func setupNotificationListeners() {
        NotificationCenter.default.addObserver(
            forName: .profilePictureUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let newProfilePictureUrl = notification.object as? String {
                self?.currentProfilePicture = newProfilePictureUrl
                print("🔄 Profile picture view refreshed with new URL: \(newProfilePictureUrl)")
            }
        }
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

            // Upload to server - use the new method with crop data support
            let profilePictureUrl = try await apiClient.uploadProfilePictureWithCrop(
                imageData: imageData,
                cropData: cropData
            )

            // Update the current user with the new profile picture URL
            await MainActor.run {
                print("✅ Profile upload successful! New URL: \(profilePictureUrl)")

                if var currentUser = authManager.currentUser {
                    currentUser.profilePicture = profilePictureUrl
                    authManager.updateUser(currentUser)

                    // Clear all image cache to ensure the new profile picture is shown
                    ImageCacheManager.shared.clearCache()

                    // Also clear iOS URL cache to prevent old image from being served
                    URLCache.shared.removeAllCachedResponses()
                    print("🧹 Cleared both ImageCache and URLCache")

                    // Clear the selected image to show the uploaded version
                    self.selectedImage = nil

                    // Force refresh by clearing current picture and then setting new one
                    self.currentProfilePicture = nil

                    // Small delay to ensure cache clearing takes effect before setting new URL
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.currentProfilePicture = profilePictureUrl
                        print("🔄 Profile picture display updated to: \(profilePictureUrl)")
                    }

                    print("✅ Local user updated with new profile picture")
                    print("✅ Image cache cleared")
                    print("✅ Current profile picture updated to: \(profilePictureUrl)")

                    // Send notifications to refresh any profile views
                    NotificationCenter.default.post(name: .profilePictureUpdated, object: profilePictureUrl)

                    // Also trigger a general UI refresh for profile-related views
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshUserProfile"), object: nil)
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
            print("❌ Profile picture upload error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")

            await MainActor.run {
                // Provide more helpful error messages
                if error.localizedDescription.contains("data couldn't be read") {
                    self.errorMessage = "Server response error. Please try again in a moment."
                } else if error.localizedDescription.contains("timeout") {
                    self.errorMessage = "Upload timed out. Please check your connection and try again."
                } else if error.localizedDescription.contains("network") {
                    self.errorMessage = "Network error. Please check your internet connection."
                } else {
                    self.errorMessage = "Upload failed: \(error.localizedDescription)"
                }
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