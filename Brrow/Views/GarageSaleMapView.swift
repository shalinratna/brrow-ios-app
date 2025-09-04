import SwiftUI
import MapKit

struct GarageSaleMapView: View {
    let garageSales: [GarageSale]
    @StateObject private var locationManager = LocationService.shared
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedSale: GarageSale?
    @State private var showingSaleDetail = false
    @State private var showingPreview = false
    @State private var mapStyle: MapStyle = .standard
    @State private var showUserLocation = true
    @State private var showBusinessOnly = false
    
    enum MapStyle: String, CaseIterable {
        case standard = "Standard"
        case satellite = "Satellite"
        case hybrid = "Hybrid"
        
        var mapType: MKMapType {
            switch self {
            case .standard: return .standard
            case .satellite: return .satellite
            case .hybrid: return .hybrid
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Debug info
            let filteredSales = showBusinessOnly ? garageSales.filter { $0.isBusiness } : garageSales
            let _ = print("🗺️ DEBUG: GarageSaleMapView rendering with \(garageSales.count) total sales, \(filteredSales.count) filtered sales")
            
            // Map
            MapViewRepresentable(
                region: $region,
                garageSales: filteredSales,
                selectedSale: $selectedSale,
                showingPreview: $showingPreview,
                mapType: mapStyle.mapType,
                showUserLocation: showUserLocation
            )
            .ignoresSafeArea()
            
            // Map controls overlay
            VStack {
                // Top controls
                HStack {
                    // Map style selector
                    Menu {
                        ForEach(MapStyle.allCases, id: \.self) { style in
                            Button(action: { mapStyle = style }) {
                                Label(style.rawValue, systemImage: style == mapStyle ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Image(systemName: "map")
                            .font(.title3)
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color(.systemBackground))
                                    .shadow(radius: 4)
                            )
                    }
                    
                    Spacer()
                    
                    // Current location button
                    Button(action: centerOnUserLocation) {
                        Image(systemName: "location.fill")
                            .font(.title3)
                            .foregroundColor(showUserLocation ? Theme.Colors.primary : .gray)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color(.systemBackground))
                                    .shadow(radius: 4)
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                Spacer()
                
                // Empty space at bottom for popup to appear
            }
            
            // Live indicator
            if garageSales.contains(where: { $0.isActive }) {
                VStack {
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(Color.red.opacity(0.3), lineWidth: 8)
                                        .scaleEffect(2)
                                        .opacity(0)
                                        .animate(using: .easeOut(duration: 1).repeatForever(autoreverses: false)) { view in
                                            view
                                                .scaleEffect(1)
                                                .opacity(1)
                                        }
                                )
                            
                            Text("\(garageSales.filter { $0.isActive }.count) LIVE")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                        )
                        .padding(.trailing)
                    }
                    
                    Spacer()
                }
                .padding(.top, 80)
            }
            
            // Preview Popup with backdrop
            if showingPreview, let selectedSale = selectedSale {
                // Tap outside to dismiss
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showingPreview = false
                            self.selectedSale = nil
                        }
                    }
                    .zIndex(1)
                
