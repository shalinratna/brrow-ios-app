//
//  GarageSalePreviewPopup.swift
//  Brrow
//
//  Smooth animated popup for garage sale preview
//

import SwiftUI

struct GarageSalePreviewPopup: View {
    let garageSale: GarageSale
    @Binding var isShowing: Bool
    let onViewDetails: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Handle bar
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 4)
                Spacer()
            }
            .padding(.top, 8)
            .onTapGesture {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isShowing = false
                }
            }
            
            HStack(spacing: 16) {
                // Image
                if let firstImage = garageSale.images.first {
                    BrrowAsyncImage(url: firstImage) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: "house.fill")
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    // Title with business/boosted indicator
                    HStack {
                        Text(garageSale.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.Colors.text)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        // Business indicator
                        if garageSale.isBusiness {
                            HStack(spacing: 4) {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 10))
                                Text("Business")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                    
                    // Category
                    if let firstCategory = garageSale.tags.first {
                        Text(firstCategory)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.Colors.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.Colors.primary.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Date and time
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.secondaryText)
                            Text(formatDate(garageSale.startDate))
                                .font(.system(size: 13))
                                .foregroundColor(Theme.Colors.text)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.secondaryText)
                            Text(formatTime(garageSale.startTime, endTime: garageSale.endTime))
                                .font(.system(size: 13))
                                .foregroundColor(Theme.Colors.text)
                        }
                    }
                    
                    // Status indicator
                    if garageSale.isActive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("LIVE NOW")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isShowing = false
                    }
                }) {
                    Text("Close")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isShowing = false
                    }
                    onViewDetails()
                }) {
                    Text("View Full Details")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(Theme.Colors.primary)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -2)
        )
        .padding(.horizontal, 16)
        .onTapGesture {
            // Prevent tap-through to map
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        guard let date = inputFormatter.date(from: dateString) else { return dateString }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d, yyyy"
        return outputFormatter.string(from: date)
    }
    
    private func formatTime(_ startTime: String, endTime: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "HH:mm:ss"
        
        guard let start = inputFormatter.date(from: startTime),
              let end = inputFormatter.date(from: endTime) else {
            return "\(startTime) - \(endTime)"
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "h:mm a"
        
        let startStr = outputFormatter.string(from: start)
        let endStr = outputFormatter.string(from: end)
        
        return "\(startStr) - \(endStr)"
    }
}

struct GarageSalePreviewPopup_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.3)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                GarageSalePreviewPopup(
                    garageSale: GarageSale(
                        id: "preview-1",
                        hostId: "host123",
                        title: "Big Family Garage Sale",
                        description: "Lots of items for sale",
                        location: "San Francisco, CA",
                        address: "123 Main St",
                        latitude: 37.7749,
                        longitude: -122.4194,
                        saleDate: "2025-08-08",
                        startTime: "08:00:00",
                        endTime: "16:00:00",
                        startDate: "2025-08-08 08:00:00",
                        endDate: "2025-08-08 16:00:00",
                        images: ["https://example.com/image1.jpg"],
                        tags: ["Furniture", "Electronics"],
                        rsvpCount: 5,
                        interestedCount: 12,
                        isPublic: true,
                        host: GarageSaleHost(
                            username: "john_doe",
                            profilePicture: nil,
                            verified: true,
                            rating: 5
                        ),
                        isActive: true,
                        isUpcoming: false,
                        isPast: false,
                        isBusiness: true,
                        isBoosted: false
                    ),
                    isShowing: .constant(true),
                    onViewDetails: {}
                )
            }
        }
    }
}