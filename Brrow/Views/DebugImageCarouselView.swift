//
//  DebugImageCarouselView.swift
//  Brrow
//
//  Debug view to test image carousel behavior
//

import SwiftUI

struct DebugImageCarouselView: View {
    let listing: Listing
    @State private var selectedImageIndex = 0
    @State private var imageLoadStates: [Int: String] = [:]
    @State private var manualTestResult: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Debug info
                VStack(alignment: .leading, spacing: 8) {
                    Text("🔴 DEBUG IMAGE CAROUSEL")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Group {
                        Text("Listing ID: \(listing.listingId)")
                            .font(.caption)
                        Text("Total images: \(listing.images.count)")
                            .font(.subheadline)
                            .foregroundColor(listing.images.isEmpty ? .red : .green)
                        Text("Selected index: \(selectedImageIndex)")
                            .font(.subheadline)
                    }
                    
                    Divider()
                    
                    Text("Image URLs:")
                        .font(.caption.bold())
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(0..<listing.images.count, id: \.self) { index in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("[\(index)]")
                                        .foregroundColor(index == selectedImageIndex ? .red : .blue)
                                        .font(.caption.bold())
                                    if let state = imageLoadStates[index] {
                                        Text(state)
                                            .font(.caption2)
                                            .foregroundColor(state.contains("✅") ? .green : .orange)
                                    }
                                }
                                Text(listing.imageUrls[index])
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    
                    if !manualTestResult.isEmpty {
                        Divider()
                        Text("Manual Test Result:")
                            .font(.caption.bold())
                        Text(manualTestResult)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
                // Image carousel
                if !listing.images.isEmpty {
                    Text("TabView Test:")
                        .font(.headline)
                    
                    TabView(selection: $selectedImageIndex) {
                        ForEach(0..<listing.images.count, id: \.self) { index in
                            VStack {
                                Text("Image \(index + 1) of \(listing.images.count)")
                                    .font(.caption)
                                    .padding(.bottom, 5)
                                
                                BrrowAsyncImage(url: listing.imageUrls[index])
                                    .frame(height: 200)
                                    .cornerRadius(10)
                                    .onAppear {
                                        print("🎨 TabView: Image \(index) appeared")
                                        imageLoadStates[index] = "⏳ Loading..."
                                    }
                                    .overlay(
                                        // Index overlay
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Text("\(index + 1)")
                                                    .font(.title.bold())
                                                    .foregroundColor(.white)
                                                    .padding(10)
                                                    .background(Circle().fill(Color.black.opacity(0.7)))
                                                    .padding(.trailing, 10)
                                                    .padding(.top, 10)
                                            }
                                            Spacer()
                                        }
                                    )
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .frame(height: 250)
                
                // Manual navigation buttons
                HStack(spacing: 20) {
                    Button("Previous") {
                        withAnimation {
                            selectedImageIndex = max(0, selectedImageIndex - 1)
                        }
                    }
                    .disabled(selectedImageIndex == 0)
                    
                    Button("Next") {
                        withAnimation {
                            selectedImageIndex = min(listing.images.count - 1, selectedImageIndex + 1)
                        }
                    }
                    .disabled(selectedImageIndex == listing.images.count - 1)
                }
                .padding()
                
                    // Image indicators
                    HStack(spacing: 8) {
                        ForEach(0..<listing.images.count, id: \.self) { index in
                            Circle()
                                .fill(selectedImageIndex == index ? Color.blue : Color.gray)
                                .frame(width: 10, height: 10)
                                .onTapGesture {
                                    withAnimation {
                                        selectedImageIndex = index
                                    }
                                }
                        }
                    }
                    
                    Divider()
                    
                    // Direct AsyncImage Test
                    Text("Direct AsyncImage Test (First Image):")
                        .font(.headline)
                        .padding(.top)
                    
                    if let firstURL = listing.imageUrls.first,
                       let url = URL(string: firstURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 150)
                                    .onAppear {
                                        print("🔄 Direct AsyncImage: Loading...")
                                        manualTestResult = "Loading direct image..."
                                    }
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 150)
                                    .cornerRadius(10)
                                    .onAppear {
                                        print("✅ Direct AsyncImage: Success!")
                                        manualTestResult = "✅ Direct load successful"
                                        imageLoadStates[0] = "✅ Loaded"
                                    }
                            case .failure(let error):
                                VStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.red)
                                    Text("Failed: \(error.localizedDescription)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .frame(height: 150)
                                .onAppear {
                                    print("❌ Direct AsyncImage: Failed - \(error)")
                                    manualTestResult = "❌ Failed: \(error.localizedDescription)"
                                }
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    
                    // Manual Load Test Button
                    Button(action: testManualLoad) {
                        Text("Test Manual Cache Load")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                    
                } else {
                    Text("No images available")
                        .foregroundColor(.red)
                        .font(.headline)
                        .frame(height: 200)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Image Debug")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("🔍 DebugImageCarousel opened")
            print("   Listing ID: \(listing.listingId)")
            print("   Total images: \(listing.images.count)")
            listing.images.enumerated().forEach { index, url in
                print("   Image \(index): \(url)")
            }
        }
    }
    
    private func testManualLoad() {
        guard let firstURL = listing.imageUrls.first else {
            manualTestResult = "❌ No images to test"
            return
        }
        
        print("🧪 Testing manual cache load for: \(firstURL)")
        manualTestResult = "Testing manual load..."
        
        ImageCacheManager.shared.loadImage(from: firstURL) { image in
            DispatchQueue.main.async {
                if let image = image {
                    print("✅ Manual cache load successful")
                    print("   Image size: \(image.size)")
                    self.manualTestResult = "✅ Manual load successful - Size: \(image.size)"
                    self.imageLoadStates[0] = "✅ Manual load success"
                } else {
                    print("❌ Manual cache load failed")
                    self.manualTestResult = "❌ Manual load failed"
                    self.imageLoadStates[0] = "❌ Manual load failed"
                }
            }
        }
    }
}

struct DebugImageCarouselView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DebugImageCarouselView(listing: Listing.example)
        }
    }
}