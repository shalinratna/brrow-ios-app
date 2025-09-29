//
//  GarageSaleComponents.swift
//  Brrow
//
//  Reusable garage sale UI components
//

import SwiftUI
import MapKit

// Type alias for compatibility
typealias GarageSaleItem = GarageSale

// Simple ShareSheet for garage sales
struct GarageSaleShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Extensions to provide missing properties
extension GarageSale {
    // isBoosted is now a stored property in the model
    
    var dateString: String {
        // Use formatted_date from API if available
        if let formattedDate = self.formattedDate {
            return formattedDate
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = formatter.date(from: startDate) {
            formatter.dateFormat = "MMM d, h:mm a"
            formatter.timeZone = TimeZone.current
            return formatter.string(from: date)
        }
        return startDate
    }
    
    var fullDateString: String {
        // Use formatted_date_range from API if available
        if let formattedRange = self.formattedDateRange {
            return formattedRange
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let start = formatter.date(from: startDate),
           let end = formatter.date(from: endDate) {
            formatter.dateFormat = "MMM d, h:mm a"
            formatter.timeZone = TimeZone.current
            let startStr = formatter.string(from: start)
            formatter.dateFormat = "h:mm a"
            let endStr = formatter.string(from: end)
            return "\(startStr) - \(endStr)"
        }
        return "\(startDate) - \(endDate)"
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitude ?? 0,
            longitude: longitude ?? 0
        )
    }
    
    var associatedListingCount: Int {
        // Use value from API if available
        return self.listingCount ?? 0
    }
}

// MARK: - Map Pin View
struct GarageSaleMapPin: View {
    let sale: GarageSaleItem
    @State private var showDetails = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Pin
            ZStack {
                Image(systemName: "house.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(sale.isBoosted ? Theme.Colors.accentOrange : Theme.Colors.primary)
                    .clipShape(Circle())
                
                if sale.isBoosted {
                    Circle()
                        .stroke(Theme.Colors.accentOrange, lineWidth: 2)
                        .frame(width: 44, height: 44)
                        .scaleEffect(showDetails ? 1.3 : 1.0)
                        .opacity(showDetails ? 0 : 1)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: showDetails)
                }
            }
            
            // Triangle pointer
            Triangle()
                .fill(sale.isBoosted ? Theme.Colors.accentOrange : Theme.Colors.primary)
                .frame(width: 12, height: 6)
                .offset(y: -2)
        }
        .onTapGesture {
            showDetails = true
        }
        .scaleEffect(sale.isBoosted ? 1.2 : 1.0)
        .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)
    }
}

// Triangle shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview Card
struct GarageSalePreviewCard: View {
    let sale: GarageSaleItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            if let firstImage = sale.images.first {
                BrrowAsyncImage(url: firstImage) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Theme.Colors.secondary.opacity(0.2))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(Theme.Colors.secondary)
                        )
                }
                .frame(width: 140, height: 100)
                .clipped()
                .cornerRadius(12)
                .overlay(
                    // Boosted badge
                    sale.isBoosted ? 
                    HStack {
                        Image(systemName: "rocket.fill")
                        Text("Boosted")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.accentOrange)
                    .cornerRadius(12)
                    .padding(6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    : nil
                )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(sale.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                    Text(sale.dateString)
                        .font(.system(size: 12))
                }
                .foregroundColor(Theme.Colors.secondaryText)
                
                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .font(.system(size: 10))
                    Text(String(format: "%.1f mi", sale.distance ?? 0))
                        .font(.system(size: 12))
                }
                .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .frame(width: 140)
    }
}

