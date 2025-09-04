//
//  NearbyListingsView.swift
//  Brrow
//
//  List view showing nearby listings, garage sales, and seeks based on location
//

import SwiftUI
import CoreLocation

struct NearbyListingsView: View {
    @StateObject private var locationManager = LocationManager.shared
    @State private var nearbyItems: [NearbyItem] = []
    @State private var isLoading = false
    @State private var searchRadius: Double = 10
    @State private var selectedType: String = "all"
    @State private var selectedSort: String = "distance"
    @State private var showingLocationAlert = false
    @State private var errorMessage: String?
    
    struct NearbyItem: Identifiable {
        let id: String
        let type: String
        let title: String
        let description: String
        let price: Double?
        let distance: Double
        let distanceDisplay: String
        let images: [String]
        let category: String?
        let address: String?
        let userId: Int
        let createdAt: String
        
        // Garage sale specific
        let saleDate: String?
        let startTime: String?
        let endTime: String?
        let when: String?
        
        // Seek specific
        let minBudget: Double?
        let maxBudget: Double?
        let urgency: String?
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if nearbyItems.isEmpty && !isLoading {
                    NearbyEmptyStateView()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Location status bar
                            LocationStatusBar()
                            
                            // Filter controls
                            FilterControlsView(
                                selectedType: $selectedType,
                                selectedSort: $selectedSort,
                                searchRadius: $searchRadius,
                                onFilterChange: refreshItems
                            )
                            
                            // Items list
                            LazyVStack(spacing: 12) {
                                ForEach(nearbyItems) { item in
                                    NearbyItemCard(item: item)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
                
                if isLoading {
                    NearbyLoadingOverlay()
                }
            }
            .navigationTitle("Nearby")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Navigate to map view
                    }) {
                        Image(systemName: "map")
                    }
                }
            }
            .alert("Location Required", isPresented: $showingLocationAlert) {
                Button("Open Settings") {
                    LocationManager.openSettings()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Please enable location access to see nearby items.")
            }
            .onAppear {
                checkLocationAndLoad()
            }
            .refreshable {
                await refreshItemsAsync()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkLocationAndLoad() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestLocationPermission()
        case .denied, .restricted:
            errorMessage = locationManager.locationError?.localizedDescription
            showingLocationAlert = true
        case .authorizedWhenInUse, .authorizedAlways:
            if locationManager.currentLocation == nil {
                locationManager.startLocationUpdates()
            } else {
                refreshItems()
            }
        @unknown default:
            break
        }
    }
    
    private func refreshItems() {
        guard locationManager.currentLocation != nil else {
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let response = try await locationManager.searchNearby(
                    radius: searchRadius,
                    type: selectedType,
                    sort: selectedSort
                )
                
                await MainActor.run {
                    processResults(response)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    @MainActor
    private func refreshItemsAsync() async {
        guard locationManager.currentLocation != nil else {
            return
        }
        
        do {
            let response = try await locationManager.searchNearby(
                radius: searchRadius,
                type: selectedType,
                sort: selectedSort
            )
            processResults(response)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func processResults(_ response: [String: Any]) {
        guard let data = response["data"] as? [[String: Any]] else { return }
        
        var items: [NearbyItem] = []
        
        for itemData in data {
            guard let resultType = itemData["result_type"] as? String,
                  let id = itemData["id"],
                  let title = itemData["title"] as? String,
                  let userId = itemData["user_id"] as? Int,
                  let distance = itemData["distance_km"] as? Double,
                  let distanceDisplay = itemData["distance_display"] as? String else {
                continue
            }
            
            let item = NearbyItem(
                id: "\(resultType)_\(id)",
                type: resultType,
                title: title,
                description: itemData["description"] as? String ?? "",
                price: itemData["price"] as? Double,
                distance: distance,
                distanceDisplay: distanceDisplay,
                images: itemData["images"] as? [String] ?? [],
                category: itemData["category"] as? String,
                address: itemData["address"] as? String,
                userId: userId,
                createdAt: itemData["created_at"] as? String ?? "",
                saleDate: itemData["sale_date"] as? String,
                startTime: itemData["start_time"] as? String,
                endTime: itemData["end_time"] as? String,
                when: itemData["when"] as? String,
                minBudget: itemData["min_budget"] as? Double,
                maxBudget: itemData["max_budget"] as? Double,
                urgency: itemData["urgency"] as? String
            )
            
            items.append(item)
        }
        
        nearbyItems = items
        
        // Update nearby counts in location manager
        if let stats = response["stats"] as? [String: Any] {
            locationManager.nearbyListings = stats["listings_count"] as? Int ?? 0
            locationManager.nearbyGarageSales = stats["garage_sales_count"] as? Int ?? 0
            locationManager.matchingSeeks = stats["seeks_count"] as? Int ?? 0
        }
    }
}

// MARK: - Supporting Views

struct LocationStatusBar: View {
    @ObservedObject private var locationManager = LocationManager.shared
    
    var body: some View {
        HStack {
            Image(systemName: "location.fill")
                .foregroundColor(.blue)
            
            if locationManager.isLocationAvailable {
                Text(locationManager.address.isEmpty ? "Current Location" : locationManager.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    if locationManager.nearbyListings > 0 {
                        Label("\(locationManager.nearbyListings)", systemImage: "tag.fill")
                            .font(.caption)
                    }
                    if locationManager.nearbyGarageSales > 0 {
                        Label("\(locationManager.nearbyGarageSales)", systemImage: "house.fill")
                            .font(.caption)
                    }
                    if locationManager.matchingSeeks > 0 {
                        Label("\(locationManager.matchingSeeks)", systemImage: "magnifyingglass")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            } else {
                Text("Location not available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Enable") {
                    locationManager.requestLocationPermission()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}

struct FilterControlsView: View {
    @Binding var selectedType: String
    @Binding var selectedSort: String
    @Binding var searchRadius: Double
    let onFilterChange: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Type filter
                Menu {
                    Button("All Items") {
                        selectedType = "all"
                        onFilterChange()
                    }
                    Button("Listings") {
                        selectedType = "listings"
                        onFilterChange()
                    }
                    Button("Garage Sales") {
                        selectedType = "garage_sales"
                        onFilterChange()
                    }
                    Button("Seeks") {
                        selectedType = "seeks"
                        onFilterChange()
                    }
                } label: {
                    NearbyFilterChip(
                        title: selectedType == "all" ? "All Items" :
                               selectedType == "listings" ? "Listings" :
                               selectedType == "garage_sales" ? "Garage Sales" : "Seeks",
                        isSelected: selectedType != "all"
                    )
                }
                
                // Sort filter
                Menu {
                    Button("Distance") {
                        selectedSort = "distance"
                        onFilterChange()
                    }
                    Button("Newest") {
                        selectedSort = "newest"
                        onFilterChange()
                    }
                    Button("Price: Low to High") {
                        selectedSort = "price_low"
                        onFilterChange()
                    }
                    Button("Price: High to Low") {
                        selectedSort = "price_high"
                        onFilterChange()
                    }
                } label: {
                    NearbyFilterChip(
                        title: selectedSort == "distance" ? "Nearest" :
                               selectedSort == "newest" ? "Newest" :
                               selectedSort == "price_low" ? "Price ↑" : "Price ↓",
                        isSelected: true
                    )
                }
                
                // Radius filter
                Menu {
                    ForEach([1, 5, 10, 20, 50], id: \.self) { radius in
                        Button("\(radius) km") {
                            searchRadius = Double(radius)
                            onFilterChange()
                        }
                    }
                } label: {
                    NearbyFilterChip(
                        title: "\(Int(searchRadius)) km",
                        isSelected: true
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct NearbyFilterChip: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(15)
    }
}

struct NearbyItemCard: View {
    let item: NearbyListingsView.NearbyItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image and type badge
            ZStack(alignment: .topLeading) {
                if let firstImage = item.images.first,
                   let url = URL(string: firstImage) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: itemTypeIcon(item.type))
                                .font(.largeTitle)
                                .foregroundColor(.gray.opacity(0.3))
                        )
                }
                
                // Type badge
                HStack {
                    Image(systemName: itemTypeIcon(item.type))
                    Text(itemTypeLabel(item.type))
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(itemTypeColor(item.type))
                .cornerRadius(8)
                .padding(8)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Title and distance
                HStack(alignment: .top) {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.distanceDisplay)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        if let when = item.when {
                            Text(when)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Description
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Price/Budget
                HStack {
                    if let price = item.price {
                        Text("$\(String(format: "%.2f", price))")
                            .font(.headline)
                            .foregroundColor(.primary)
                    } else if let minBudget = item.minBudget,
                              let maxBudget = item.maxBudget {
                        Text("$\(Int(minBudget))-$\(Int(maxBudget))")
                            .font(.headline)
                            .foregroundColor(.orange)
                    } else if item.type == "garage_sale",
                              let startTime = item.startTime,
                              let endTime = item.endTime {
                        Text("\(formatTime(startTime)) - \(formatTime(endTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let category = item.category {
                        Text(category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func itemTypeIcon(_ type: String) -> String {
        switch type {
        case "listing": return "tag.fill"
        case "garage_sale": return "house.fill"
        case "seek": return "magnifyingglass"
        default: return "questionmark.circle"
        }
    }
    
    private func itemTypeLabel(_ type: String) -> String {
        switch type {
        case "listing": return "Listing"
        case "garage_sale": return "Garage Sale"
        case "seek": return "Seek"
        default: return "Unknown"
        }
    }
    
    private func itemTypeColor(_ type: String) -> Color {
        switch type {
        case "listing": return .blue
        case "garage_sale": return .green
        case "seek": return .orange
        default: return .gray
        }
    }
    
    private func formatTime(_ time: String) -> String {
        // Convert "HH:mm:ss" to "h:mm a"
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        guard let date = formatter.date(from: time) else { return time }
        
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct NearbyEmptyStateView: View {
    @ObservedObject private var locationManager = LocationManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: locationManager.authorizationStatus == .denied ? 
                  "location.slash.fill" : "map.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(locationManager.authorizationStatus == .denied ?
                 "Location Access Required" : "No Nearby Items")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(locationManager.authorizationStatus == .denied ?
                 "Enable location access to see items near you" :
                 "No listings, garage sales, or seeks found nearby")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if locationManager.authorizationStatus == .denied {
                Button(action: {
                    LocationManager.openSettings()
                }) {
                    Text("Open Settings")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(25)
                }
            }
        }
        .padding()
    }
}

struct NearbyLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Finding nearby items...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(.regularMaterial)
            .cornerRadius(10)
        }
    }
}