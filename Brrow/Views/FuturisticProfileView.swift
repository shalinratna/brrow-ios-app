import SwiftUI
import Charts

struct FuturisticProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedSegment = 0
    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var animateIn = false
    @State private var liquidAnimation = false
    @State private var glowAnimation = false
    @State private var particleAnimation = false
    
    let segments = ["Overview", "Activity", "Insights", "Achievements"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated gradient background
                animatedBackground
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Futuristic header with parallax
                        futuristicHeader
                            .offset(y: animateIn ? 0 : -50)
                            .opacity(animateIn ? 1 : 0)
                        
                        // Glowing profile card
                        glowingProfileCard
                            .padding(.horizontal)
                            .offset(y: -60)
                        
                        // Liquid segment control
                        liquidSegmentControl
                            .padding(.horizontal)
                            .offset(y: -40)
                        
                        // Dynamic content with animations
                        dynamicContent
                            .padding(.horizontal)
                            .padding(.top, -20)
                        
                        Spacer(minLength: 100)
                    }
                }
                .ignoresSafeArea(edges: .top)
                
                // Floating action button
                floatingActionButton
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animateIn = true
                }
                startLiquidAnimation()
                startGlowAnimation()
                startParticleAnimation()
            }
            .sheet(isPresented: $showEditProfile) {
                if let user = authManager.currentUser {
                    EditProfileView(user: user)
                }
            }
            .sheet(isPresented: $showSettings) {
                NativeSettingsView()
            }
        }
    }
    
    // MARK: - Animated Background
    private var animatedBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(hex: "1a1a2e"),
                    Color(hex: "16213e"),
                    Color(hex: "0f3460")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated mesh gradient overlay
            GeometryReader { geometry in
                ForEach(0..<3) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.Colors.primary.opacity(0.3),
                                    Theme.Colors.primary.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 300, height: 300)
                        .offset(
                            x: liquidAnimation ? CGFloat.random(in: -100...100) : 0,
                            y: liquidAnimation ? CGFloat.random(in: -100...100) : 0
                        )
                        .blur(radius: 60)
                        .animation(
                            .easeInOut(duration: Double.random(in: 8...12))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.5),
                            value: liquidAnimation
                        )
                }
            }
            
            // Particle effect
            ParticleEffectView(isAnimating: particleAnimation)
        }
    }
    
    // MARK: - Futuristic Header
    private var futuristicHeader: some View {
        ZStack {
            // Blurred background image
            if let user = authManager.currentUser, let imageUrl = user.profilePicture {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.primary.opacity(0.3))
                }
                .frame(height: 400)
                .blur(radius: 30)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            
            // Header content
            VStack(spacing: 20) {
                HStack {
                    Button(action: { showSettings = true }) {
                        GlassButton(icon: "gearshape.fill")
                    }
                    
                    Spacer()
                    
                    Text("Profile")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                    
                    Spacer()
                    
                    Button(action: { showEditProfile = true }) {
                        GlassButton(icon: "square.and.pencil")
                    }
                }
                .padding(.horizontal)
                .padding(.top, 60)
                
                Spacer()
            }
            .frame(height: 350)
        }
    }
    
    // MARK: - Glowing Profile Card
    private var glowingProfileCard: some View {
        VStack(spacing: 20) {
            // Profile picture with glow
            ZStack {
                // Glow effect
                Circle()
                    .fill(Theme.Colors.primary)
                    .frame(width: 140, height: 140)
                    .blur(radius: glowAnimation ? 30 : 15)
                    .opacity(glowAnimation ? 0.8 : 0.4)
                    .scaleEffect(glowAnimation ? 1.2 : 1.0)
                
                // Profile image
                if let user = authManager.currentUser, let imageUrl = user.profilePicture {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Theme.Colors.primary, Color.white],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                } else {
                    Circle()
                        .fill(Theme.Colors.primary.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                        )
                }
                
                // Verified badge with animation
                if authManager.currentUser?.verified ?? false {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 40, height: 40)
                        )
                        .offset(x: 45, y: 45)
                        .rotationEffect(.degrees(glowAnimation ? 360 : 0))
                        .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: glowAnimation)
                }
            }
            
            // User info with glassmorphism
            VStack(spacing: 12) {
                Text(authManager.currentUser?.username ?? "Guest User")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                HStack(spacing: 20) {
                    InfoPill(icon: "star.fill", text: String(format: "%.1f", viewModel.userRating))
                    InfoPill(icon: "cube.box.fill", text: "\(viewModel.userListings.count) items")
                    InfoPill(icon: "dollarsign.circle.fill", text: "$\(Int.random(in: 100...999))")
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 30)
            .background(
                GlassmorphicCard()
            )
        }
        .padding(.top, -80)
    }
    
    // MARK: - Liquid Segment Control
    private var liquidSegmentControl: some View {
        HStack(spacing: 0) {
            ForEach(segments.indices, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedSegment = index
                    }
                    HapticManager.impact(style: .light)
                }) {
                    Text(segments[index])
                        .font(.subheadline.bold())
                        .foregroundColor(selectedSegment == index ? .white : .white.opacity(0.6))
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                if selectedSegment == index {
                                    LiquidShape()
                                        .fill(Theme.Colors.primary)
                                        .matchedGeometryEffect(id: "liquid", in: namespace)
                                }
                            }
                        )
                }
            }
        }
        .background(
            GlassmorphicCard()
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @Namespace private var namespace
    
    // MARK: - Dynamic Content
    @ViewBuilder
    private var dynamicContent: some View {
        switch selectedSegment {
        case 0:
            overviewContent
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                       removal: .move(edge: .leading).combined(with: .opacity)))
        case 1:
            activityContent
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                       removal: .move(edge: .leading).combined(with: .opacity)))
        case 2:
            insightsContent
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                       removal: .move(edge: .leading).combined(with: .opacity)))
        case 3:
            achievementsContent
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                       removal: .move(edge: .leading).combined(with: .opacity)))
        default:
            EmptyView()
        }
    }
    
    // MARK: - Overview Content
    private var overviewContent: some View {
        VStack(spacing: 20) {
            // Stats grid with animations
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard3D(
                    icon: "cube.box.fill",
                    value: "\(viewModel.userListings.count)",
                    label: "Active Listings",
                    color: .blue
                )
                
                StatCard3D(
                    icon: "arrow.triangle.2.circlepath",
                    value: "42",
                    label: "Transactions",
                    color: .green
                )
                
                StatCard3D(
                    icon: "star.fill",
                    value: String(format: "%.1f", viewModel.userRating),
                    label: "Rating",
                    color: .orange
                )
                
                StatCard3D(
                    icon: "dollarsign.circle.fill",
                    value: "$1,234",
                    label: "Earnings",
                    color: .purple
                )
            }
            
            // Recent listings with hover effect
            VStack(alignment: .leading, spacing: 16) {
                Text("Recent Listings")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(viewModel.userListings.prefix(3)) { listing in
                    HoverListingCard(listing: listing)
                }
            }
            .padding(.top, 20)
        }
    }
    
    // MARK: - Activity Content
    private var activityContent: some View {
        VStack(spacing: 20) {
            // Activity timeline
            ForEach(0..<5) { index in
                TimelineCard(
                    icon: ["cube.box", "star", "arrow.triangle.2.circlepath", "message", "heart"].randomElement()!,
                    title: ["Listed new item", "Received review", "Completed rental", "New message", "Item favorited"].randomElement()!,
                    time: "\(index + 1)h ago",
                    color: [Color.blue, Color.orange, Color.green, Color.purple, Color.pink].randomElement()!
                )
                .opacity(animateIn ? 1 : 0)
                .offset(x: animateIn ? 0 : -50)
                .animation(.spring(response: 0.5).delay(Double(index) * 0.1), value: animateIn)
            }
        }
    }
    
    // MARK: - Insights Content
    private var insightsContent: some View {
        VStack(spacing: 20) {
            // Animated chart
            AnimatedChart()
                .frame(height: 200)
                .padding()
                .background(GlassmorphicCard())
            
            // Insights cards
            InsightCard(
                title: "Peak Activity",
                value: "3-5 PM",
                trend: "+12%",
                icon: "chart.line.uptrend.xyaxis"
            )
            
            InsightCard(
                title: "Most Popular Category",
                value: "Electronics",
                trend: "68% of listings",
                icon: "tv"
            )
        }
    }
    
    // MARK: - Achievements Content
    private var achievementsContent: some View {
        VStack(spacing: 20) {
            // Achievement badges
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(0..<6) { index in
                    AchievementBadge(
                        icon: ["star", "crown", "flame", "bolt", "trophy", "medal"].randomElement()!,
                        title: ["Super Lender", "Elite Member", "Hot Streak", "Quick Responder", "Top Rated", "Veteran"][index],
                        unlocked: index < 4
                    )
                }
            }
            
            // Progress card
            VStack(alignment: .leading, spacing: 12) {
                Text("Next Achievement")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(Theme.Colors.primary)
                    
                    VStack(alignment: .leading) {
                        Text("Power Seller")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        
                        Text("Complete 50 transactions")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Text("42/50")
                        .font(.caption.bold())
                        .foregroundColor(Theme.Colors.primary)
                }
                .padding()
                .background(GlassmorphicCard())
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * 0.84, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(.top, 20)
        }
    }
    
    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button(action: {
                    // Action
                    HapticManager.impact(style: .medium)
                }) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.primary)
                            .frame(width: 60, height: 60)
                            .shadow(color: Theme.Colors.primary.opacity(0.5), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(glowAnimation ? 90 : 0))
                    }
                }
                .scaleEffect(glowAnimation ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowAnimation)
                .padding()
            }
        }
    }
    
    // MARK: - Animation Functions
    private func startLiquidAnimation() {
        liquidAnimation = true
    }
    
    private func startGlowAnimation() {
        glowAnimation = true
    }
    
    private func startParticleAnimation() {
        particleAnimation = true
    }
}

