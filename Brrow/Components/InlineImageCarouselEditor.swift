//
//  InlineImageCarouselEditor.swift
//  Brrow
//
//  Created by Claude Code on 11/13/25.
//

import SwiftUI
import PhotosUI

/// Inline editor for image carousel
struct InlineImageCarouselEditor: View {
    @ObservedObject var viewModel: InlineEditViewModel

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var images: [ListingImage] = []

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Manage photos (up to 5)")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.secondaryText)

            // Current images grid
            if !images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(Array(images.enumerated()), id: \.element.id) { index, image in
                            ZStack(alignment: .topTrailing) {
                                // Image
                                BrrowAsyncImage(
                                    url: image.imageUrl
                                )
                                .frame(width: 150, height: 150)
                                .cornerRadius(Theme.CornerRadius.md)
                                .clipped()

                                // Delete button
                                Button(action: {
                                    withAnimation {
                                        images.remove(at: index)
                                        viewModel.updateBuffer(key: "images", value: images)
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                                .padding(8)

                                // Order indicator
                                Text("#\(index + 1)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.black.opacity(0.6)))
                                    .padding(8)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                            }
                        }
                    }
                }
                .frame(height: 150)
            }

            // Add photos button
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 5 - images.count,
                matching: .images
            ) {
                HStack {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 20))

                    Text(images.isEmpty ? "Add Photos" : "Add More Photos")
                        .font(.system(size: 16, weight: .semibold))

                    Spacer()

                    Text("\(images.count)/5")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .foregroundColor(images.count >= 5 ? Theme.Colors.secondaryText : Theme.Colors.primary)
                .padding(Theme.Spacing.md)
                .background(
                    images.count >= 5 ?
                    Theme.Colors.secondaryBackground :
                    Theme.Colors.primary.opacity(0.1)
                )
                .cornerRadius(Theme.CornerRadius.md)
            }
            .disabled(images.count >= 5)
            .onChange(of: selectedItems) { newItems in
                Task {
                    // Handle photo selection
                    // Note: In production, this would upload photos and add them to images array
                    print("Selected \(newItems.count) photos for upload")
                }
            }

            if images.isEmpty {
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.Colors.secondaryText)

                    Text("No photos added yet")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.Colors.text)

                    Text("Add photos to make your listing more attractive")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.xl)
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(Theme.CornerRadius.md)
            }
        }
        .onAppear {
            images = (viewModel.editBuffer["images"] as? [ListingImage]) ?? viewModel.listing.images
        }
    }
}
