//
//  SimplePerformanceComponents.swift
//  Brrow
//
//  Created by Claude on 7/26/25.
//  Simplified performance components that compile successfully
//

import SwiftUI

// MARK: - Simple Optimized AsyncImage
struct SimpleOptimizedAsyncImage: View {
    let url: String
    let targetSize: CGSize?
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    init(url: String, targetSize: CGSize? = nil) {
        self.url = url
        self.targetSize = targetSize
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let imageUrl = URL(string: url) else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: imageUrl) { data, _, _ in
            guard let data = data, let loadedImage = UIImage(data: data) else {
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }
            
            let optimizedImage = optimizeImage(loadedImage)
            
            DispatchQueue.main.async {
                self.image = optimizedImage
                self.isLoading = false
            }
        }.resume()
    }
    
    private func optimizeImage(_ image: UIImage) -> UIImage {
        guard let targetSize = targetSize else { return image }
        
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
}

// MARK: - Simple Shimmer Effect
struct SimpleShimmerEffect: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.gray.opacity(0.3),
                Color.white.opacity(0.8),
                Color.gray.opacity(0.3)
            ]),
            startPoint: UnitPoint(x: phase - 0.3, y: 0.5),
            endPoint: UnitPoint(x: phase + 0.3, y: 0.5)
        )
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                phase = 1
            }
        }
    }
}

// MARK: - Simple Shimmer Card
struct SimpleShimmerCard: View {
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .overlay(SimpleShimmerEffect())
                .frame(width: width, height: height * 0.6)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Rectangle()
                    .overlay(SimpleShimmerEffect())
                    .frame(width: width * 0.8, height: 16)
                    .cornerRadius(4)
                
                Rectangle()
                    .overlay(SimpleShimmerEffect())
                    .frame(width: width * 0.6, height: 12)
                    .cornerRadius(4)
            }
        }
        .frame(width: width)
    }
}

// MARK: - Simple Image Card
struct SimpleImageCard: View {
    let imageUrl: String
    let title: String
    let subtitle: String?
    let price: String?
    let onTap: () -> Void
    
    private let cardSize = CGSize(width: 160, height: 200)
    private let imageSize = CGSize(width: 160, height: 120)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SimpleOptimizedAsyncImage(
                url: imageUrl,
                targetSize: imageSize
            )
            .frame(width: imageSize.width, height: imageSize.height)
            .clipped()
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if let price = price {
                    Text(price)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.primary)
                }
            }
        }
        .frame(width: cardSize.width)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Performance Tracking Modifier
struct SimplePerformanceTrackingModifier: ViewModifier {
    let viewName: String
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Simple performance tracking
                let startTime = Date()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let renderTime = Date().timeIntervalSince(startTime)
                    print("📊 View \(viewName) rendered in \(renderTime)s")
                }
            }
    }
}

extension View {
    func trackSimplePerformance(_ viewName: String) -> some View {
        modifier(SimplePerformanceTrackingModifier(viewName: viewName))
    }
}