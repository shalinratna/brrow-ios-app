//
//  SimpleImageView.swift
//  Brrow
//
//  Simple image view for production use
//

import SwiftUI
import Combine

class SimpleImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    private var cancellable: AnyCancellable?
    private let url: URL
    private static let imageCache = NSCache<NSURL, UIImage>()
    
    init(url: URL) {
        self.url = url
    }
    
    deinit {
        cancel()
    }
    
    func load() {
        // Check cache first
        if let cachedImage = Self.imageCache.object(forKey: url as NSURL) {
            self.image = cachedImage
            return
        }
        
        isLoading = true
        
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                self.isLoading = false
                if let image = $0 {
                    self.image = image
                    Self.imageCache.setObject(image, forKey: self.url as NSURL)
                }
            }
    }
    
    func cancel() {
        cancellable?.cancel()
    }
}

struct SimpleImageView: View {
    @StateObject private var loader: SimpleImageLoader
    let contentMode: ContentMode
    
    init(url: URL?, contentMode: ContentMode = .fill) {
        self.contentMode = contentMode
        _loader = StateObject(wrappedValue: SimpleImageLoader(url: url ?? URL(string: "https://brrowapp.com/assets/placeholder.jpg")!))
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if loader.isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.gray.opacity(0.3))
                    )
            }
        }
        .onAppear {
            loader.load()
        }
    }
}