// MARK: - Full Map View
struct GarageSaleFullMapView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = GarageSaleMapViewModel()
    @State private var selectedSale: GarageSaleItem?
    @State private var showDetails = false
    
    var body: some View {
        ZStack {
            // Map
            Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.filteredGarageSales) { sale in
                MapPin(coordinate: sale.coordinate, tint: .red)
            }
            .ignoresSafeArea()
            .overlay(
                // Loading indicator
                viewModel.isLoading ?
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primary))
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
                : nil
            )
            
            // UI Overlay
            VStack {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Theme.Colors.text)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.white))
                            .shadow(color: Color.black.opacity(0.1), radius: 4)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("Garage Sales")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.Colors.text)
                        Text("\(viewModel.filteredGarageSales.count) active")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 4)
                    
                    Spacer()
                    
                    // Filter button
                    Button(action: { viewModel.toggleFilter() }) {
                        Image(systemName: viewModel.showBoostedOnly ? "star.fill" : "star")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(viewModel.showBoostedOnly ? Theme.Colors.accentOrange : Theme.Colors.text)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.white))
                            .shadow(color: Color.black.opacity(0.1), radius: 4)
                    }
                }
                .padding()
                
                Spacer()
                
                // Legend and business filter
                HStack(spacing: 20) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Theme.Colors.primary)
                            .frame(width: 12, height: 12)
                        Text("Regular")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.text)
                    }
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                        Text("Business")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.text)
                    }
                    
                    Spacer()
                    
                    // Business filter toggle
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.toggleBusinessFilter()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.showBusinessOnly ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(viewModel.showBusinessOnly ? Color.blue : Color.gray)
                            Text("Business Only")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(viewModel.showBusinessOnly ? Color.blue : Color.gray)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.1), radius: 4)
                .padding(.bottom)
            }
        }
        .sheet(isPresented: $showDetails) {
            if let sale = selectedSale {
                GarageSaleDetailView(sale: sale)
            }
        }
        .onAppear {
            if viewModel.allGarageSales.isEmpty && !viewModel.isLoading {
                viewModel.loadGarageSales()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
            Button("Retry") {
                viewModel.loadGarageSales()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

// MARK: - Garage Sale Detail View
struct GarageSaleDetailView: View {
    let sale: GarageSaleItem
    @Environment(\.dismiss) private var dismiss
    @State private var showingListings = false
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                // Photos
                    if !sale.images.isEmpty {
                        TabView {
                            ForEach(sale.images, id: \.self) { imageUrl in
                                BrrowAsyncImage(url: imageUrl) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Theme.Colors.secondary.opacity(0.2))
                                        .overlay(
                                            ProgressView()
                                        )
                                }
                                .frame(height: 300)
                                .clipped()
                            }
                        }
                        .tabViewStyle(PageTabViewStyle())
                        .frame(height: 300)
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        // Title and boost badge
                        HStack {
                            Text(sale.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Theme.Colors.text)
                            
                            if sale.isBoosted {
                                HStack(spacing: 4) {
                                    Image(systemName: "rocket.fill")
                                    Text("Boosted")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Theme.Colors.accentOrange)
                                .cornerRadius(15)
                            }
                        }
                        
                        // Status Badge (if ended recently)
                        if let status = sale.status, status == "ended" {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(Color.red)
                                Text("Sale Ended")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.red)
                                if let hours = sale.hoursSinceEnd {
                                    Text("(\(Int(hours)) hours ago)")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.red.opacity(0.8))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(20)
                        } else if let status = sale.status, status == "live" {
                            HStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Happening Now")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.green)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(20)
                        }
                        
                        // Date & Time
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(Theme.Colors.primary)
                            Text(sale.fullDateString)
                                .font(.system(size: 16))
                                .foregroundColor(Theme.Colors.text)
                        }
                        
                        // Location
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(Theme.Colors.primary)
                            Text(sale.address ?? sale.location)
                                .font(.system(size: 16))
                                .foregroundColor(Theme.Colors.text)
                        }
                        
                        // Categories
                        if !sale.categories.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(sale.categories.prefix(5)), id: \.self) { category in
                                        Text(category)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Theme.Colors.primary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Theme.Colors.primary.opacity(0.1))
                                            .cornerRadius(15)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.horizontal, -Theme.Spacing.md)
                            .padding(.horizontal, Theme.Spacing.md)
                        }
                        
                        // Description
                        Text(sale.description ?? "")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.Colors.text)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Associated listings button
                        if sale.associatedListingCount > 0 {
                            Button(action: { showingListings = true }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Items at this sale")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Theme.Colors.text)
                                        
                                        Text("\(sale.associatedListingCount) items available")
                                            .font(.system(size: 14))
                                            .foregroundColor(Theme.Colors.secondaryText)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Theme.Colors.secondary)
                                }
                                .padding()
                                .background(Theme.Colors.secondaryBackground)
                                .cornerRadius(12)
                            }
                        }
                        
                        // Host info
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.Colors.secondary)
                            
                            VStack(alignment: .leading) {
                                Text("Hosted by")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.Colors.secondaryText)
                                Text(sale.hostName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Theme.Colors.text)
                            }
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Text("Message")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Theme.Colors.primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Theme.Colors.primary.opacity(0.1))
                                    .cornerRadius(20)
                            }
                        }
                        .padding()
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    
                    // Map
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: sale.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), annotationItems: [sale]) { _ in
                        MapMarker(coordinate: sale.coordinate, tint: Theme.Colors.primary)
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding(.horizontal, Theme.Spacing.md)
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: openDirections) {
                            HStack {
                                Image(systemName: "car.fill")
                                Text("Get Directions")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.Colors.primary)
                            .cornerRadius(12)
                        }
                        
                        Button(action: shareGarageSale) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Theme.Colors.primary)
                                .frame(width: 56, height: 56)
                                .background(Theme.Colors.primary.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.bottom, Theme.Spacing.xl)
                }
            }
            .navigationBarHidden(true)
            .overlay(
                // Close button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.Colors.text)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color.white.opacity(0.9)))
                                .shadow(color: Color.black.opacity(0.1), radius: 4)
                        }
                        .padding()
                    }
                    Spacer()
                }
            )
        .sheet(isPresented: $showingListings) {
            GarageSaleListingsView(sale: sale)
        }
        .sheet(isPresented: $showingShareSheet) {
            GarageSaleShareSheet(activityItems: shareItems)
        }
    }
    
    // MARK: - Helper Functions
    
    private func openDirections() {
        let coordinate = sale.coordinate
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = sale.title
        
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    private func shareGarageSale() {
        let message = "Check out this garage sale: \(sale.title)\n\n\(sale.fullDateString)\n\(sale.address ?? sale.location)\n\nFind more garage sales on Brrow!"
        let url = URL(string: "https://brrowapp.com/garage-sale/\(sale.id)")
        
        var items: [Any] = [message]
        if let url = url {
            items.append(url)
        }
        
        shareItems = items
        showingShareSheet = true
    }
}

