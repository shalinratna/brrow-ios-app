import SwiftUI
import PhotosUI

struct FuturisticCreateListingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var animateIn = false
    @State private var rippleEffect = false
    @State private var glowAnimation = false
    @State private var floatingAnimation = false
    
    // Form Data
    @State private var listingType = ""
    @State private var title = ""
    @State private var description = ""
    @State private var category = ""
    @State private var price = ""
    @State private var isRental = false
    @State private var condition = "New"
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var loadedImages: [UIImage] = []
    @State private var tags: [String] = []
    @State private var selectedPromotion: PromotionType? = nil
    
    // UI States
    @State private var showSuccessAnimation = false
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var gradientRotation = 0.0
    @State private var particleAnimation = false
    
    enum PromotionType: String, CaseIterable {
        case none = "none"
        case featured = "featured"
        case spotlight = "spotlight"
        
        var title: String {
            switch self {
            case .none: return "Standard Listing"
            case .featured: return "Featured (10% upfront)"
            case .spotlight: return "Spotlight (3% on sale)"
            }
        }
        
        var icon: String {
            switch self {
            case .none: return "square.grid.2x2"
            case .featured: return "star.fill"
            case .spotlight: return "sparkles"
            }
        }
        
        var color: Color {
            switch self {
            case .none: return .gray
            case .featured: return .orange
            case .spotlight: return .purple
            }
        }
    }
    
    let categories = [
        ("Electronics", "tv.fill", Color.blue),
        ("Fashion", "tshirt.fill", Color.pink),
        ("Home", "house.fill", Color.green),
        ("Sports", "sportscourt.fill", Color.orange),
        ("Books", "book.fill", Color.purple),
        ("Tools", "hammer.fill", Color.red),
        ("Games", "gamecontroller.fill", Color.indigo),
        ("Other", "ellipsis.circle.fill", Color.gray)
    ]
    
    let conditions = ["New", "Like New", "Good", "Fair", "For Parts"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated background
                animatedBackground
                
                VStack(spacing: 0) {
                    // Futuristic header
                    futuristicHeader
                    
                    // Progress indicator
                    progressIndicator
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    
                    // Content with 3D card effect
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Step content
                            Group {
                                switch currentStep {
                                case 0:
                                    typeSelectionView
                                case 1:
                                    detailsView
                                case 2:
                                    photosView
                                case 3:
                                    pricingView
                                case 4:
                                    reviewView
                                default:
                                    EmptyView()
                                }
                            }
                            .padding(.horizontal, 20)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            
                            // Navigation buttons
                            navigationButtons
                                .padding(.horizontal, 20)
                                .padding(.bottom, 40)
                        }
                    }
                }
                
                // Success overlay
                if showSuccessAnimation {
                    successOverlay
                }
                
                // Floating particles
                floatingParticles
            }
            .navigationBarHidden(true)
            .onAppear {
                startAnimations()
            }
        }
    }
    
    // MARK: - Animated Background
    private var animatedBackground: some View {
        ZStack {
            // Gradient mesh
            MeshGradient(
                colors: [
                    Color(#colorLiteral(red: 0.5568627451, green: 0.2666666667, blue: 0.6784313725, alpha: 1)),
                    Color(#colorLiteral(red: 0.2588235294, green: 0.5254901961, blue: 0.9568627451, alpha: 1)),
                    Color(#colorLiteral(red: 0.9098039216, green: 0.2666666667, blue: 0.5843137255, alpha: 1)),
                    Color(#colorLiteral(red: 0.9568627451, green: 0.6431372549, blue: 0.3764705882, alpha: 1))
                ],
                rotation: gradientRotation
            )
            .ignoresSafeArea()
            
            // Glass overlay
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.7)
                .ignoresSafeArea()
        }
    }
    
    // MARK: - Futuristic Header
    private var futuristicHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Create Listing")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text("Step \(currentStep + 1) of 5")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Help button
            Button(action: {}) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 20)
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 8)
                
                // Progress fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple, Color.pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(currentStep + 1) / 5, height: 8)
                    .animation(.spring(response: 0.5), value: currentStep)
                
                // Glow effect
                if glowAnimation {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.8), Color.white.opacity(0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 50, height: 8)
                        .offset(x: geometry.size.width * CGFloat(currentStep + 1) / 5 - 25)
                        .blur(radius: 10)
                }
            }
        }
        .frame(height: 8)
    }
    
    // MARK: - Type Selection View
    private var typeSelectionView: some View {
        VStack(spacing: 20) {
            Text("What are you listing?")
                .font(.title.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                TypeCard(
                    title: "Sell an Item",
                    subtitle: "One-time sale to a buyer",
                    icon: "tag.fill",
                    color: .green,
                    isSelected: !isRental
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        isRental = false
                        HapticManager.impact(style: .light)
                    }
                }
                
                TypeCard(
                    title: "Rent it Out",
                    subtitle: "Earn recurring income",
                    icon: "arrow.triangle.2.circlepath",
                    color: .blue,
                    isSelected: isRental
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        isRental = true
                        HapticManager.impact(style: .light)
                    }
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .scaleEffect(animateIn ? 1 : 0.8)
        .animation(.spring(response: 0.6).delay(0.2), value: animateIn)
    }
    
    // MARK: - Details View
    private var detailsView: some View {
        VStack(spacing: 20) {
            // Title field
            FuturisticTextField(
                text: $title,
                placeholder: "Give it a catchy title",
                icon: "text.cursor",
                gradient: [.purple, .pink]
            )
            
            // Category selector
            VStack(alignment: .leading, spacing: 12) {
                Label("Category", systemImage: "square.grid.3x3.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(categories, id: \.0) { cat in
                        FuturisticCategoryChip(
                            title: cat.0,
                            icon: cat.1,
                            color: cat.2,
                            isSelected: category == cat.0
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                category = cat.0
                                HapticManager.impact(style: .light)
                            }
                        }
                    }
                }
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Label("Description", systemImage: "text.alignleft")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextEditor(text: $description)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Condition picker
            VStack(alignment: .leading, spacing: 8) {
                Label("Condition", systemImage: "star.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(conditions, id: \.self) { cond in
                            FuturisticConditionChip(
                                title: cond,
                                isSelected: condition == cond
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    condition = cond
                                    HapticManager.impact(style: .light)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Photos View
    private var photosView: some View {
        VStack(spacing: 20) {
            Text("Add Photos")
                .font(.title.bold())
                .foregroundColor(.white)
            
            Text("Add up to 10 photos to showcase your item")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            // Photo grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // Loaded images
                ForEach(Array(loadedImages.enumerated()), id: \.offset) { index, image in
                    PhotoThumbnail(image: image, index: index) {
                        removeImage(at: index)
                    }
                }
                
                // Add photo button
                if loadedImages.count < 10 {
                    PhotosPicker(selection: $selectedPhotos,
                               maxSelectionCount: 10 - loadedImages.count,
                               matching: .images) {
                        AddPhotoButton()
                    }
                }
            }
            
            // Photo tips
            VStack(alignment: .leading, spacing: 8) {
                PhotoTip(icon: "camera.fill", text: "Use natural lighting")
                PhotoTip(icon: "square.on.square", text: "Show multiple angles")
                PhotoTip(icon: "sparkles", text: "Clean background preferred")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
        .onChange(of: selectedPhotos) { oldValue, newItems in
            loadImages(from: newItems)
        }
    }
    
    // MARK: - Pricing View
    private var pricingView: some View {
        VStack(spacing: 24) {
            // Price input
            VStack(spacing: 16) {
                Text("Set Your Price")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                HStack {
                    Text("$")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    
                    TextField("0", text: $price)
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 200)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                    
                    if isRental {
                        Text("/day")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            // Promotion options
            VStack(spacing: 12) {
                Text("Boost Your Listing")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(PromotionType.allCases, id: \.self) { type in
                    PromotionCard(
                        type: type,
                        isSelected: selectedPromotion == type,
                        price: Double(price) ?? 0
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedPromotion = type
                            HapticManager.impact(style: .light)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Review View
    private var reviewView: some View {
        VStack(spacing: 24) {
            Text("Review Your Listing")
                .font(.title.bold())
                .foregroundColor(.white)
            
            // Preview card
            ListingPreviewCard(
                title: title,
                price: price,
                isRental: isRental,
                category: category,
                condition: condition,
                images: loadedImages,
                promotion: selectedPromotion
            )
            
            // Summary
            VStack(alignment: .leading, spacing: 12) {
                SummaryRow(label: "Type", value: isRental ? "Rental" : "Sale")
                SummaryRow(label: "Category", value: category)
                SummaryRow(label: "Condition", value: condition)
                SummaryRow(label: "Photos", value: "\(loadedImages.count)")
                if let promotion = selectedPromotion, promotion != .none {
                    SummaryRow(label: "Promotion", value: promotion.title, color: promotion.color)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button(action: previousStep) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
            
            Button(action: currentStep < 4 ? nextStep : submitListing) {
                HStack {
                    Text(currentStep < 4 ? "Next" : "Create Listing")
                    Image(systemName: currentStep < 4 ? "chevron.right" : "checkmark.circle.fill")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    currentStep < 4 ? Color.purple : Color.green,
                                    currentStep < 4 ? Color.pink : Color.green.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: currentStep < 4 ? .purple.opacity(0.3) : .green.opacity(0.3), radius: 10)
                )
            }
            .disabled(!isStepValid)
            .opacity(isStepValid ? 1 : 0.6)
        }
    }
    
    // MARK: - Success Overlay
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Animated checkmark
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 100, height: 100)
                        .scaleEffect(rippleEffect ? 1.2 : 1.0)
                        .opacity(rippleEffect ? 0 : 1)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(showSuccessAnimation ? 1 : 0)
                        .rotationEffect(.degrees(showSuccessAnimation ? 0 : -180))
                }
                
                Text("Listing Created!")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                Text("Your item is now live")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                
                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.green)
                        )
                }
            }
            .scaleEffect(showSuccessAnimation ? 1 : 0.8)
            .opacity(showSuccessAnimation ? 1 : 0)
        }
    }
    
    // MARK: - Floating Particles
    private var floatingParticles: some View {
        ZStack {
            ForEach(0..<15) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 20
                        )
                    )
                    .frame(width: CGFloat.random(in: 10...30))
                    .position(
                        x: particleAnimation ? CGFloat.random(in: 0...UIScreen.main.bounds.width) : UIScreen.main.bounds.width / 2,
                        y: particleAnimation ? CGFloat.random(in: 0...UIScreen.main.bounds.height) : UIScreen.main.bounds.height
                    )
                    .animation(
                        .linear(duration: Double.random(in: 20...40))
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.5),
                        value: particleAnimation
                    )
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Helper Functions
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            animateIn = true
        }
        
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            gradientRotation = 360
        }
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowAnimation = true
            floatingAnimation = true
        }
        
        particleAnimation = true
    }
    
    private func loadImages(from items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        loadedImages.append(image)
                    }
                }
            }
            selectedPhotos.removeAll()
        }
    }
    
    private func removeImage(at index: Int) {
        withAnimation(.spring(response: 0.3)) {
            loadedImages.remove(at: index)
        }
    }
    
    private func nextStep() {
        withAnimation(.spring(response: 0.5)) {
            currentStep += 1
        }
        HapticManager.impact(style: .light)
    }
    
    private func previousStep() {
        withAnimation(.spring(response: 0.5)) {
            currentStep -= 1
        }
        HapticManager.impact(style: .light)
    }
    
    private func submitListing() {
        isLoading = true
        HapticManager.impact(style: .medium)
        
        Task {
            do {
                // Upload images first
                var uploadedImageUrls: [String] = []
                for image in loadedImages {
                    if let imageData = image.jpegData(compressionQuality: 0.8) {
                        let response = try await APIClient.shared.uploadImage(imageData: imageData)
                        uploadedImageUrls.append(response.data?.url ?? "")
                    }
                }
                
                // Create listing request
                if selectedPromotion != nil && selectedPromotion != .none {
                    // Create listing with promotion
                    let userLocation = Location(
                        address: "123 Main St",
                        city: "San Francisco",
                        state: "CA",
                        zipCode: "94102",
                        country: "USA",
                        latitude: 37.7749,
                        longitude: -122.4194
                    )
                    let listing = CreateListingRequest(
                        title: title,
                        description: description,
                        price: Double(price) ?? 0,
                        category: category,
                        location: "\(userLocation.city), \(userLocation.state)",
                        type: isRental ? "for_rent" : "for_sale",
                        images: uploadedImageUrls,
                        inventoryAmt: 1,
                        isFree: false,
                        pricePerDay: isRental ? Double(price) : nil,
                        buyoutValue: nil,
                        latitude: userLocation.latitude,
                        longitude: userLocation.longitude
                    )
                    let promotion = PromotionRequest(
                        type: selectedPromotion == .featured ? "auto_promote" : "pay_on_sale",
                        duration: 7
                    )
                    let request = CreateListingWithPromotionRequest(
                        listing: listing,
                        promotion: promotion
                    )
                    
                    let response = try await APIClient.shared.createListingWithPromotion(request)
                    
                    // Handle payment if needed
                    if let promotion = response.promotion, 
                       promotion.paymentRequired == true,
                       let paymentIntentId = promotion.paymentIntentId {
                        // Handle Stripe payment flow
                        // For now, we'll assume success
                    }
                } else {
                    // Create regular listing
                    let request = CreateListingRequest(
                        title: title,
                        description: description,
                        price: Double(price) ?? 0,
                        category: category,
                        location: "123 Main St, San Francisco, CA",
                        type: isRental ? "for_rent" : "for_sale",
                        images: uploadedImageUrls,
                        inventoryAmt: 1,
                        isFree: false,
                        pricePerDay: isRental ? Double(price) : nil,
                        buyoutValue: nil,
                        latitude: nil,  // TODO: Get actual coordinates
                        longitude: nil  // TODO: Get actual coordinates
                    )
                    
                    _ = try await APIClient.shared.createListing(request)
                }
                
                await MainActor.run {
                    withAnimation(.spring(response: 0.6)) {
                        showSuccessAnimation = true
                        rippleEffect = true
                    }
                    
                    HapticManager.notification(type: .success)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        rippleEffect = false
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    HapticManager.notification(type: .error)
                    // Handle error - show alert
                    print("Error creating listing: \(error)")
                }
            }
        }
    }
    
    private var isStepValid: Bool {
        switch currentStep {
        case 0:
            return true // Type selection always valid
        case 1:
            return !title.isEmpty && !category.isEmpty && !description.isEmpty
        case 2:
            return !loadedImages.isEmpty
        case 3:
            return !price.isEmpty && Double(price) != nil
        case 4:
            return true // Review always valid
        default:
            return false
        }
    }
}

