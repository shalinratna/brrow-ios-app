//
//  EnhancedGarageSaleMapView.swift
//  Brrow
//
//  Enhanced garage sale map with list view and navigation features
//

import SwiftUI
import MapKit

struct EnhancedGarageSaleMapView: View {
    @State private var garageSales: [GarageSale] = []
    @State private var visibleGarageSales: [GarageSale] = []
    @State private var selectedSale: GarageSale?
    @State private var showingPreview = false
    @State private var showingSaleDetail = false
    @State private var showingListView = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var trackingMode: MKUserTrackingMode = .follow
    @State private var mapRef: MKMapView?
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Map View
            MapViewWithAnnotations(
                garageSales: garageSales,
                selectedSale: $selectedSale,
                showingPreview: $showingPreview,
                region: $region,
                visibleSales: $visibleGarageSales,
                mapRef: $mapRef
            )
            .ignoresSafeArea()
            
            // Top Controls
            VStack {
                HStack {
                    // Back button
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(Theme.Colors.primary)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color(.systemBackground))
                                    .shadow(radius: 4)
                            )
                    }
                    .padding(.leading)
                    
                    Spacer()
                    
                    // List view toggle
                    Button(action: { showingListView = true }) {
                        VStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .font(.title3)
                            Text("List")
                                .font(.caption2)
                        }
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 60, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(radius: 4)
                        )
                    }
                    .padding(.trailing)
                }
                .padding(.top, 50)
                
                // Active sales indicator
                if !visibleGarageSales.filter({ $0.isActive }).isEmpty {
                    HStack {
                        Spacer()
                        ActiveSalesIndicator(count: visibleGarageSales.filter { $0.isActive }.count)
                            .padding(.trailing)
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
            }
            
            // Selected sale preview
            if showingPreview, let selectedSale = selectedSale {
                VStack {
                    Spacer()
                    EnhancedGarageSalePreview(
                        garageSale: selectedSale,
                        isShowing: $showingPreview,
                        onViewDetails: {
                            showingSaleDetail = true
                        },
                        onNavigate: {
                            centerMapOnSale(selectedSale)
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $showingListView) {
            GarageSaleListView(
                garageSales: visibleGarageSales.isEmpty ? garageSales : visibleGarageSales,
                onSelectSale: { sale in
                    selectedSale = sale
                    showingListView = false
                    centerMapOnSale(sale)
                    showingPreview = true
                },
                onClose: {
                    showingListView = false
                }
            )
        }
        .sheet(isPresented: $showingSaleDetail) {
            if let sale = selectedSale {
                NavigationView {
                    GarageSaleDetailView(sale: sale)
                }
            }
        }
        .onAppear {
            loadGarageSales()
        }
    }
    
    private func loadGarageSales() {
        Task {
            do {
                let sales = try await APIClient.shared.fetchGarageSales()
                await MainActor.run {
                    self.garageSales = sales
                    self.visibleGarageSales = sales
                    self.isLoading = false
                    print("📍 Loaded \(sales.count) garage sales for map")
                    
                    // Debug: Print image URLs for first few sales
                    for sale in sales.prefix(3) {
                        print("🏠 \(sale.title):")
                        print("   - images array: \(sale.images)")
                        print("   - photos computed: \(sale.photos.map { $0.url })")
                    }
                    
                    // Center map on first sale if available
                    if let firstSale = sales.first,
                       let lat = firstSale.latitude,
                       let lon = firstSale.longitude {
                        region.center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    }
                }
            } catch {
                print("❌ Failed to load garage sales: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func centerMapOnSale(_ sale: GarageSale) {
        guard let lat = sale.latitude, let lon = sale.longitude else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        
        // Programmatically select the annotation
        if let mapView = mapRef {
            for annotation in mapView.annotations {
                if let saleAnnotation = annotation as? GarageSaleAnnotation,
                   saleAnnotation.garageSale.id == sale.id {
                    mapView.selectAnnotation(annotation, animated: true)
                    break
                }
            }
        }
    }
}

// MARK: - Map View with Annotations
struct MapViewWithAnnotations: UIViewRepresentable {
    let garageSales: [GarageSale]
    @Binding var selectedSale: GarageSale?
    @Binding var showingPreview: Bool
    @Binding var region: MKCoordinateRegion
    @Binding var visibleSales: [GarageSale]
    @Binding var mapRef: MKMapView?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: false)
        mapRef = mapView
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update annotations
        mapView.removeAnnotations(mapView.annotations.filter { $0 is GarageSaleAnnotation })
        
        for sale in garageSales {
            let annotation = GarageSaleAnnotation(garageSale: sale)
            mapView.addAnnotation(annotation)
        }
        
        // Update region if changed externally
        if !mapView.region.isEqual(region) {
            mapView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWithAnnotations
        
        init(_ parent: MapViewWithAnnotations) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let saleAnnotation = annotation as? GarageSaleAnnotation else { return nil }
            
            let identifier = "GarageSale"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false // We'll handle our own callout
            } else {
                annotationView?.annotation = annotation
            }
            
            // Customize appearance
            annotationView?.markerTintColor = saleAnnotation.garageSale.isActive ? .systemRed : UIColor(Theme.Colors.primary)
            annotationView?.glyphImage = UIImage(systemName: "house.fill")
            
            if saleAnnotation.garageSale.isBoosted {
                annotationView?.markerTintColor = .systemOrange
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let saleAnnotation = view.annotation as? GarageSaleAnnotation else { return }
            
            print("🎯 Garage sale marker tapped: \(saleAnnotation.garageSale.title)")
            
            DispatchQueue.main.async {
                self.parent.selectedSale = saleAnnotation.garageSale
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.parent.showingPreview = true
                }
            }
            
            // Deselect to allow re-selection
            mapView.deselectAnnotation(view.annotation, animated: false)
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
            updateVisibleSales(in: mapView)
        }
        
        private func updateVisibleSales(in mapView: MKMapView) {
            let visibleRect = mapView.visibleMapRect
            let visibleSales = parent.garageSales.filter { sale in
                guard let lat = sale.latitude, let lon = sale.longitude else { return false }
                let point = MKMapPoint(CLLocationCoordinate2D(latitude: lat, longitude: lon))
                return visibleRect.contains(point)
            }
            
            DispatchQueue.main.async {
                self.parent.visibleSales = visibleSales
            }
        }
    }
}

// MARK: - Enhanced Preview
struct EnhancedGarageSalePreview: View {
    let garageSale: GarageSale
    @Binding var isShowing: Bool
    let onViewDetails: () -> Void
    let onNavigate: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.vertical, 8)
            
            HStack(spacing: 16) {
                // Image
                if let firstImage = garageSale.images.first {
                    AsyncImage(url: URL(string: firstImage)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: "house.fill")
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    // Placeholder when no image
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "house.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(garageSale.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if garageSale.isActive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("LIVE NOW")
                                .font(.caption.bold())
                                .foregroundColor(.red)
                        }
                    }
                    
                    Text(garageSale.address ?? garageSale.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 16) {
                        Button(action: onNavigate) {
                            Label("Navigate", systemImage: "location.fill")
                                .font(.caption.bold())
                                .foregroundColor(Theme.Colors.primary)
                        }
                        
                        Button(action: onViewDetails) {
                            Label("Details", systemImage: "info.circle")
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(radius: 10)
        )
        .padding()
        .onTapGesture {
            // Allow tapping anywhere to view details
            onViewDetails()
        }
    }
}

// MARK: - List View
struct GarageSaleListView: View {
    let garageSales: [GarageSale]
    let onSelectSale: (GarageSale) -> Void
    let onClose: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(garageSales) { sale in
                        GarageSaleListRow(
                            sale: sale,
                            onTap: {
                                onSelectSale(sale)
                            },
                            onViewInMap: {
                                onSelectSale(sale)
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Garage Sales (\(garageSales.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onClose()
                    }
                }
            }
        }
    }
}

// MARK: - List Row
struct GarageSaleListRow: View {
    let sale: GarageSale
    let onTap: () -> Void
    let onViewInMap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Image
                if let firstImage = sale.images.first {
                    AsyncImage(url: URL(string: firstImage)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: "house.fill")
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "house.fill")
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(sale.title)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if sale.isActive {
                            HStack(spacing: 2) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                Text("LIVE")
                                    .font(.caption2.bold())
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Text(sale.address ?? sale.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack {
                        Label("\(sale.photos.count) items", systemImage: "cube.box")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: onViewInMap) {
                            Label("See in Map", systemImage: "map")
                                .font(.caption.bold())
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .onTapGesture {
                onTap()
            }
        }
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Active Sales Indicator
struct ActiveSalesIndicator: View {
    let count: Int
    @State private var pulse = false
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 8)
                        .scaleEffect(pulse ? 2 : 1)
                        .opacity(pulse ? 0 : 1)
                        .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: pulse)
                )
            
            Text("\(count) ACTIVE")
                .font(.caption.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.7))
        )
        .onAppear {
            pulse = true
        }
    }
}

// Helper extension - using existing MKCoordinateRegion extension from GarageSaleMapView.swift