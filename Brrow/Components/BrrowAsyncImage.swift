import SwiftUI

/// Smart AsyncImage wrapper that automatically handles Railway URL construction
struct BrrowAsyncImage<Content: View, Placeholder: View>: View {
    let urlString: String?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    init(
        url urlString: String?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.urlString = urlString
        self.content = content
        self.placeholder = placeholder
    }

    // Computed property to construct proper URLs
    private var properURL: String? {
        guard let urlString = urlString, !urlString.isEmpty, urlString != "null" else {
            print("🖼️ BrrowAsyncImage: Empty/null URL input")
            return nil
        }

        print("🖼️ BrrowAsyncImage: Input URL = '\(urlString)'")

        // If already a full URL, return as-is
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            print("🖼️ BrrowAsyncImage: Already full URL, returning as-is")
            return urlString
        }

        let finalURL: String

        // If it's a relative path, construct full Railway URL
        if urlString.hasPrefix("/") {
            // Absolute path relative to domain root (e.g., "/uploads/...", "/api/images/...")
            finalURL = "https://brrow-backend-nodejs-production.up.railway.app\(urlString)"
            print("🖼️ BrrowAsyncImage: Converted absolute path: '\(urlString)' → '\(finalURL)'")
        } else if urlString.contains("/") || urlString.contains(".") {
            // Relative path or filename (e.g., "uploads/...", "image.jpg")
            finalURL = "https://brrow-backend-nodejs-production.up.railway.app/\(urlString)"
            print("🖼️ BrrowAsyncImage: Converted relative path: '\(urlString)' → '\(finalURL)'")
        } else {
            finalURL = urlString
            print("🖼️ BrrowAsyncImage: No conversion needed: '\(urlString)'")
        }

        return finalURL
    }

    var body: some View {
        // Use CachedAsyncImage which has comprehensive URL handling
        CachedAsyncImage(url: properURL, content: content, placeholder: placeholder)
    }
}

// MARK: - Convenience Initializers
extension BrrowAsyncImage where Content == AnyView, Placeholder == AnyView {
    init(url urlString: String?, placeholder: Image = Image(systemName: "photo")) {
        self.init(
            url: urlString,
            content: { image in
                AnyView(
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                )
            },
            placeholder: {
                AnyView(
                    ZStack {
                        Color.gray.opacity(0.1)
                        placeholder
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.3))
                    }
                )
            }
        )
    }
}