                VStack {
                    Spacer()
                    GarageSalePreviewPopup(
                        garageSale: selectedSale,
                        isShowing: $showingPreview,
                        onViewDetails: {
                            showingSaleDetail = true
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.height > 100 {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        showingPreview = false
                                        self.selectedSale = nil
                                    }
                                }
                            }
                    )
                }
                .zIndex(2)
            }
        }
        .sheet(isPresented: $showingSaleDetail) {
            if let sale = selectedSale {
                GarageSaleDetailSheet(garageSale: sale)
            }
        }
        .onAppear {
            setupInitialRegion()
        }
    }
    
    private func centerOnUserLocation() {
        if let location = locationManager.currentLocation {
            withAnimation {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
        }
    }
    
    private func centerOnGarageSale(_ sale: GarageSale) {
        withAnimation {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: sale.latitude ?? 37.7749,
                    longitude: sale.longitude ?? -122.4194
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }
    }
    
    private func setupInitialRegion() {
        if let firstSale = garageSales.first {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: firstSale.latitude ?? 37.7749,
                    longitude: firstSale.longitude ?? -122.4194
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        } else if let userLocation = locationManager.currentLocation {
            region = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
    }
}

// MARK: - Map View Representable

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let garageSales: [GarageSale]
    @Binding var selectedSale: GarageSale?
    @Binding var showingPreview: Bool
    let mapType: MKMapType
    let showUserLocation: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = showUserLocation
        mapView.showsCompass = false
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.mapType = mapType
        mapView.showsUserLocation = showUserLocation
        
        // Update annotations
        mapView.removeAnnotations(mapView.annotations)
        let annotations = garageSales.map { GarageSaleAnnotation(garageSale: $0) }
        print("📍 DEBUG: Adding \(annotations.count) garage sale annotations")
        mapView.addAnnotations(annotations)
        
        // Update region only if it changed significantly
        if !mapView.region.isEqual(region) {
            mapView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            print("🎨 DEBUG: Creating view for annotation: \(type(of: annotation))")
            guard let saleAnnotation = annotation as? GarageSaleAnnotation else { 
                print("❌ DEBUG: Not a GarageSaleAnnotation, skipping")
                return nil 
            }
            print("✅ DEBUG: Creating marker for garage sale: \(saleAnnotation.garageSale.title)")
            
            let identifier = "GarageSale"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
                annotationView?.isEnabled = true
                annotationView?.isUserInteractionEnabled = true
            } else {
                annotationView?.annotation = annotation
                annotationView?.isEnabled = true
                annotationView?.isUserInteractionEnabled = true
            }
            
            // Use the old marker design - green color for all
            annotationView?.markerTintColor = UIColor(Theme.Colors.primary)
            annotationView?.glyphImage = UIImage(systemName: "house.fill")
            
            // Add subtle differentiation for special types
            if saleAnnotation.garageSale.isBusiness {
                annotationView?.glyphImage = UIImage(systemName: "building.2.fill")
            }
            
            // Show red tint only for active sales
            if saleAnnotation.garageSale.isActive {
                annotationView?.markerTintColor = .systemRed
            }
            
            // Add pulse animation for active sales
            if saleAnnotation.garageSale.isActive {
                annotationView?.animatesWhenAdded = true
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            print("🔥 DEBUG: Map annotation tapped!")
            guard let saleAnnotation = view.annotation as? GarageSaleAnnotation else { 
                print("❌ DEBUG: Not a GarageSaleAnnotation")
                return 
            }
            print("✅ DEBUG: GarageSaleAnnotation detected: \(saleAnnotation.garageSale.title)")
            
            // Zoom into the selected marker
            let region = MKCoordinateRegion(
                center: saleAnnotation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            mapView.setRegion(region, animated: true)
            
            // Deselect the annotation to allow it to be selected again
            mapView.deselectAnnotation(view.annotation, animated: false)
            
            DispatchQueue.main.async {
                self.parent.selectedSale = saleAnnotation.garageSale
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.parent.showingPreview = true
                    print("🎉 DEBUG: Showing preview popup")
                }
            }
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            parent.region = mapView.region
        }
    }
}

// MARK: - Garage Sale Annotation