// MARK: - Supporting Views

struct GlassButton: View {
    let icon: String
    
    var body: some View {
        Image(systemName: icon)
            .font(.title3)
            .foregroundColor(.white)
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .background(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .blur(radius: 0.5)
            )
    }
}

struct InfoPill: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption.bold())
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.2))
                .background(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct GlassmorphicCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.1))
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .blur(radius: 0.5)
    }
}

struct LiquidShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: 0, y: rect.height * 0.5))
        
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.5),
            control1: CGPoint(x: rect.width * 0.3, y: 0),
            control2: CGPoint(x: rect.width * 0.7, y: rect.height)
        )
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

struct StatCard3D: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .blur(radius: isHovered ? 20 : 10)
                
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                    .scaleEffect(isHovered ? 1.2 : 1.0)
            }
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(GlassmorphicCard())
        .rotation3DEffect(
            .degrees(isHovered ? 5 : 0),
            axis: (x: 1, y: 0, z: 0)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.4)) {
                isHovered.toggle()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.4)) {
                    isHovered.toggle()
                }
            }
        }
    }
}

struct HoverListingCard: View {
    let listing: Listing
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            if let imageUrl = listing.images.first {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("$\(Int(listing.price))\(listing.type == "rental" ? "/day" : "")")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "eye")
                        .font(.caption2)
                    Text("\(listing.views)")
                        .font(.caption)
                }
                .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
                .offset(x: isHovered ? 5 : 0)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isHovered ? 0.15 : 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                isHovered.toggle()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3)) {
                    isHovered.toggle()
                }
            }
        }
    }
}

