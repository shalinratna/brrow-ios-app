//
//  CircularImageCropper.swift
//  Brrow
//
//  Instagram-style circular profile picture cropper - Full screen edition
//

import SwiftUI
import UIKit

struct CircularImageCropper: View {
    let image: UIImage
    @Binding var cropOffset: CGSize
    @Binding var cropScale: CGFloat
    let cropSize: CGFloat
    let onCropComplete: (UIImage, CropData) -> Void
    let onCancel: () -> Void

    @State private var currentOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var dragOffset: CGSize = .zero
    @State private var magnificationAmount: CGFloat = 1.0

    // Calculate optimal initial scale
    @State private var initialScale: CGFloat = 1.0

    init(
        image: UIImage,
        cropOffset: Binding<CGSize> = .constant(.zero),
        cropScale: Binding<CGFloat> = .constant(1.0),
        cropSize: CGFloat = 280, // Larger default for better UX
        onCropComplete: @escaping (UIImage, CropData) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.image = image
        self._cropOffset = cropOffset
        self._cropScale = cropScale
        self.cropSize = cropSize
        self.onCropComplete = onCropComplete
        self.onCancel = onCancel

        // Initialize with provided values or defaults
        self._currentOffset = State(initialValue: cropOffset.wrappedValue)
        self._currentScale = State(initialValue: cropScale.wrappedValue == 1.0 ? Self.calculateInitialScale(for: image, cropSize: cropSize) : cropScale.wrappedValue)
        self._initialScale = State(initialValue: Self.calculateInitialScale(for: image, cropSize: cropSize))
    }

    static func calculateInitialScale(for image: UIImage, cropSize: CGFloat) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let imageSize = image.size

        // Calculate scale to make sure the crop circle is filled
        let minDimension = min(imageSize.width, imageSize.height)
        let scale = cropSize / minDimension

        return max(scale, 1.0)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full screen black background
                Color.black
                    .ignoresSafeArea()

                // Full screen image container (draggable and zoomable)
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(currentScale * magnificationAmount)
                    .offset(
                        x: currentOffset.width + dragOffset.width,
                        y: currentOffset.height + dragOffset.height
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .gesture(
                        SimultaneousGesture(
                            // Drag gesture - works anywhere on screen
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation
                                }
                                .onEnded { value in
                                    currentOffset.width += value.translation.width
                                    currentOffset.height += value.translation.height
                                    dragOffset = .zero
                                },

                            // Pinch to zoom - works anywhere
                            MagnificationGesture()
                                .onChanged { value in
                                    magnificationAmount = value
                                }
                                .onEnded { value in
                                    currentScale *= value
                                    currentScale = max(0.5, min(currentScale, 5.0)) // Wider range
                                    magnificationAmount = 1.0
                                }
                        )
                    )

                // Dark overlay with circular cutout (non-interactive)
                CircularCropOverlay(cropSize: cropSize)
                    .allowsHitTesting(false)

