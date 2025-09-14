//
//  OptimizedImageLoader.swift
//  Brrow
//
//  Optimized image loader that ensures proper loading of multiple images
//

import SwiftUI
import Combine
import Foundation

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    private var task: URLSessionDataTask?
    private var url: URL
    private static let cache = NSCache<NSURL, UIImage>()
    
    init(url: URL) {
        self.url = url
    }
    
    deinit {
        cancel()
    }
    
    func load() {
        // Check cache first
        if let cachedImage = Self.cache.object(forKey: url as NSURL) {
            self.image = cachedImage
            return
        }
        
        isLoading = true
        
        // Log the URL being loaded for debugging
        print("🔄 Loading image from: \(url.absoluteString)")
        
        // Create a simple URLSession with default configuration
        let session = URLSession.shared
        
        // Create request with basic settings
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        
        // Use data task to handle redirects properly
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("❌ Image load error: \(error.localizedDescription) for URL: \(self.url.absoluteString)")
                    // Try to handle HTTP->HTTPS conversion
                    let nsError = error as NSError
                    if nsError.code == -1022 || nsError.code == -1016 {
                        // Try with HTTPS if not already
                        if var components = URLComponents(url: self.url, resolvingAgainstBaseURL: false) {
                            components.scheme = "https"
                            if let httpsURL = components.url, httpsURL != self.url {
                                print("🔄 Retrying with HTTPS: \(httpsURL.absoluteString)")
                                self.url = httpsURL
                                self.load()
                                return
                            }
                        }
                    }
                    return
                }
                
                guard let data = data else {
                    print("❌ No data received for URL: \(self.url.absoluteString)")
                    return
                }
                
                guard let image = UIImage(data: data) else {
                    print("❌ Could not create image from data for URL: \(self.url.absoluteString)")
                    return
                }
                
                print("✅ Successfully loaded image from: \(self.url.absoluteString)")
                
                self.image = image
                Self.cache.setObject(image, forKey: self.url as NSURL)
            }
        }
        
        task.resume()
    }
    
    func cancel() {
        task?.cancel()
    }
}

struct OptimizedImageView: View {
    @StateObject private var loader: ImageLoader
    let contentMode: ContentMode
    
    init(url: URL?, contentMode: ContentMode = .fill) {
        self.contentMode = contentMode
        _loader = StateObject(wrappedValue: ImageLoader(url: url ?? URL(string: "https://via.placeholder.com/400")!))
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if loader.isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.4))
                    )
            }
        }
        .onAppear {
            loader.load()
        }
    }
}

// Enhanced gallery view with proper image loading
struct EnhancedImageGalleryView: View {
    let images: [String]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            TabView(selection: $selectedIndex) {
                ForEach(images.indices, id: \.self) { index in
                    ZoomableImageView(imageURL: images[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            VStack {
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
                    
                    Text("\(selectedIndex + 1) / \(images.count)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(15)
                    
                    Spacer()
                    
                    Button(action: { shareImage() }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 50)
                
                Spacer()
                
                HStack(spacing: 8) {
                    ForEach(images.indices, id: \.self) { index in
                        Circle()
                            .fill(index == selectedIndex ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: selectedIndex)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .statusBar(hidden: true)
    }
    
    private func shareImage() {
        guard selectedIndex < images.count,
              let url = URL(string: images[selectedIndex]) else { return }
        
        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }
}

struct ZoomableImageView: View {
    let imageURL: String
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        CachedAsyncImage(url: imageURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
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
                )
                .simultaneousGesture(
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
                )
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
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                )
        }
    }
}