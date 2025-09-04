//
//  EnhancedImageGallery.swift
//  Brrow
//
//  Improved image gallery that properly loads all images
//

import SwiftUI
import Combine

// MARK: - Image Cache Manager
class ImageGalleryCache {
    static let shared = ImageGalleryCache()
    private var cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 50
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
    }
    
    func image(for url: String) -> UIImage? {
        return cache.object(forKey: url as NSString)
    }
    
    func setImage(_ image: UIImage, for url: String) {
        cache.setObject(image, forKey: url as NSString, cost: image.jpegData(compressionQuality: 1.0)?.count ?? 0)
    }
}

// MARK: - Gallery Image Loader
class GalleryImageLoader: ObservableObject {
    @Published var images: [Int: UIImage] = [:]
    @Published var loadingStates: [Int: LoadingState] = [:]
    
    enum LoadingState {
        case idle
        case loading
        case loaded
        case failed
    }
    
    private var cancellables = Set<AnyCancellable>()
    private let imageURLs: [String]
    
    init(imageURLs: [String]) {
        self.imageURLs = imageURLs
        // Initialize all states
        for index in imageURLs.indices {
            loadingStates[index] = .idle
        }
    }
    
    func loadImage(at index: Int) {
        guard index < imageURLs.count else { return }
        
        let urlString = imageURLs[index]
        
        // Check cache first
        if let cachedImage = ImageGalleryCache.shared.image(for: urlString) {
            DispatchQueue.main.async {
                self.images[index] = cachedImage
                self.loadingStates[index] = .loaded
            }
            return
        }
        
        // Already loading or failed, don't retry
        if loadingStates[index] == .loading || loadingStates[index] == .failed {
            return
        }
        
        loadingStates[index] = .loading
        
        guard let url = URL(string: urlString) else {
            loadingStates[index] = .failed
            return
        }
        
        // Create custom session with better configuration
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache.shared
        
        let session = URLSession(configuration: config)
        
        session.dataTaskPublisher(for: url)
            .tryMap { data, response -> UIImage in
                guard let image = UIImage(data: data) else {
                    throw URLError(.cannotDecodeContentData)
                }
                return image
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        self?.loadingStates[index] = .failed
                    }
                },
                receiveValue: { [weak self] image in
                    self?.images[index] = image
                    self?.loadingStates[index] = .loaded
                    ImageGalleryCache.shared.setImage(image, for: urlString)
                }
            )
            .store(in: &cancellables)
    }
    
    func preloadAllImages() {
        for index in imageURLs.indices {
            loadImage(at: index)
        }
    }
}

// MARK: - Enhanced Image Gallery View
struct EnhancedImageGallery: View {
    let imageURLs: [String]
    @State private var selectedIndex = 0
    @StateObject private var imageLoader: GalleryImageLoader
    
    init(imageURLs: [String]) {
        self.imageURLs = imageURLs
        self._imageLoader = StateObject(wrappedValue: GalleryImageLoader(imageURLs: imageURLs))
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedIndex) {
                ForEach(imageURLs.indices, id: \.self) { index in
                    galleryImage(at: index)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            
            // Image counter overlay
            if imageURLs.count > 1 {
                imageCounterOverlay
            }
        }
        .onAppear {
            // Preload first image immediately
            imageLoader.loadImage(at: 0)
            // Preload next image
            if imageURLs.count > 1 {
                imageLoader.loadImage(at: 1)
            }
        }
        .onChange(of: selectedIndex) { newIndex in
            // Load current image if needed
            imageLoader.loadImage(at: newIndex)
            
            // Preload adjacent images
            if newIndex > 0 {
                imageLoader.loadImage(at: newIndex - 1)
            }
            if newIndex < imageURLs.count - 1 {
                imageLoader.loadImage(at: newIndex + 1)
            }
        }
    }
    
    @ViewBuilder
    private func galleryImage(at index: Int) -> some View {
        ZStack {
            if let image = imageLoader.images[index] {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                switch imageLoader.loadingStates[index] ?? .idle {
                case .idle, .loading:
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            VStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(1.2)
                                
                                Text("Loading image \(index + 1)...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                        .onAppear {
                            // Trigger load when this image appears
                            imageLoader.loadImage(at: index)
                        }
                    
                case .failed:
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray.opacity(0.5))
                                
                                Text("Failed to load")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Button("Retry") {
                                    imageLoader.loadingStates[index] = .idle
                                    imageLoader.loadImage(at: index)
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                            }
                        )
                    
                case .loaded:
                    EmptyView()
                }
            }
        }
    }
    
    private var imageCounterOverlay: some View {
        HStack {
            Image(systemName: "photo.fill")
            Text("\(selectedIndex + 1)/\(imageURLs.count)")
        }
        .font(.caption)
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.6))
        .cornerRadius(20)
        .padding()
    }
}

// MARK: - Full Screen Gallery
struct EnhancedFullScreenGallery: View {
    let imageURLs: [String]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    @StateObject private var imageLoader: GalleryImageLoader
    
    init(imageURLs: [String], selectedIndex: Binding<Int>) {
        self.imageURLs = imageURLs
        self._selectedIndex = selectedIndex
        self._imageLoader = StateObject(wrappedValue: GalleryImageLoader(imageURLs: imageURLs))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $selectedIndex) {
                ForEach(imageURLs.indices, id: \.self) { index in
                    ZoomableGalleryImage(
                        image: imageLoader.images[index],
                        loadingState: imageLoader.loadingStates[index] ?? .idle,
                        onRetry: {
                            imageLoader.loadingStates[index] = .idle
                            imageLoader.loadImage(at: index)
                        }
                    )
                    .tag(index)
                    .onAppear {
                        imageLoader.loadImage(at: index)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Top controls
            VStack {
                topControls
                Spacer()
                pageIndicator
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            // Preload current and adjacent images
            imageLoader.loadImage(at: selectedIndex)
            if selectedIndex > 0 {
                imageLoader.loadImage(at: selectedIndex - 1)
            }
            if selectedIndex < imageURLs.count - 1 {
                imageLoader.loadImage(at: selectedIndex + 1)
            }
        }
    }
    
    private var topControls: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("\(selectedIndex + 1) / \(imageURLs.count)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.5))
                .cornerRadius(15)
            
            Spacer()
            
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .padding(.top, 50)
    }
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(imageURLs.indices, id: \.self) { index in
                Circle()
                    .fill(index == selectedIndex ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: selectedIndex)
            }
        }
        .padding(.bottom, 40)
    }
}

// MARK: - Zoomable Gallery Image
struct ZoomableGalleryImage: View {
    let image: UIImage?
    let loadingState: GalleryImageLoader.LoadingState
    let onRetry: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(magnificationGesture)
                .simultaneousGesture(dragGesture)
                .onTapGesture(count: 2) {
                    withAnimation(.spring()) {
                        if scale > 1 {
                            scale = 1
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 2
                        }
                    }
                }
        } else {
            switch loadingState {
            case .idle, .loading:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
            case .failed:
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Failed to load image")
                        .foregroundColor(.white.opacity(0.7))
                    
                    Button("Retry") {
                        onRetry()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                
            case .loaded:
                EmptyView()
            }
        }
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale = min(max(scale * delta, 1), 4)
            }
            .onEnded { _ in
                lastScale = 1.0
                withAnimation(.spring()) {
                    if scale < 1 {
                        scale = 1
                        offset = .zero
                    }
                }
            }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if scale > 1 {
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }
}