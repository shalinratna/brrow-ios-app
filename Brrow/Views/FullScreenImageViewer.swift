//
//  FullScreenImageViewer.swift
//  Brrow
//
//  Full-screen image viewer with pinch-to-zoom, swipe-to-dismiss, and share
//

import SwiftUI

struct FullScreenImageViewer: View {
    let imageURL: String?
    let image: UIImage?
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var showControls = true
    @State private var loadedImage: UIImage?
    @State private var isLoading = true

    init(imageURL: String) {
        self.imageURL = imageURL
        self.image = nil
    }

    init(image: UIImage) {
        self.imageURL = nil
        self.image = image
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else if let displayImage = loadedImage {
                imageContent(displayImage)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                    Text("Failed to load image")
                        .foregroundColor(.white)
                }
            }

            // Controls overlay
            if showControls {
                VStack {
                    // Top bar
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }

                        Spacer()

                        if let displayImage = loadedImage {
                            Menu {
                                Button(action: { shareImage(displayImage) }) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }

                                Button(action: { saveImage(displayImage) }) {
                                    Label("Save to Photos", systemImage: "square.and.arrow.down")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .statusBar(hidden: !showControls)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showControls.toggle()
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func imageContent(_ displayImage: UIImage) -> some View {
        Image(uiImage: displayImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(scale)
            .offset(x: offset.width + dragOffset.width, y: offset.height + dragOffset.height)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let delta = value / lastScale
                        lastScale = value
                        scale = min(max(scale * delta, 1.0), 5.0)
                    }
                    .onEnded { _ in
                        lastScale = 1.0
                        if scale < 1.0 {
                            withAnimation(.spring()) {
                                scale = 1.0
                                offset = .zero
                            }
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        if scale > 1.0 {
                            // Pan when zoomed in
                            dragOffset = value.translation
                        } else {
                            // Swipe to dismiss when not zoomed
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        if scale > 1.0 {
                            // Update pan offset
                            offset.width += dragOffset.width
                            offset.height += dragOffset.height
                            dragOffset = .zero

                            // Limit offset to prevent panning too far
                            limitOffset()
                        } else {
                            // Check if swipe is enough to dismiss
                            if abs(dragOffset.height) > 100 {
                                dismiss()
                            } else {
                                withAnimation(.spring()) {
                                    dragOffset = .zero
                                }
                            }
                        }
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        withAnimation(.spring()) {
                            if scale > 1.0 {
                                scale = 1.0
                                offset = .zero
                            } else {
                                scale = 2.0
                            }
                        }
                    }
            )
    }

    private func loadImage() {
        if let image = image {
            // Use provided UIImage
            loadedImage = image
            isLoading = false
        } else if let imageURL = imageURL {
            // Load from URL
            Task {
                do {
                    guard let url = URL(string: imageURL) else {
                        await MainActor.run {
                            isLoading = false
                        }
                        return
                    }

                    let (data, _) = try await URLSession.shared.data(from: url)

                    if let downloadedImage = UIImage(data: data) {
                        await MainActor.run {
                            loadedImage = downloadedImage
                            isLoading = false
                        }
                    } else {
                        await MainActor.run {
                            isLoading = false
                        }
                    }
                } catch {
                    print("Error loading image: \(error)")
                    await MainActor.run {
                        isLoading = false
                    }
                }
            }
        } else {
            isLoading = false
        }
    }

    private func limitOffset() {
        // Limit offset based on scale
        let maxOffset: CGFloat = 100 * (scale - 1)
        offset.width = min(max(offset.width, -maxOffset), maxOffset)
        offset.height = min(max(offset.height, -maxOffset), maxOffset)
    }

    private func shareImage(_ image: UIImage) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }

        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)

        // For iPad
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = window
            popoverController.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        rootViewController.present(activityVC, animated: true)
    }

    private func saveImage(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        // Show success feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

struct FullScreenImageViewer_Previews: PreviewProvider {
    static var previews: some View {
        FullScreenImageViewer(image: UIImage(systemName: "photo")!)
    }
}
