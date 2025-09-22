import SwiftUI

struct ModernPostCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    @State private var selectedOption: PostOption? = nil
    @State private var showCreateListing = false
    @State private var showCreateSeek = false
    @State private var showCreateGarageSale = false
    @State private var animateCards = false
    @State private var floatingAnimation = false
    @State private var showLoginAlert = false
    
    // Callback for when a listing is created successfully
    var onListingCreated: ((String) -> Void)? = nil
    
    enum PostOption {
        case listing
        case seek
        case garageSale
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated gradient background
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Theme.Colors.primary.opacity(0.05),
                        Color(.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: floatingAnimation)
                
                VStack(spacing: 40) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Theme.Colors.primary)
                            .rotationEffect(.degrees(floatingAnimation ? 5 : -5))
                            .scaleEffect(floatingAnimation ? 1.1 : 1.0)
                        
                        Text(LocalizationHelper.localizedString("what_would_you_like_to_do"))
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                        
                        Text(LocalizationHelper.localizedString("choose_option_to_get_started"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                    
                    // Option cards
                    VStack(spacing: 20) {
                        // List Something card
                        OptionCard(
                            icon: "bag.fill",
                            title: LocalizationHelper.localizedString("list_something"),
                            subtitle: LocalizationHelper.localizedString("share_items_services_community"),
                            gradientColors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.7)],
                            isSelected: selectedOption == .listing
                        ) {
                            if authManager.isAuthenticated {
                                withAnimation(.spring()) {
                                    selectedOption = .listing
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showCreateListing = true
                                }
                            } else {
                                showLoginAlert = true
                            }
                        }
                        .scaleEffect(animateCards ? 1.0 : 0.8)
                        .opacity(animateCards ? 1.0 : 0.0)
                        .animation(.spring().delay(0.1), value: animateCards)
                        
                        // Find Something card
                        OptionCard(
                            icon: "magnifyingglass",
                            title: LocalizationHelper.localizedString("find_something"),
                            subtitle: LocalizationHelper.localizedString("post_what_looking_for"),
                            gradientColors: [Color(hex: "007AFF"), Color(hex: "007AFF").opacity(0.7)],
                            isSelected: selectedOption == .seek
                        ) {
                            withAnimation(.spring()) {
                                selectedOption = .seek
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showCreateSeek = true
                            }
                        }
                        .scaleEffect(animateCards ? 1.0 : 0.8)
                        .opacity(animateCards ? 1.0 : 0.0)
                        .animation(.spring().delay(0.2), value: animateCards)
                        
                        // Garage Sale card
                        OptionCard(
                            icon: "house.fill",
                            title: LocalizationHelper.localizedString("host_garage_sale"),
                            subtitle: LocalizationHelper.localizedString("organize_sale_event"),
                            gradientColors: [Color(hex: "FF9500"), Color(hex: "FF9500").opacity(0.7)],
                            isSelected: selectedOption == .garageSale
                        ) {
                            withAnimation(.spring()) {
                                selectedOption = .garageSale
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showCreateGarageSale = true
                            }
                        }
                        .scaleEffect(animateCards ? 1.0 : 0.8)
                        .opacity(animateCards ? 1.0 : 0.0)
                        .animation(.spring().delay(0.3), value: animateCards)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .overlay(
                // Close button
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.secondary)
                        .padding(12)
                        .background(Circle().fill(Color(.systemGray5)))
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            )
            .onAppear {
                withAnimation {
                    animateCards = true
                    floatingAnimation = true
                }
            }
        }
        .fullScreenCover(isPresented: $showCreateListing) {
            ModernCreateListingView(onViewListing: { listingId in
                print("📋 ModernPostCreationView: Received onViewListing callback with ID: \(listingId)")
                // Dismiss the post creation modal and call the parent callback
                dismiss()
                print("📋 ModernPostCreationView: Calling parent onListingCreated with ID: \(listingId)")
                onListingCreated?(listingId)
            })
        }
        .fullScreenCover(isPresented: $showCreateSeek) {
            ModernCreateSeekView()
        }
        .fullScreenCover(isPresented: $showCreateGarageSale) {
            ModernCreateGarageSaleView()
        }
        .alert(LocalizationHelper.localizedString("login_required"), isPresented: $showLoginAlert) {
            Button(LocalizationHelper.localizedString("cancel"), role: .cancel) { }
            Button(LocalizationHelper.localizedString("login")) {
                dismiss()
                // The user will need to login from the main screen
            }
        } message: {
            Text(LocalizationHelper.localizedString("login_required_message"))
        }
    }
}

struct OptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradientColors: [Color]
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background gradient
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: gradientColors.map { $0.opacity(isSelected ? 0.8 : 0.1) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: gradientColors.first?.opacity(0.3) ?? .clear,
                        radius: isSelected ? 20 : 10,
                        y: isSelected ? 10 : 5
                    )
                
                // Content
                HStack(spacing: 20) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(.white.opacity(isSelected ? 1.0 : 0.2))
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: icon)
                            .font(.system(size: 30))
                            .foregroundColor(isSelected ? gradientColors.first : .white)
                    }
                    
                    // Text
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.title3.bold())
                            .foregroundColor(isSelected ? .white : .primary)
                        
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Arrow
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : gradientColors.first)
                        .rotationEffect(.degrees(isSelected ? 0 : -90))
                }
                .padding(24)
            }
            .frame(height: 120)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// Alternative design with interactive elements
struct ModernPostCreationAlternativeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var dragOffset = CGSize.zero
    @State private var showListingFlow = false
    @State private var showSeekFlow = false
    @State private var selectedCard: Int? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                // Particle background
                ParticleBackgroundView()
                
                VStack {
                    // Custom header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(LocalizationHelper.localizedString("create"))
                            .font(.headline)
                        
                        Spacer()
                        
                        // Balance
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .opacity(0)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Interactive cards stack
                    ZStack {
                        ForEach(0..<2) { index in
                            InteractiveCard(
                                index: index,
                                isTop: selectedCard == nil || selectedCard == index,
                                content: index == 0 ? .listing : .seek
                            ) {
                                withAnimation(.spring()) {
                                    selectedCard = index
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    if index == 0 {
                                        showListingFlow = true
                                    } else {
                                        showSeekFlow = true
                                    }
                                }
                            }
                            .offset(y: CGFloat(index) * 10)
                            .scaleEffect(selectedCard == nil ? 1.0 - (CGFloat(index) * 0.05) : (selectedCard == index ? 1.0 : 0.9))
                            .opacity(selectedCard == nil ? 1.0 : (selectedCard == index ? 1.0 : 0.0))
                            .zIndex(selectedCard == index ? 2 : Double(1 - index))
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Instructions
                    VStack(spacing: 8) {
                        Text(LocalizationHelper.localizedString("tap_to_select"))
                            .font(.subheadline.weight(.medium))
                        
                        Text(LocalizationHelper.localizedString("choose_how_to_contribute"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showListingFlow) {
            ModernCreateListingView()
        }
        .fullScreenCover(isPresented: $showSeekFlow) {
            ModernCreateSeekView()
        }
    }
}

struct InteractiveCard: View {
    let index: Int
    let isTop: Bool
    let content: CardContent
    let onTap: () -> Void
    
    @State private var rotation: Double = 0
    @State private var offset = CGSize.zero
    
    enum CardContent {
        case listing
        case seek
        
        var icon: String {
            switch self {
            case .listing: return "bag.fill"
            case .seek: return "magnifyingglass"
            }
        }
        
        var title: String {
            switch self {
            case .listing: return LocalizationHelper.localizedString("list_something")
            case .seek: return LocalizationHelper.localizedString("find_something")
            }
        }
        
        var description: String {
            switch self {
            case .listing: return LocalizationHelper.localizedString("share_items_description")
            case .seek: return LocalizationHelper.localizedString("post_needs_description")
            }
        }
        
        var gradient: [Color] {
            switch self {
            case .listing: return [.blue, .cyan]
            case .seek: return [.purple, .pink]
            }
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(
                    LinearGradient(
                        colors: content.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: content.gradient.first?.opacity(0.4) ?? .clear, radius: 20, y: 10)
            
            VStack(spacing: 30) {
                // Icon with animation
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: content.icon)
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(rotation))
                }
                
                VStack(spacing: 12) {
                    Text(content.title)
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    
                    Text(content.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Action hint
                HStack {
                    Text(LocalizationHelper.localizedString("tap_to_continue"))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Capsule().fill(.white.opacity(0.2)))
            }
            .padding(40)
        }
        .frame(height: 400)
        .rotation3DEffect(
            .degrees(Double(offset.width) / 10),
            axis: (x: 0, y: 1, z: 0)
        )
        .offset(offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if isTop {
                        offset = value.translation
                        rotation = Double(value.translation.width) / 10
                    }
                }
                .onEnded { value in
                    withAnimation(.spring()) {
                        offset = .zero
                        rotation = 0
                    }
                }
        )
        .onTapGesture {
            if isTop {
                onTap()
            }
        }
    }
}

struct ParticleBackgroundView: View {
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGVector
        var size: CGFloat
        var opacity: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(Theme.Colors.primary.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                }
            }
            .onAppear {
                // Ensure we have valid dimensions
                guard geometry.size.width > 0 && geometry.size.height > 0 else { return }
                
                for _ in 0..<20 {
                    particles.append(
                        Particle(
                            position: CGPoint(
                                x: CGFloat.random(in: 0...max(1, geometry.size.width)),
                                y: CGFloat.random(in: 0...max(1, geometry.size.height))
                            ),
                            velocity: CGVector(
                                dx: CGFloat.random(in: -1...1),
                                dy: CGFloat.random(in: -1...1)
                            ),
                            size: CGFloat.random(in: 2...6),
                            opacity: Double.random(in: 0.1...0.3)
                        )
                    )
                }
                
                let width = max(1, geometry.size.width)
                let height = max(1, geometry.size.height)
                Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                    guard width > 0 && height > 0 else { return }
                    
                    for i in particles.indices {
                        particles[i].position.x += particles[i].velocity.dx
                        particles[i].position.y += particles[i].velocity.dy
                        
                        // Bounce off edges
                        if particles[i].position.x < 0 || particles[i].position.x > width {
                            particles[i].velocity.dx *= -1
                            particles[i].position.x = max(0, min(width, particles[i].position.x))
                        }
                        if particles[i].position.y < 0 || particles[i].position.y > height {
                            particles[i].velocity.dy *= -1
                            particles[i].position.y = max(0, min(height, particles[i].position.y))
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Preview

struct ModernPostCreationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ModernPostCreationView()
            ModernPostCreationAlternativeView()
        }
    }
}