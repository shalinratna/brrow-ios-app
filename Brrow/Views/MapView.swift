//
//  MapView.swift
//  Brrow
//
//  Interactive map view showing nearby listings, garage sales, and seeks
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @StateObject private var locationManager = LocationManager.shared
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedItem: MapItem?
    @State private var showingFilter = false
    @State private var mapItems: [MapItem] = []
    @State private var isLoading = false
    @State private var searchRadius: Double = 10
    @State private var filterType: String = "all"
    @State private var selectedCategory: String?
    @State private var showingLocationPermission = false
    
    // Map annotation for items
    struct MapItem: Identifiable {
        let id: String
        let coordinate: CLLocationCoordinate2D
        let title: String
        let subtitle: String
        let type: ItemType
        let price: Double?
        let imageUrl: String?
        let userId: Int
        
        enum ItemType {
            case listing
            case garageSale
            case seek
            
            var color: Color {
                switch self {
                case .listing:
                    return .blue
                case .garageSale:
                    return .green
                case .seek:
                    return .orange
                }
            }
            
            var icon: String {
                switch self {
                case .listing:
                    return "tag.fill"
                case .garageSale:
                    return "house.fill"
                case .seek:
                    return "magnifyingglass"
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Map
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                annotationItems: mapItems) { item in
                MapPin(coordinate: item.coordinate, tint: item.type == .listing ? .blue : .red)
            }
            .ignoresSafeArea()
            
            // Controls overlay
            VStack {
                // Top controls
                HStack {
                    // Search radius selector
                    Menu {
                        ForEach([1, 5, 10, 20, 50], id: \.self) { radius in
                            Button(action: {
                                searchRadius = Double(radius)
                                loadNearbyItems()
                            }) {
                                Label("\(radius) km", systemImage: searchRadius == Double(radius) ? "checkmark" : "")
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "location.circle.fill")
                            Text("\(Int(searchRadius)) km")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.regularMaterial)
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    // Filter button
                    Button(action: { showingFilter = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .background(Circle().fill(.regularMaterial))
                    }
                    
                    // Center on user location
                    Button(action: centerOnUserLocation) {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .background(Circle().fill(.regularMaterial))
                    }
                }
                .padding()
                
                Spacer()
                
                // Stats bar
                if !mapItems.isEmpty {
                    HStack(spacing: 20) {
                        StatBadge(
                            icon: "tag.fill",
                            count: mapItems.filter { $0.type == .listing }.count,
                            color: .blue
                        )
                        StatBadge(
                            icon: "house.fill",
                            count: mapItems.filter { $0.type == .garageSale }.count,
                            color: .green
                        )
                        StatBadge(
                            icon: "magnifyingglass",
                            count: mapItems.filter { $0.type == .seek }.count,
                            color: .orange
                        )
                    }
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(15)
                    .padding(.bottom)
                }
            }
            
            // Loading overlay
            if isLoading {
                ProgressView("Loading nearby items...")
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(10)
            }
        }
        .sheet(item: $selectedItem) { item in
            ItemDetailSheet(item: item)
        }
        .sheet(isPresented: $showingFilter) {
            MapFilterView(
                filterType: $filterType,
                selectedCategory: $selectedCategory,
                onApply: {
                    showingFilter = false
                    loadNearbyItems()
                }
            )
        }
        .alert("Location Permission Required", isPresented: $showingLocationPermission) {
            Button("Open Settings") {
                LocationManager.openSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable location access to see nearby items on the map.")
        }
        .onAppear {
            checkLocationPermission()
        }
        .onChange(of: locationManager.currentLocation) { _ in
            if let location = locationManager.currentLocation {
                updateRegion(for: location)
                loadNearbyItems()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestLocationPermission()
        case .denied, .restricted:
            showingLocationPermission = true
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    private func centerOnUserLocation() {
        if let location = locationManager.currentLocation {
            withAnimation {
                region.center = location.coordinate
            }
        } else {
            locationManager.requestSingleLocation()
        }
    }
    
    private func updateRegion(for location: CLLocation) {
        withAnimation {
            region.center = location.coordinate
        }
    }
    
    private func loadNearbyItems() {
        guard let location = locationManager.currentLocation else { return }
        
        isLoading = true
        
        Task {
            do {
                let response = try await locationManager.searchNearby(
                    radius: searchRadius,
                    type: filterType,
                    category: selectedCategory
                )
                
                await MainActor.run {
                    processSearchResults(response)
                    isLoading = false
                }
            } catch {
                print("Failed to load nearby items: \(error)")
                isLoading = false
            }
        }
    }
    
    private func processSearchResults(_ response: [String: Any]) {
        guard let data = response["data"] as? [[String: Any]] else { return }
        
        var newItems: [MapItem] = []
        
        for item in data {
            guard let resultType = item["result_type"] as? String,
                  let id = item["id"],
                  let title = item["title"] as? String,
                  let lat = item["latitude"] as? Double,
                  let lng = item["longitude"] as? Double,
                  let userId = item["user_id"] as? Int else {
                continue
            }
            
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let price = item["price"] as? Double
            let images = item["images"] as? [String]
            let imageUrl = images?.first
            
            let type: MapItem.ItemType
            var subtitle = ""
            
            switch resultType {
            case "listing":
                type = .listing
                if let priceValue = price {
                    subtitle = "$\(String(format: "%.2f", priceValue))"
                }
                if let condition = item["condition"] as? String {
                    subtitle += subtitle.isEmpty ? condition : " • \(condition)"
                }
                
            case "garage_sale":
                type = .garageSale
                if let saleDate = item["sale_date"] as? String,
                   let when = item["when"] as? String {
                    subtitle = when
                }
                
            case "seek":
                type = .seek
                if let minBudget = item["min_budget"] as? Double,
                   let maxBudget = item["max_budget"] as? Double {
                    subtitle = "$\(Int(minBudget))-$\(Int(maxBudget))"
                }
                
            default:
                continue
            }
            
            let mapItem = MapItem(
                id: "\(resultType)_\(id)",
                coordinate: coordinate,
                title: title,
                subtitle: subtitle,
                type: type,
                price: price,
                imageUrl: imageUrl,
                userId: userId
            )
            
            newItems.append(mapItem)
        }
        
        mapItems = newItems
    }
}

// MARK: - Supporting Views

struct StatBadge: View {
    let icon: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

struct ItemDetailSheet: View {
    let item: MapView.MapItem
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Image
                    if let imageUrl = item.imageUrl,
                       let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxHeight: 250)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 250)
                                .overlay(
                                    ProgressView()
                                )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Type badge
                        HStack {
                            Image(systemName: item.type.icon)
                            Text(item.type == .listing ? "Listing" : 
                                 item.type == .garageSale ? "Garage Sale" : "Seek")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(item.type.color)
                        .cornerRadius(15)
                        
                        // Title
                        Text(item.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Subtitle/Price
                        if !item.subtitle.isEmpty {
                            Text(item.subtitle)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Distance
                        if let location = LocationManager.shared.currentLocation {
                            let itemLocation = CLLocation(
                                latitude: item.coordinate.latitude,
                                longitude: item.coordinate.longitude
                            )
                            Text(LocationManager.shared.distanceString(from: itemLocation))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Action button
                        Button(action: {
                            // Navigate to appropriate detail view
                            dismiss()
                        }) {
                            Text("View Details")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.top)
                    }
                    .padding()
                }
            }
            .navigationTitle("Item Details")
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

struct MapFilterView: View {
    @Binding var filterType: String
    @Binding var selectedCategory: String?
    let onApply: () -> Void
    @Environment(\.dismiss) var dismiss
    
    let categories = [
        "Electronics", "Furniture", "Clothing", "Sports",
        "Books", "Tools", "Toys", "Other"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Item Type") {
                    Picker("Type", selection: $filterType) {
                        Text("All").tag("all")
                        Text("Listings").tag("listings")
                        Text("Garage Sales").tag("garage_sales")
                        Text("Seeks").tag("seeks")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if filterType == "listings" || filterType == "seeks" {
                    Section("Category") {
                        ForEach(categories, id: \.self) { category in
                            HStack {
                                Text(category)
                                Spacer()
                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedCategory == category {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                }
            }
        }
    }
}