struct TimelineCard: View {
    let icon: String
    let title: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Timeline dot and line
            VStack(spacing: 0) {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .fill(color)
                            .frame(width: 20, height: 20)
                            .opacity(0.3)
                            .blur(radius: 4)
                    )
                
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 2)
            }
            .frame(width: 20)
            
            // Content
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(color.opacity(0.2))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text(time)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
            .padding()
            .background(GlassmorphicCard())
        }
        .padding(.leading, 10)
    }
}

struct AnimatedChart: View {
    @State private var animateChart = false
    
    let data = [
        (day: "Mon", value: 45),
        (day: "Tue", value: 65),
        (day: "Wed", value: 55),
        (day: "Thu", value: 78),
        (day: "Fri", value: 92),
        (day: "Sat", value: 88),
        (day: "Sun", value: 73)
    ]
    
    var body: some View {
        Chart(data, id: \.day) { item in
            BarMark(
                x: .value("Day", item.day),
                y: .value("Value", animateChart ? item.value : 0)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(8)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.white.opacity(0.2))
                AxisValueLabel()
                    .foregroundStyle(Color.white.opacity(0.6))
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .foregroundStyle(Color.white.opacity(0.6))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8).delay(0.2)) {
                animateChart = true
            }
        }
    }
}

struct InsightCard: View {
    let title: String
    let value: String
    let trend: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Theme.Colors.primary.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                Text(trend)
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
        .padding()
        .background(GlassmorphicCard())
    }
}

struct AchievementBadge: View {
    let icon: String
    let title: String
    let unlocked: Bool
    @State private var rotate = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Hexagon()
                    .fill(unlocked ? Theme.Colors.primary : Color.white.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(rotate ? 360 : 0))
                    .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: rotate)
                
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(unlocked ? .white : .white.opacity(0.3))
            }
            
            Text(title)
                .font(.caption2.bold())
                .foregroundColor(unlocked ? .white : .white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .onAppear {
            if unlocked {
                rotate = true
            }
        }
    }
}

struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let corners = 6
        let angle = .pi * 2 / Double(corners)
        
        for i in 0..<corners {
            let x = center.x + radius * cos(angle * Double(i) - .pi / 2)
            let y = center.y + radius * sin(angle * Double(i) - .pi / 2)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

struct ParticleEffectView: View {
    let isAnimating: Bool
    @State private var particles: [Particle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(particles) { particle in
                Circle()
                    .fill(Theme.Colors.primary.opacity(particle.opacity))
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .blur(radius: 2)
            }
        }
        .onAppear {
            if isAnimating {
                createParticles()
            }
        }
    }
    
    private func createParticles() {
        for _ in 0..<20 {
            let particle = Particle()
            particles.append(particle)
            
            animateParticle(particle)
        }
    }
    
    private func animateParticle(_ particle: Particle) {
        withAnimation(.linear(duration: Double.random(in: 5...10)).repeatForever(autoreverses: false)) {
            if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                particles[index].position.y = -100
                particles[index].opacity = 0
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    
    init() {
        position = CGPoint(
            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
            y: CGFloat.random(in: UIScreen.main.bounds.height...UIScreen.main.bounds.height + 200)
        )
        size = CGFloat.random(in: 2...6)
        opacity = Double.random(in: 0.3...0.7)
    }
}

// Color extension already exists in Theme.swift

// Preview
struct FuturisticProfileView_Previews: PreviewProvider {
    static var previews: some View {
        FuturisticProfileView()
            .environmentObject(AuthManager.shared)
    }
}