// MARK: - Garage Sale Listings View
struct GarageSaleListingsView: View {
    let sale: GarageSaleItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    // Info banner
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(Theme.Colors.primary)
                        
                        Text("These items will be available at the garage sale")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.text)
                    }
                    .padding()
                    .background(Theme.Colors.primary.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, Theme.Spacing.md)
                    
                    // Listings grid
                    if sale.associatedListingCount > 0 {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            // Fetch listings for this garage sale (mock implementation)
                            // In a real app, use API call: APIClient.shared.fetchListingsForGarageSale(sale.id)
                            ForEach(0..<1, id: \.self) { _ in
                                VStack(spacing: 16) {
                                    Image(systemName: "cube.box")
                                        .font(.system(size: 48))
                                        .foregroundColor(.secondary.opacity(0.5))
                                    
                                    Text("Loading items...")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .gridCellColumns(2)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.bottom, Theme.Spacing.xl)
                    } else {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "cube.box")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.5))
                            
                            Text("No items listed yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("The host hasn't added any specific items for this sale")
                                .font(.subheadline)
                                .foregroundColor(.secondary.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                        .padding(.horizontal, Theme.Spacing.md)
                    }
                }
            }
            .navigationTitle("Items at this sale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Garage Sale Listing Card
struct GarageSaleListingCard: View {
    var body: some View {
        VStack(spacing: 0) {
            // Image with badge
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Theme.Colors.secondary.opacity(0.2))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(Theme.Colors.secondary)
                    )
                
                // Garage sale badge
                HStack(spacing: 4) {
                    Image(systemName: "house.fill")
                    Text("At sale")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.Colors.primary)
                .cornerRadius(12)
                .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Item Name")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(2)
                
                HStack {
                    Text("$25")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("/day")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    Spacer()
                }
            }
            .padding(12)
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(12)
        .shadow(color: Theme.Shadows.card, radius: Theme.Shadows.cardRadius, y: 2)
    }
}

// MARK: - Models
// GarageSaleItem is defined as a typealias above

// MARK: - View Model
class GarageSaleMapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @Published var allGarageSales: [GarageSaleItem] = []
    @Published var showBoostedOnly = false
    @Published var showBusinessOnly = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let locationService = LocationService.shared
    
    init() {
        loadGarageSales()
    }
    
    func loadGarageSales() {
        isLoading = true
        errorMessage = nil
        
        // Update region based on user location if available
        if let userLocation = locationService.currentLocation {
            region = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        
        // Fetch garage sales from API
        Task {
            do {
                let apiSales = try await APIClient.shared.fetchGarageSales()
                await MainActor.run {
                    self.allGarageSales = apiSales
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load garage sales: \(error.localizedDescription)"
                    self.allGarageSales = [] // Clear any existing data
                    self.isLoading = false
                }
            }
        }
    }
    
    func toggleFilter() {
        showBoostedOnly.toggle()
    }
    
    func toggleBusinessFilter() {
        showBusinessOnly.toggle()
    }
    
    var filteredGarageSales: [GarageSaleItem] {
        var filtered = allGarageSales
        
        if showBoostedOnly {
            filtered = filtered.filter { $0.isBoosted }
        }
        
        if showBusinessOnly {
            filtered = filtered.filter { $0.isBusiness }
        }
        
        return filtered
    }
}