// MARK: - Supporting Views

struct TypeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? color : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
    }
}

struct FuturisticTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    let gradient: [Color]
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !text.isEmpty || isFocused {
                Label(placeholder, systemImage: icon)
                    .font(.caption.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
            
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .focused($isFocused)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: isFocused ? gradient : [Color.white.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
            )
        }
        .animation(.spring(response: 0.3), value: isFocused)
    }
}

struct FuturisticCategoryChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
        }
    }
}

struct FuturisticConditionChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
}

struct PhotoThumbnail: View {
    let image: UIImage
    let index: Int
    let onDelete: () -> Void
    @State private var showDelete = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            
            if index == 0 {
                Text("Main")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.purple)
                    )
                    .padding(8)
            }
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            .padding(8)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct AddPhotoButton: View {
    @State private var isHovered = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.title)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Add Photo")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
            )
            .aspectRatio(1, contentMode: .fit)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .onHover { hovering in
                withAnimation(.spring(response: 0.3)) {
                    isHovered = hovering
                }
            }
    }
}

struct PhotoTip: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.purple)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
}

struct PromotionCard: View {
    let type: FuturisticCreateListingView.PromotionType
    let isSelected: Bool
    let price: Double
    let action: () -> Void
    
    var calculatedFee: String {
        switch type {
        case .none:
            return "Free"
        case .featured:
            return "$\(String(format: "%.2f", price * 0.1))"
        case .spotlight:
            return "$\(String(format: "%.2f", price * 0.03)) on sale"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(type.color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text(calculatedFee)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? type.color : .white.opacity(0.5))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? type.color : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
    }
}

struct ListingPreviewCard: View {
    let title: String
    let price: String
    let isRental: Bool
    let category: String
    let condition: String
    let images: [UIImage]
    let promotion: FuturisticCreateListingView.PromotionType?
    