class GarageSaleAnnotation: NSObject, MKAnnotation {
    let garageSale: GarageSale
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: garageSale.latitude ?? 37.7749,
            longitude: garageSale.longitude ?? -122.4194
        )
    }
    
    var title: String? {
        garageSale.title
    }
    
    var subtitle: String? {
        "\(garageSale.photos.count) items • \(garageSale.isActive ? "LIVE NOW" : formatDate(garageSale.startDate))"
    }
    
    init(garageSale: GarageSale) {
        self.garageSale = garageSale
        super.init()
        print("📍 DEBUG: Creating annotation for '\(garageSale.title)' at (\(garageSale.latitude ?? 0), \(garageSale.longitude ?? 0))")
    }
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = inputFormatter.date(from: dateString) else { return dateString }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct GarageSaleMapCard: View {
    let garageSale: GarageSale
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if garageSale.isActive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                            Text("LIVE")
                                .font(.caption2.bold())
                                .foregroundColor(.red)
                        }
                    } else {
                        Text(formatTime(garageSale.startDate))
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    Text(formatDistance(garageSale.distance))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(garageSale.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                    Text(garageSale.address ?? garageSale.location)
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundColor(.secondary)
                
                Label("\(garageSale.photos.count) items", systemImage: "cube.box")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 250)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
                    )
                    .shadow(radius: 8)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDistance(_ distance: Double?) -> String {
        guard let distance = distance else { return "" }
        if distance < 1 {
            return String(format: "%.0f ft", distance * 5280)
        } else {
            return String(format: "%.1f mi", distance)
        }
    }
    
    private func formatTime(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = inputFormatter.date(from: dateString) else { return dateString }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct GarageSaleDetailSheet: View {
    let garageSale: GarageSale
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Images
                    if !garageSale.images.isEmpty {
                        TabView {
                            ForEach(garageSale.images, id: \.self) { imageUrl in
                                AsyncImage(url: URL(string: imageUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                }
                                .frame(height: 250)
                                .clipped()
                            }
                        }
                        .frame(height: 250)
                        .tabViewStyle(PageTabViewStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Status and title
                        if garageSale.isActive {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                                Text("LIVE NOW")
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Text(garageSale.title)
                            .font(.largeTitle.bold())
                        
                        // Info
                        VStack(alignment: .leading, spacing: 12) {
                            Label(garageSale.address ?? garageSale.location, systemImage: "location.fill")
                            Label(formatDateRange(start: garageSale.startDate, end: garageSale.endDate), systemImage: "calendar")
                            Label("\(garageSale.photos.count) items available", systemImage: "cube.box")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        
                        // Description
                        if let description = garageSale.description {
                            Text(description)
                                .font(.body)
                        }
                        
                        // Get directions button
                        Button(action: openInMaps) {
                            Label("Get Directions", systemImage: "map.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.Colors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
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
    
    private func formatDateRange(start: String, end: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        guard let startDate = inputFormatter.date(from: start),
              let endDate = inputFormatter.date(from: end) else {
            return "\(start) - \(end)"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        let startStr = formatter.string(from: startDate)
        formatter.dateFormat = "h:mm a"
        let endStr = formatter.string(from: endDate)
        return "\(startStr) - \(endStr)"
    }
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: garageSale.latitude ?? 37.7749,
            longitude: garageSale.longitude ?? -122.4194
        )
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = garageSale.title
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Extensions

extension MKCoordinateRegion: @retroactive Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        lhs.center.latitude == rhs.center.latitude &&
        lhs.center.longitude == rhs.center.longitude &&
        lhs.span.latitudeDelta == rhs.span.latitudeDelta &&
        lhs.span.longitudeDelta == rhs.span.longitudeDelta
    }
    
    func isEqual(_ other: MKCoordinateRegion, tolerance: Double = 0.001) -> Bool {
        abs(center.latitude - other.center.latitude) < tolerance &&
        abs(center.longitude - other.center.longitude) < tolerance &&
        abs(span.latitudeDelta - other.span.latitudeDelta) < tolerance &&
        abs(span.longitudeDelta - other.span.longitudeDelta) < tolerance
    }
}

// Animation helper
extension View {
    func animate<Result>(using animation: Animation = .easeInOut(duration: 1), _ action: @escaping (Self) -> Result) -> Result {
        withAnimation(animation) {
            action(self)
        }
    }
}