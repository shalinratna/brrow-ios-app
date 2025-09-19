import SwiftUI
import PhotosUI

struct ModernCreateListingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateListingViewModel()
    @StateObject private var authManager = AuthManager.shared
    @State private var currentStep = 0
    @State private var showSuccessAnimation = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var loadedImages: [UIImage] = []
    @State private var showCamera = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isCreatingListing = false
    @State private var showLoginAlert = false
    @State private var uploadProgress: Double = 0
    @State private var uploadStatusText = "Preparing..."
    @State private var listingCreationFailed = false
    @State private var failureMessage = ""
    @State private var showLoadingScreen = false
    @State private var showResultScreen = false
    @State private var isSuccess = false
    @State private var showLocationPermission = false
    @State private var createdListingId: String? = nil
    @FocusState private var focusedField: Field?
    
    // Callback for when listing is successfully created and user wants to view it
    var onViewListing: ((String) -> Void)? = nil
    
    enum Field {
        case title
        case description
        case price
        case tags
    }
    
    // Form data
    @State private var listingType = ""
    @State private var transactionType = "sale"
    @State private var title = ""
    @State private var description = ""
    @State private var category = ""
    @State private var tags: [String] = []
    @State private var price = ""
    @State private var negotiable = false
    
    // Promotion options
    @State private var selectedPromotionType: PromotionType? = nil
    @State private var showPromotionInfo = false
    
    enum PromotionType: String {
        case autoPromote = "auto_promote"
        case payOnSale = "pay_on_sale"
    }
    
    let steps = ["Type", "Details", "Photos", "Pricing", "Review"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress header
                progressHeader
                
                // Step indicator
                stepIndicator
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                
                // Content
                TabView(selection: $currentStep) {
                    typeSelectionStep.tag(0)
                    detailsStep.tag(1)
                    photosStep.tag(2)
                    pricingStep.tag(3)
                    reviewStep.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4), value: currentStep)
                
                // Navigation buttons
                navigationButtons
                    .padding()
                    .background(.ultraThinMaterial)
            }
            .navigationBarHidden(true)
            .onAppear {
                checkLocationPermission()
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker { image in
                    if loadedImages.count < 10 {
                        loadedImages.append(image)
                    }
                }
            }
            .overlay(
                successOverlay
            )
            .alert("Error Creating Listing", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Login Required", isPresented: $showLoginAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Login") {
                    dismiss()
                    // The user will need to login from the main screen
                }
            } message: {
                Text("You need to be logged in to create a listing. Please login and try again.")
            }
            .sheet(isPresented: $showLocationPermission) {
                LocationPermissionView {
                    // Permission granted - request location update
                    viewModel.refreshLocation()
                }
            }
            .fullScreenCover(isPresented: $isCreatingListing) {
                if showResultScreen {
                    ListingResultView(
                        isSuccess: isSuccess,
                        message: isSuccess ? "Your listing is now live!" : (failureMessage.isEmpty ? "Failed to create listing. Please try again." : failureMessage),
                        onDismiss: {
                            isCreatingListing = false
                            showResultScreen = false
                            uploadProgress = 0
                            uploadStatusText = "Preparing..."
                            listingCreationFailed = false
                            if isSuccess {
                                // Store the listing ID before dismissing
                                let savedListingId = createdListingId
                                
                                // Dismiss the view
                                dismiss()
                                
                                // Wait for dismissal to complete before navigating
                                if let listingId = savedListingId, let callback = onViewListing {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                        callback(listingId)
                                    }
                                }
                            }
                        }
                    )
                } else {
                    BrrowLoadingScreen(
                        statusText: uploadStatusText,
                        progress: uploadProgress,
                        onComplete: {
                            // Handled in the main logic
                        }
                    )
                }
            }
        }
    }
    
    private var progressHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(10)
                        .background(Circle().fill(Color(.systemGray5)))
                }
                
                Spacer()
                
                Text("Create Listing")
                    .font(.title2.bold())
                
                Spacer()
                
                Color.clear
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal)
            .padding(.top, 60)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.Colors.primary)
                        .frame(width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(steps.count), height: 8)
                        .animation(.spring(), value: currentStep)
                }
            }
            .frame(height: 8)
            .padding(.horizontal)
        }
    }
    
    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(steps.indices, id: \.self) { index in
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(index <= currentStep ? Theme.Colors.primary : Color(.systemGray5))
                            .frame(width: 30, height: 30)
                        
                        if index < currentStep {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundColor(index == currentStep ? .white : .secondary)
                        }
                    }
                    .scaleEffect(index == currentStep ? 1.2 : 1.0)
                    .animation(.spring(), value: currentStep)
                    
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Theme.Colors.primary : Color(.systemGray5))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
    
    private var typeSelectionStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("What are you listing?")
                    .font(.largeTitle.bold())
                    .padding(.top, 20)
                
                Text("Choose the type that best describes your listing")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 16) {
                    ListingTypeButton(
                        title: "Product",
                        icon: "bag.fill",
                        description: "Physical items for sale or rent",
                        isSelected: listingType == "product",
                        action: { 
                            listingType = "product"
                            HapticManager.impact(style: .light)
                        }
                    )
                    
                    ListingTypeButton(
                        title: "Service",
                        icon: "wrench.and.screwdriver.fill",
                        description: "Skills and services offered",
                        isSelected: listingType == "service",
                        action: { 
                            listingType = "service"
                            HapticManager.impact(style: .light)
                        }
                    )
                }
                .padding()
                
                if !listingType.isEmpty {
                    VStack(spacing: 12) {
                        Text("How do you want to offer this?")
                            .font(.headline)
                            .padding(.top)
                        
                        HStack(spacing: 16) {
                            TransactionTypeButton(
                                title: "For Sale",
                                icon: "tag.fill",
                                isSelected: transactionType == "sale",
                                action: { transactionType = "sale" }
                            )
                            
                            TransactionTypeButton(
                                title: "For Rent",
                                icon: "arrow.triangle.2.circlepath",
                                isSelected: transactionType == "rental",
                                action: { transactionType = "rental" }
                            )
                        }
                        .padding(.horizontal)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
    
    private var detailsStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Tell us about it")
                    .font(.largeTitle.bold())
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        
                        TextField("Give your listing a catchy title", text: $title)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Description")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(description.count)/10 min")
                                .font(.caption)
                                .foregroundColor(description.count < 10 ? .red : .secondary)
                        }
                        
                        TextEditor(text: $description)
                            .padding(8)
                            .frame(minHeight: 120)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                            .focused($focusedField, equals: .description)
                    }
                    
                    // Category
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        
                        Menu {
                            ForEach(CategoryHelper.getAllCategories(), id: \.self) { cat in
                                Button(action: { 
                                    category = cat
                                    focusedField = nil  // Dismiss keyboard
                                }) {
                                    Label(cat, systemImage: CategoryHelper.getCategoryIcon(for: cat))
                                }
                            }
                        } label: {
                            HStack {
                                Text(category.isEmpty ? "Select a category" : category)
                                    .foregroundColor(category.isEmpty ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                        }
                        .simultaneousGesture(TapGesture().onEnded { _ in
                            focusedField = nil  // Dismiss keyboard when menu opens
                        })
                    }
                }
                .padding()
            }
        }
    }
    
    private var photosStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Add photos")
                    .font(.largeTitle.bold())
                    .padding(.top, 20)
                
                Text("Add up to 10 photos")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(loadedImages.indices, id: \.self) { index in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: loadedImages[index])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 110, height: 110)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Button(action: {
                                loadedImages.remove(at: index)
                                HapticManager.impact(style: .light)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.6)))
                            }
                            .padding(4)
                        }
                    }
                    
                    if loadedImages.count < 10 {
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: 10 - loadedImages.count,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .frame(width: 110, height: 110)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "camera.fill")
                                            .font(.title2)
                                            .foregroundColor(.secondary)
                                        Text("Add Photos")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                )
                        }
                        .onChange(of: selectedPhotos) { newPhotos in
                            Task {
                                for photo in newPhotos {
                                    if let data = try? await photo.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data),
                                       loadedImages.count < 10 {
                                        // Resize image immediately after loading to save memory
                                        let optimizedImage = uiImage.resizedWithAspectRatio(maxDimension: 1200)
                                        loadedImages.append(optimizedImage)
                                    }
                                }
                                selectedPhotos.removeAll()
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var pricingStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Set your price")
                    .font(.largeTitle.bold())
                    .padding(.top, 20)
                
                HStack(spacing: 4) {
                    Text("$")
                        .font(.largeTitle.bold())
                        .foregroundColor(Theme.Colors.primary)
                    
                    TextField("0", text: $price)
                        .font(.system(size: 48, weight: .bold))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 150)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemGray6)))
                
                Toggle("Allow negotiations", isOn: $negotiable)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                    .padding(.horizontal)
            }
        }
    }
    
    private var reviewStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Review & Publish")
                    .font(.largeTitle.bold())
                    .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 16) {
                    ModernSummaryRow(label: "Type", value: listingType.capitalized)
                    ModernSummaryRow(label: "Transaction", value: transactionType.capitalized)
                    ModernSummaryRow(label: "Title", value: title)
                    ModernSummaryRow(label: "Category", value: category)
                    ModernSummaryRow(label: "Price", value: "$\(price)")
                    ModernSummaryRow(label: "Negotiable", value: negotiable ? "Yes" : "No")
                    ModernSummaryRow(label: "Photos", value: "\(loadedImages.count)")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
                .padding(.horizontal)
            }
        }
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button(action: {
                    // Dismiss keyboard before moving to previous step
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    
                    withAnimation {
                        currentStep -= 1
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray5)))
                }
            }
            
            Button(action: {
                // Dismiss keyboard before moving to next step
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                
                if currentStep < steps.count - 1 {
                    withAnimation {
                        currentStep += 1
                    }
                } else {
                    createListing()
                }
            }) {
                HStack {
                    Text(currentStep == steps.count - 1 ? "Create Listing" : "Continue")
                    if currentStep < steps.count - 1 {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isStepValid ? Theme.Colors.primary : Color(.systemGray4))
                )
            }
            .disabled(!isStepValid || isCreatingListing)
        }
    }
    
    private var isStepValid: Bool {
        switch currentStep {
        case 0: return !listingType.isEmpty
        case 1: return !title.isEmpty && description.count >= 10 && !category.isEmpty
        case 2: return !loadedImages.isEmpty
        case 3: return !price.isEmpty && Double(price) ?? 0 > 0
        case 4: return true
        default: return false
        }
    }
    
    private var successOverlay: some View {
        Group {
            if showSuccessAnimation {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text("Listing Created!")
                            .font(.title.bold())
                        
                        Text("Your listing is now live")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(40)
                    .background(RoundedRectangle(cornerRadius: 30).fill(.regularMaterial))
                }
            }
        }
    }
    
    private func createListing() {
        guard !isCreatingListing else {
            print("⚠️ Listing creation already in progress")
            return
        }
        
        // Check if user is logged in
        guard authManager.isAuthenticated else {
            showLoginAlert = true
            return
        }
        
        // Check location permission
        let locationStatus = LocationService.shared.authorizationStatus
        if locationStatus == .notDetermined || locationStatus == .denied || locationStatus == .restricted {
            showLocationPermission = true
            return
        }
        
        isCreatingListing = true
        showResultScreen = false
        uploadProgress = 0
        uploadStatusText = "Preparing images..."
        
        Task {
            await performListingCreation()
        }
    }
    
    private func performListingCreation() async {
        do {
                // Reset progress
                let totalImages = loadedImages.count
                var completedUploads = 0
                
                uploadStatusText = "Uploading \(totalImages) image\(totalImages == 1 ? "" : "s")..."
                
                // Upload images sequentially to avoid cancellation issues
                var uploadedImageUrls: [String] = []
                
                for (index, image) in loadedImages.enumerated() {
                    // Check if task is cancelled
                    try Task.checkCancellation()
                    
                    // Update status
                    await MainActor.run {
                        uploadStatusText = "Uploading image \(index + 1) of \(totalImages)..."
                    }
                    
                    // Use optimized compression (already resized when loaded)
                    if let imageData = image.optimizedForUpload(maxDimension: 1200, compressionQuality: 0.7) {
                        let fileName = "listing_\(Date().timeIntervalSince1970)_\(index).jpg"
                        
                        do {
                            let url = try await APIClient.shared.uploadFile(imageData, fileName: fileName)
                            uploadedImageUrls.append(url)
                            
                            // Update progress on main thread
                            await MainActor.run {
                                completedUploads += 1
                                uploadProgress = Double(completedUploads) / Double(totalImages) * 0.8 // 80% for uploads
                                uploadStatusText = "Uploaded \(completedUploads) of \(totalImages) images"
                            }
                            
                            print("✅ Successfully uploaded image \(index + 1)/\(totalImages)")
                        } catch {
                            print("❌ Failed to upload image \(index + 1): \(error)")
                            // Continue with other images even if one fails
                        }
                    }
                    
                    // Small delay between uploads to avoid overwhelming the server
                    if index < loadedImages.count - 1 {
                        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                    }
                }
                
                // Check if we have at least some images uploaded
                if loadedImages.count > 0 && uploadedImageUrls.isEmpty {
                    throw BrrowAPIError.networkError("Failed to upload images. Please check your connection and try again.")
                }
                
                // Update status for creating listing
                uploadProgress = 0.9
                uploadStatusText = "Creating your listing..."
                
                // Check if promotion is selected
                if let promotionType = selectedPromotionType {
                    let listing = CreateListingRequest(
                        title: title,
                        description: description,
                        dailyRate: Double(price) ?? 0,  // Changed to dailyRate for Railway backend
                        categoryId: "default-category",
                        condition: "GOOD",
                        location: Location(
                            address: "123 Main Street",
                            city: "San Francisco",
                            state: "CA",
                            zipCode: "94102",
                            country: "US",
                            latitude: viewModel.currentCoordinate?.latitude ?? 37.7749,
                            longitude: viewModel.currentCoordinate?.longitude ?? -122.4194
                        ),
                        isNegotiable: true,
                        deliveryOptions: DeliveryOptions(pickup: true, delivery: false, shipping: false),
                        tags: [],
                        images: uploadedImageUrls,  // Send URLs as simple strings
                        videos: nil
                    )
                    let promotion = PromotionRequest(
                        type: promotionType.rawValue,
                        duration: 7 // 7 days default
                    )
                    let request = CreateListingWithPromotionRequest(
                        listing: listing,
                        promotion: promotion
                    )
                    
                    let response = try await APIClient.shared.createListingWithPromotion(request)
                    if let listing = response.listing {
                        createdListingId = listing.listingId
                    }
                } else {
                    let request = CreateListingRequest(
                        title: title,
                        description: description,
                        dailyRate: Double(price) ?? 0,  // Changed to dailyRate for Railway backend
                        categoryId: "default-category",
                        condition: "GOOD",
                        location: Location(
                            address: "123 Main Street",
                            city: "San Francisco",
                            state: "CA",
                            zipCode: "94102",
                            country: "US",
                            latitude: viewModel.currentCoordinate?.latitude ?? 37.7749,
                            longitude: viewModel.currentCoordinate?.longitude ?? -122.4194
                        ),
                        isNegotiable: true,
                        deliveryOptions: DeliveryOptions(pickup: true, delivery: false, shipping: false),
                        tags: [],
                        images: uploadedImageUrls,  // Send URLs as simple strings
                        videos: nil
                    )
                    
                    let listing = try await APIClient.shared.createListing(request)
                    createdListingId = listing.listingId
                }
                
                await MainActor.run {
                    uploadProgress = 1.0
                    uploadStatusText = "Success!"
                    
                    // Track achievement for creating listing
                    AchievementManager.shared.trackListingCreated()
                    
                    HapticManager.notification(type: .success)
                    
                    // Transition to success screen
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isSuccess = true
                        showResultScreen = true
                    }
                }
            } catch {
                await MainActor.run {
                    uploadProgress = 0
                    uploadStatusText = "Failed"
                    listingCreationFailed = true
                    
                    // More specific error handling
                    if let apiError = error as? BrrowAPIError {
                        failureMessage = apiError.localizedDescription
                    } else if let decodingError = error as? DecodingError {
                        // For debugging decoding issues
                        switch decodingError {
                        case .keyNotFound(let key, _):
                            failureMessage = "Missing field: \(key.stringValue)"
                        case .typeMismatch(_, let context):
                            failureMessage = "Type mismatch: \(context.debugDescription)"
                        case .valueNotFound(_, let context):
                            failureMessage = "Value not found: \(context.debugDescription)"
                        case .dataCorrupted(let context):
                            failureMessage = "Data corrupted: \(context.debugDescription)"
                        @unknown default:
                            failureMessage = "Unknown decoding error"
                        }
                    } else {
                        failureMessage = error.localizedDescription
                    }
                    
                    HapticManager.notification(type: .error)
                    
                    // Transition to failure screen
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isSuccess = false
                        showResultScreen = true
                    }
                }
            }
        }
    
    private func checkLocationPermission() {
        let status = LocationService.shared.authorizationStatus
        
        // Show permission view if not determined
        if status == .notDetermined {
            // Don't show immediately on appear, wait for user to interact
            return
        }
        
        // If denied or restricted, we'll show the permission view when they try to create
        if status == .denied || status == .restricted {
            // Will handle when user tries to submit
            return
        }
    }
    
}

// MARK: - Supporting Views

struct ListingTypeButton: View {
    let title: String
    let icon: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : Theme.Colors.primary)
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Theme.Colors.primary : Theme.Colors.primary.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Theme.Colors.primary : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct TransactionTypeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : Theme.Colors.primary)
                
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Theme.Colors.primary : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}

struct ModernSummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }
}

// MARK: - Preview

struct ModernCreateListingView_Previews: PreviewProvider {
    static var previews: some View {
        ModernCreateListingView()
    }
}