                // Circular border guide
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: cropSize, height: cropSize)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .allowsHitTesting(false)

                // Top bar with Cancel button
                VStack {
                    HStack {
                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                        }

                        Spacer()
                    }
                    .padding(.top, 50)
                    .padding(.horizontal, 20)

                    Spacer()
                }
                .allowsHitTesting(true)

                // Bottom bar with zoom slider and Done button
                VStack {
                    Spacer()

                    VStack(spacing: 20) {
                        // Zoom slider - compact and Instagram-like
                        HStack(spacing: 15) {
                            Image(systemName: "minus.magnifyingglass")
                                .foregroundColor(.white)
                                .font(.system(size: 20))

                            Slider(value: $currentScale, in: (initialScale * 0.5)...(initialScale * 3.0))
                                .accentColor(.white)
                                .frame(maxWidth: 250)

                            Image(systemName: "plus.magnifyingglass")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(30)

                        // Done button
                        Button(action: performCrop) {
                            Text("Done")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 30)
                    }
                    .padding(.bottom, 50)
                }
                .allowsHitTesting(true)
            }
        }
    }

    private func performCrop() {
        let cropData = CropData(
            offset: currentOffset,
            scale: currentScale,
            cropSize: cropSize
        )

        // Update bindings
        cropOffset = currentOffset
        cropScale = currentScale

        // Create accurately cropped circular image
        let croppedImage = cropImageToCircle(
            image: image,
            cropData: cropData,
            screenSize: UIScreen.main.bounds.size
        )

        print("✅ Crop completed - offset: \(currentOffset), scale: \(currentScale)")
        onCropComplete(croppedImage, cropData)
    }

    private func cropImageToCircle(image: UIImage, cropData: CropData, screenSize: CGSize) -> UIImage {
        // Use high resolution for quality
        let outputSize = CGSize(width: 600, height: 600)

        let renderer = UIGraphicsImageRenderer(size: outputSize)

        return renderer.image { context in
            // Create circular clipping path
            let clipPath = UIBezierPath(ovalIn: CGRect(origin: .zero, size: outputSize))
            clipPath.addClip()

            // Calculate the image's display size on screen
            let imageAspect = image.size.width / image.size.height
            var displaySize: CGSize

            if imageAspect > 1 {
                // Landscape: fit to height
                displaySize = CGSize(width: screenSize.height * imageAspect, height: screenSize.height)
            } else {
                // Portrait or square: fit to width
                displaySize = CGSize(width: screenSize.width, height: screenSize.width / imageAspect)
            }

            // Apply scale
            let scaledSize = CGSize(
                width: displaySize.width * cropData.scale,
                height: displaySize.height * cropData.scale
            )

            // Calculate position in screen coordinates
            let screenCenterX = screenSize.width / 2
            let screenCenterY = screenSize.height / 2

            // Image position relative to screen center
            let imageScreenX = screenCenterX - (scaledSize.width / 2) + cropData.offset.width
            let imageScreenY = screenCenterY - (scaledSize.height / 2) + cropData.offset.height

            // Crop circle position on screen (always centered)
            let cropCircleCenterX = screenSize.width / 2
            let cropCircleCenterY = screenSize.height / 2

            // Calculate how much of the image to take based on crop circle position
            let cropCircleLeft = cropCircleCenterX - (cropData.cropSize / 2)
            let cropCircleTop = cropCircleCenterY - (cropData.cropSize / 2)

            // Relative position of crop area to the image
            let relativeX = cropCircleLeft - imageScreenX
            let relativeY = cropCircleTop - imageScreenY

            // Scale factor: crop circle size to output size
            let scaleFactor = outputSize.width / cropData.cropSize

            // Final drawing position in output coordinates
            let drawX = -relativeX * scaleFactor
            let drawY = -relativeY * scaleFactor
            let drawWidth = scaledSize.width * scaleFactor
            let drawHeight = scaledSize.height * scaleFactor

            let drawRect = CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight)

            // Draw the image
            image.draw(in: drawRect)
        }
    }
}

// MARK: - Circular Crop Overlay
struct CircularCropOverlay: View {
    let cropSize: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full screen dark overlay
                Color.black.opacity(0.7)
                    .ignoresSafeArea()

                // Circular cutout in the center
                Circle()
                    .frame(width: cropSize, height: cropSize)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
        }
    }
}

// MARK: - Crop Data Model
struct CropData: Codable {
    let offset: CGSize
    let scale: CGFloat
    let cropSize: CGFloat

    var offsetX: Double { offset.width }
    var offsetY: Double { offset.height }
}

// MARK: - CGSize Codable Extension
extension CGSize: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        self.init(width: width, height: height)
    }

    enum CodingKeys: String, CodingKey {
        case width, height
    }
}

// MARK: - Preview
#if DEBUG
struct CircularImageCropper_Previews: PreviewProvider {
    static var previews: some View {
        if let sampleImage = UIImage(systemName: "person.fill") {
            CircularImageCropper(
                image: sampleImage,
                onCropComplete: { _, _ in },
                onCancel: { }
            )
        }
    }
}
#endif
