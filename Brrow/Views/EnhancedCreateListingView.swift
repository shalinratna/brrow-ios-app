//
//  EnhancedCreateListingView.swift
//  Brrow
//
//  Enhanced listing creation view with intelligent preloading, progress indicators, and optimized UX
//

import SwiftUI
import PhotosUI
import UIKit

struct EnhancedCreateListingView: View {
    @StateObject private var viewModel = EnhancedCreateListingViewModel()
    @Environment(\.dismiss) private var dismiss

    // Animation states
    @State private var showProgressDetails = false
    @State private var progressAnimation = false

    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        imageSection
                        detailsSection
                        pricingSection
                        locationSection
                        submitSection
                    }
                    .padding()
                }
                .disabled(viewModel.isLoading)

                // Progress overlay
                if viewModel.isLoading || viewModel.isPreprocessing {
                    progressOverlay
                }
            }
        }
        .navigationTitle("Create Listing")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    if viewModel.isLoading {
                        viewModel.cancelUpload()
                    }
                    dismiss()
                }
                .foregroundColor(viewModel.isLoading ? .red : .primary)
            }
        }
        .alert("Success!", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your listing has been created successfully!")
        }
        .onChange(of: viewModel.selectedPhotos) { newPhotos in
            // Trigger haptic feedback when photos are selected
            LocalHapticManager.shared.impact(.light)

            // ⚡️⚡️⚡️ INSTAGRAM MODE: Start background upload IMMEDIATELY
            Task {
                await viewModel.handlePhotoSelection(newPhotos)
            }
        }
        .onDisappear {
            // ⚡️ Clean up orphaned uploads when view is dismissed
            viewModel.handleViewDismissal()
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create Your Listing")
                .font(.title2)
                .fontWeight(.bold)

            Text("Add photos and details to attract potential buyers or renters")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Performance indicators (development only)
            if viewModel.isPreprocessing {
                performanceIndicators
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Enhanced Image Section
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Photos")
                    .font(.headline)

                Spacer()

                // ⚡️ INSTAGRAM-STYLE: Show upload progress banner
                if viewModel.backgroundUploadActive {
                    uploadProgressBanner
                }
                else if viewModel.isPreprocessing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)

                        Text("Optimizing...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Photo picker and grid
            VStack(spacing: 12) {
                // Photo picker button
                PhotosPicker(
                    selection: $viewModel.selectedPhotos,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 120)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)

                                Text("Add Photos")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text("Up to 10 photos")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                }
                .disabled(viewModel.isLoading)

                // Selected images grid
                if !viewModel.selectedImages.isEmpty {
                    imageGrid
                }

                // Processing progress
                if viewModel.isPreprocessing && viewModel.processedImageCount > 0 {
                    processingProgress
                }
            }
        }
    }

    private var imageGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
            ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { index, image in
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        }

                    // ⚡️ INSTAGRAM-STYLE UPLOAD PROGRESS OVERLAY
                    if let tracker = getTrackerForImage(at: index) {
                        uploadProgressOverlay(for: tracker)
                    }
                    // Processing indicator (fallback)
                    else if viewModel.isPreprocessing {
                        VStack {
                            if index < viewModel.processedImageCount {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .background(Circle().fill(Color.white))
                            } else {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .background(Circle().fill(Color.white))
                            }
                        }
                        .padding(4)
                    }

                    // Remove button
                    if !viewModel.isLoading && !viewModel.backgroundUploadActive {
                        Button {
                            withAnimation(.spring()) {
                                viewModel.removeImage(at: index)
                                LocalHapticManager.shared.impact(.light)
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .background(Circle().fill(Color.white))
                        }
                        .padding(4)
                    }
                }
            }
        }
    }

    // ⚡️ INSTAGRAM-STYLE: Upload progress overlay for individual images
    @ViewBuilder
    private func uploadProgressOverlay(for tracker: UploadTracker) -> some View {
        ZStack {
            // Dark overlay while uploading
            if case .uploading = tracker.status {
                Color.black.opacity(0.4)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(spacing: 4) {
                switch tracker.status {
                case .pending:
                    Image(systemName: "clock.fill")
                        .foregroundColor(.yellow)
                        .background(Circle().fill(Color.white))
                        .font(.caption)

                case .uploading(let progress):
                    VStack(spacing: 2) {
                        ProgressView(value: progress)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(6)
                    .background(Color.black.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                case .completed:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .background(Circle().fill(Color.white))
                        .font(.title3)

                case .failed(let error):
                    VStack(spacing: 2) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Failed")
                            .font(.system(size: 8))
                            .foregroundColor(.red)
                    }
                    .padding(4)
                    .background(Circle().fill(Color.white))

                case .cancelled:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.orange)
                        .background(Circle().fill(Color.white))
                }
            }
            .padding(4)
        }
    }

    // Helper to get tracker for image at index
    private func getTrackerForImage(at index: Int) -> UploadTracker? {
        let trackers = Array(viewModel.uploadTrackers.values)
        guard index < trackers.count else { return nil }
        return trackers[index]
    }

    // ⚡️ INSTAGRAM-STYLE: Upload progress banner
    private var uploadProgressBanner: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.7)

            Text("Uploading \(viewModel.uploadedImageCount)/\(viewModel.totalImagesToUpload)")
                .font(.caption)
                .foregroundColor(.blue)
                .fontWeight(.medium)

            if viewModel.overallUploadProgress > 0 {
                Text("\(Int(viewModel.overallUploadProgress * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .clipShape(Capsule())
    }

    private var processingProgress: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Optimizing Images")
                    .font(.caption)
                    .fontWeight(.medium)

                Spacer()

                Text("\(viewModel.processedImageCount)/\(viewModel.selectedImages.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: viewModel.processingProgress)
                .tint(.blue)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)

            VStack(spacing: 12) {
                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("Title *")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("What are you listing?", text: $viewModel.title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(viewModel.isLoading)
                }

                // Description
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description *")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("Describe your item in detail", text: $viewModel.description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(4...8)
                        .disabled(viewModel.isLoading)
                }

                // Category
                VStack(alignment: .leading, spacing: 4) {
                    Text("Category *")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Menu {
                        ForEach(viewModel.categories, id: \.self) { category in
                            Button(category) {
                                viewModel.selectedCategory = category
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedCategory.isEmpty ? "Select Category" : viewModel.selectedCategory)
                                .foregroundColor(viewModel.selectedCategory.isEmpty ? .secondary : .primary)

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }

    // MARK: - Pricing Section
    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pricing")
                .font(.headline)

            VStack(spacing: 12) {
                // Free toggle
                Toggle("Free Item", isOn: $viewModel.isFree)
                    .disabled(viewModel.isLoading)

                // Price input
                if !viewModel.isFree {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Price *")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        TextField("Enter price", text: $viewModel.price)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .disabled(viewModel.isLoading)
                    }
                }
            }
        }
    }

    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location")
                .font(.headline)

            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Location *")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("Enter location", text: $viewModel.location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(viewModel.isLoading)
                }

                Button("Use Current Location") {
                    viewModel.requestLocationPermission()
                    LocalHapticManager.shared.impact(.medium)
                }
                .foregroundColor(.blue)
                .disabled(viewModel.isLoading)
            }
        }
    }

    // MARK: - Submit Section
    private var submitSection: some View {
        VStack(spacing: 16) {
            Button {
                viewModel.createListing()
                LocalHapticManager.shared.impact(.medium)
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    }

                    Text(viewModel.isLoading ? "Creating..." : "Create Listing")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canSubmit ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.canSubmit || viewModel.isLoading)

            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Progress Overlay
    private var progressOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Main progress card
                VStack(spacing: 16) {
                    // Operation title
                    Text(viewModel.currentOperation)
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    // Progress indicators
                    if viewModel.isPreprocessing {
                        preprocessingIndicator
                    } else if viewModel.isLoading {
                        uploadIndicator
                    }

                    // Cancel button
                    if viewModel.canCancelUpload {
                        Button("Cancel Upload") {
                            viewModel.cancelUpload()
                            LocalHapticManager.shared.impact(.heavy)
                        }
                        .foregroundColor(.red)
                        .padding(.top, 8)
                    }
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(radius: 10)

                // Performance details (expandable)
                if showProgressDetails {
                    performanceDetails
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Toggle details button
                Button {
                    withAnimation(.spring()) {
                        showProgressDetails.toggle()
                    }
                } label: {
                    Image(systemName: showProgressDetails ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
            .padding()
        }
    }

    private var preprocessingIndicator: some View {
        VStack(spacing: 12) {
            ProgressView(value: viewModel.processingProgress)
                .tint(.blue)

            Text("\(viewModel.processedImageCount) of \(viewModel.selectedImages.count) images optimized")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var uploadIndicator: some View {
        VStack(spacing: 12) {
            ProgressView(value: viewModel.uploadProgress)
                .tint(.green)

            HStack {
                Text("Upload Progress")
                    .font(.caption)

                Spacer()

                if viewModel.uploadSpeed > 0 {
                    Text("\(String(format: "%.0f", viewModel.uploadSpeed)) KB/s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var performanceIndicators: some View {
        VStack(spacing: 8) {
            HStack {
                Label("Performance Monitor", systemImage: "speedometer")
                    .font(.caption)
                    .fontWeight(.medium)

                Spacer()

                Button {
                    withAnimation(.spring()) {
                        showProgressDetails.toggle()
                    }
                } label: {
                    Image(systemName: showProgressDetails ? "eye.slash" : "eye")
                        .font(.caption)
                }
            }

            if showProgressDetails {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                    GridRow {
                        Text("Images:")
                        Text("\(viewModel.processedImageCount)/\(viewModel.selectedImages.count)")
                    }

                    GridRow {
                        Text("Progress:")
                        Text("\(Int(viewModel.processingProgress * 100))%")
                    }

                    if viewModel.uploadSpeed > 0 {
                        GridRow {
                            Text("Speed:")
                            Text("\(String(format: "%.0f", viewModel.uploadSpeed)) KB/s")
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }

    private var performanceDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Performance Details")
                .font(.caption)
                .fontWeight(.medium)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                GridRow {
                    Text("Processed:")
                    Text("\(viewModel.processedImageCount) images")
                }

                GridRow {
                    Text("Upload Speed:")
                    Text("\(String(format: "%.1f", viewModel.uploadSpeed)) KB/s")
                }

                GridRow {
                    Text("Progress:")
                    Text("\(Int(viewModel.uploadProgress * 100))%")
                }

                if let batchId = viewModel.currentBatchId {
                    GridRow {
                        Text("Batch ID:")
                        Text(String(batchId.suffix(8)))
                    }
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

// MARK: - Haptic Manager
class LocalHapticManager {
    static let shared = LocalHapticManager()
    private init() {}

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

#Preview {
    EnhancedCreateListingView()
}