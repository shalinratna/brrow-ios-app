//
//  CircularImageCropper.swift
//  Brrow
//
//  Instagram-style circular profile picture cropper
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

    init(
        image: UIImage,
        cropOffset: Binding<CGSize> = .constant(.zero),
        cropScale: Binding<CGFloat> = .constant(1.0),
        cropSize: CGFloat = 200,
        onCropComplete: @escaping (UIImage, CropData) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.image = image
        self._cropOffset = cropOffset
        self._cropScale = cropScale
        self.cropSize = cropSize
        self.onCropComplete = onCropComplete
        self.onCancel = onCancel

        // Initialize with provided values
        self._currentOffset = State(initialValue: cropOffset.wrappedValue)
        self._currentScale = State(initialValue: cropScale.wrappedValue)
    }

    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea(.all)
                .onAppear {
                    print("🖼️ CircularImageCropper: Body appeared with image size: \(image.size)")
                    print("🖼️ CircularImageCropper: Screen size: \(UIScreen.main.bounds.size)")
                }

            GeometryReader { geometry in

                // Image with crop controls
                VStack {
                    Spacer()

                    // Crop area
                    ZStack {
                        // The image
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.width)
                            .scaleEffect(currentScale * magnificationAmount)
                            .offset(
                                x: currentOffset.width + dragOffset.width,
                                y: currentOffset.height + dragOffset.height
                            )
                            .clipped()

                        // Dark overlay with circular cutout
                        CircularCropOverlay(cropSize: cropSize)

                        // Circular border
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: cropSize, height: cropSize)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .clipped()
                    .gesture(
                        SimultaneousGesture(
                            // Drag gesture
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation
                                }
                                .onEnded { value in
                                    currentOffset.width += value.translation.width
                                    currentOffset.height += value.translation.height
                                    dragOffset = .zero
                                },

                            // Magnification gesture
                            MagnificationGesture()
                                .onChanged { value in
                                    magnificationAmount = value
                                }
                                .onEnded { value in
                                    currentScale *= value
                                    currentScale = max(0.5, min(currentScale, 3.0)) // Limit scale
                                    magnificationAmount = 1.0
                                }
                        )
                    )

                    Spacer()

                    // Scale slider
                    VStack(spacing: 20) {
                        Text("Zoom")
                            .foregroundColor(.white)
                            .font(.headline)

                        HStack {
                            Image(systemName: "minus")
                                .foregroundColor(.white)

                            Slider(value: $currentScale, in: 0.5...3.0, step: 0.1)
                                .accentColor(.white)

                            Image(systemName: "plus")
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                    }

                    Spacer()

                    // Action buttons
                    HStack(spacing: 40) {
                        Button("Cancel") {
                            onCancel()
                        }
                        .font(.title2)
                        .foregroundColor(.white)

                        Button("Done") {
                            performCrop()
                        }
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(25)
                    }
                    .padding(.bottom, 40)
                }
                .onAppear {
                    print("🖼️ CircularImageCropper: GeometryReader size: \(geometry.size)")
                }
            }
        }
        .onAppear {
            // Auto-fit image to crop circle initially
            autoFitImage()
        }
    }

    private func autoFitImage() {
        // Calculate proper scale to ensure image covers the crop circle
        let screenWidth = UIScreen.main.bounds.width
        let imageSize = image.size

        // Scale to ensure image covers the full crop circle
        let scaleX = cropSize / imageSize.width * screenWidth / cropSize
        let scaleY = cropSize / imageSize.height * screenWidth / cropSize

        // Use the larger scale to ensure the crop circle is fully covered
        currentScale = max(scaleX, scaleY)

        // Ensure reasonable bounds
        currentScale = max(1.0, min(currentScale, 3.0))

        print("🖼️ CircularImageCropper: Auto-fit scale set to \(currentScale)")
        print("🖼️ CircularImageCropper: Image size: \(imageSize), crop size: \(cropSize)")
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

        // Create cropped image
        let croppedImage = cropImageToCircle(
            image: image,
            cropData: cropData,
            canvasSize: UIScreen.main.bounds.width
        )

        onCropComplete(croppedImage, cropData)
    }

    private func cropImageToCircle(image: UIImage, cropData: CropData, canvasSize: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cropData.cropSize, height: cropData.cropSize))

        return renderer.image { context in
            // Create circular clipping path
            let clipPath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: cropData.cropSize, height: cropData.cropSize))
            clipPath.addClip()

            // Calculate image position and size
            let scaledImageSize = CGSize(
                width: canvasSize * cropData.scale,
                height: canvasSize * cropData.scale
            )

            let imageOrigin = CGPoint(
                x: (cropData.cropSize - scaledImageSize.width) / 2 + cropData.offset.width,
                y: (cropData.cropSize - scaledImageSize.height) / 2 + cropData.offset.height
            )

            let imageRect = CGRect(origin: imageOrigin, size: scaledImageSize)

            // Draw the image
            image.draw(in: imageRect)
        }
    }
}

// MARK: - Circular Crop Overlay
struct CircularCropOverlay: View {
    let cropSize: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark overlay
                Color.black.opacity(0.6)

                // Circular cutout
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