    var body: some View {
        VStack(spacing: 0) {
            // Image carousel placeholder
            ZStack {
                if let firstImage = images.first {
                    Image(uiImage: firstImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 300)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 300)
                }
                
                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.5)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                
                // Promotion badge
                if let promotion = promotion, promotion != .none {
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: promotion.icon)
                                Text(promotion == .featured ? "Featured" : "Spotlight")
                            }
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(promotion.color)
                            )
                            .padding(16)
                        }
                        Spacer()
                    }
                }
                
                // Price overlay
                VStack {
                    Spacer()
                    HStack {
                        Text("$\(price)")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        
                        if isRental {
                            Text("/day")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                    }
                    .padding(20)
                }
            }
            
            // Details
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                HStack(spacing: 16) {
                    Label(category, systemImage: "tag.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Label(condition, systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                }
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    var color: Color = .white
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(color)
        }
    }
}

// Mesh gradient placeholder
struct MeshGradient: View {
    let colors: [Color]
    let rotation: Double
    
    var body: some View {
        ZStack {
            ForEach(0..<colors.count, id: \.self) { index in
                let angle = Double(index) * .pi / 2 + rotation * .pi / 180
                let x = 0.5 + 0.3 * cos(angle)
                let y = 0.5 + 0.3 * sin(angle)
                
                RadialGradient(
                    colors: [colors[index], colors[index].opacity(0.3), .clear],
                    center: UnitPoint(x: x, y: y),
                    startRadius: 0,
                    endRadius: UIScreen.main.bounds.width
                )
                .blendMode(.screen)
            }
        }
        .background(Color.black)
    }
}

// Preview
struct FuturisticCreateListingView_Previews: PreviewProvider {
    static var previews: some View {
        FuturisticCreateListingView()
    }
}