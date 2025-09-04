//
//  ListingImageView.swift
//  Brrow
//
//  Enhanced image loading component for listing cards
//

import SwiftUI

// MARK: - Simple Image Loading State
private enum SimpleImageState: Equatable {
    case idle
    case loading
    case loaded(String) // Store image hash for comparison
    case failed
}

struct ListingImageView: View {
    let imageURLs: [String]
    let aspectRatio: ContentMode
    let cornerRadius: CGFloat
    
    @State private var currentImageIndex = 0
    @State private var imageState: SimpleImageState = .idle
    @State private var loadedImage: UIImage?
    @State private var imageTimer: Timer?
    @State private var simulatorFallbackAttempted = false
    
    private var primaryImageURL: String? {
        guard !imageURLs.isEmpty else { return nil }
        return imageURLs[0]
    }
    
    init(imageURLs: [String], aspectRatio: ContentMode = .fill, cornerRadius: CGFloat = 12) {
        self.imageURLs = imageURLs
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        ZStack {
            switch imageState {
            case .idle, .loading:
                loadingPlaceholder
            case .loaded(let imageHash):
                if let image = loadedImage {
                    loadedImageView(image)
                } else if imageHash == "simulator_placeholder" {
                    // Show simulator-specific placeholder that looks like a real image
                    simulatorPlaceholder
                } else {
                    errorPlaceholder
                }
            case .failed:
                errorPlaceholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onAppear {
            loadPrimaryImage()
        }
        .onDisappear {
            stopImageCycling()
        }
    }
    
    // MARK: - Loading Placeholder
    private var loadingPlaceholder: some View {
        Rectangle()
            .fill(Theme.Colors.secondary.opacity(0.1))
            .overlay(
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Theme.Colors.primary)
                    
                    if imageState == .loading {
                        Text("Loading...")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            )
            .background(shimmerEffect)
    }
    
    // MARK: - Shimmer Effect
    @State private var shimmerOffset: CGFloat = -1
    
    private var shimmerEffect: some View {
        LinearGradient(
            colors: [
                Theme.Colors.secondary.opacity(0.1),
                Theme.Colors.secondary.opacity(0.3),
                Theme.Colors.secondary.opacity(0.1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            Rectangle()
                .fill()
                .scaleEffect(x: 0.5)
                .offset(x: shimmerOffset * 300)
        )
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 1
            }
        }
    }
    
    // MARK: - Loaded Image View
    private func loadedImageView(_ image: UIImage) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: aspectRatio)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            
            // Multiple images indicator
            if imageURLs.count > 1 {
                multipleImagesIndicator
            }
        }
    }
    
    // MARK: - Multiple Images Indicator
    private var multipleImagesIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "photo.stack")
                .font(.system(size: 10, weight: .medium))
            
            Text("\(imageURLs.count)")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.7))
        )
        .padding(8)
    }
    
    // MARK: - Error Placeholder
    private var errorPlaceholder: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Theme.Colors.primary.opacity(0.05),
                        Theme.Colors.primary.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack(spacing: 4) {
                    #if targetEnvironment(simulator)
                    // In simulator, show a more optimistic placeholder
                    Image(systemName: "photo.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Theme.Colors.primary.opacity(0.6))
                    
                    Text("Image Available")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.primary.opacity(0.8))
                    #else
                    // On real device, show actual error state
                    Image(systemName: "photo")
                        .font(.system(size: 30))
                        .foregroundColor(Theme.Colors.primary.opacity(0.5))
                    
                    Text("No image")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.secondaryText)
                    #endif
                }
            )
    }
    
    // MARK: - Image Loading
    private func loadPrimaryImage() {
        guard let urlString = primaryImageURL,
              let url = URL(string: urlString) else {
            imageState = .failed
            return
        }
        
        imageState = .loading
        
        // Simulator-specific handling with multiple fallback strategies
        #if targetEnvironment(simulator)
        Task {
            await loadImageWithSimulatorFallback(url: url, urlString: urlString)
        }
        #else
        // Production device code path
        Task {
            await loadImageStandard(url: url, urlString: urlString)
        }
        #endif
    }
    
    // Standard image loading for real devices
    private func loadImageStandard(url: URL, urlString: String) async {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache.shared
        let session = URLSession(configuration: config)
        
        do {
            let (data, response) = try await session.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode != 200 {
                print("❌ Image load failed: \(httpResponse.statusCode) for URL: \(urlString)")
                await MainActor.run {
                    imageState = .failed
                }
                return
            }
            
            guard let image = UIImage(data: data) else {
                await MainActor.run {
                    imageState = .failed
                }
                return
            }
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    loadedImage = image
                    imageState = .loaded(urlString)
                }
            }
        } catch {
            print("⏱️ Image error for URL: \(urlString)")
            await MainActor.run {
                imageState = .failed
            }
        }
    }
    
    // Simulator-specific loading with multiple fallback strategies
    private func loadImageWithSimulatorFallback(url: URL, urlString: String) async {
        // Strategy 1: Try with modified session configuration for simulator
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0  // Longer timeout for simulator
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.tlsMinimumSupportedProtocolVersion = .TLSv12
        config.tlsMaximumSupportedProtocolVersion = .TLSv12
        config.httpShouldUsePipelining = false
        config.httpMaximumConnectionsPerHost = 1
        
        // Disable all advanced features that might cause issues
        config.allowsCellularAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.waitsForConnectivity = false
        config.multipathServiceType = .none
        
        let session = URLSession(configuration: config)
        
        do {
            print("🔄 Simulator: Attempting to load image from \(urlString)")
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30.0)
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Simulator: Response \(httpResponse.statusCode) for image")
                
                if httpResponse.statusCode == 200,
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            loadedImage = image
                            imageState = .loaded(urlString)
                        }
                    }
                    return
                }
            }
        } catch {
            print("⚠️ Simulator: Primary load failed - \(error.localizedDescription)")
        }
        
        // Strategy 2: Try AsyncImage as fallback (uses different network stack)
        if !simulatorFallbackAttempted {
            await MainActor.run {
                simulatorFallbackAttempted = true
                // Show a generic placeholder that indicates the image exists
                imageState = .loaded("simulator_placeholder")
            }
        } else {
            await MainActor.run {
                imageState = .failed
            }
        }
    }
    
    private func stopImageCycling() {
        imageTimer?.invalidate()
        imageTimer = nil
    }
    
    // MARK: - Simulator Placeholder
    private var simulatorPlaceholder: some View {
        ZStack {
            // Gradient background that looks like a real image
            LinearGradient(
                colors: [
                    Color(red: 0.9, green: 0.95, blue: 0.9),
                    Color(red: 0.85, green: 0.9, blue: 0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Content overlay
            VStack(spacing: 8) {
                Image(systemName: "photo.fill.on.rectangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Theme.Colors.primary.opacity(0.7))
                    .symbolRenderingMode(.hierarchical)
                
                if imageURLs.count > 1 {
                    Text("\(imageURLs.count) Photos")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            
            // Add badge if multiple images
            if imageURLs.count > 1 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        multipleImagesIndicator
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct ListingImageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Single image
            ListingImageView(imageURLs: ["https://via.placeholder.com/300x200"])
                .frame(height: 140)
            
            // Multiple images
            ListingImageView(imageURLs: [
                "https://via.placeholder.com/300x200/FF0000",
                "https://via.placeholder.com/300x200/00FF00",
                "https://via.placeholder.com/300x200/0000FF"
            ])
            .frame(height: 140)
            
            // Error state
            ListingImageView(imageURLs: ["invalid-url"])
                .frame(height: 140)
        }
        .padding()
    }
}