//
//  MeetupCard.swift
//  Brrow
//
//  Card component for displaying upcoming meetups in News & Updates section
//

import SwiftUI
import MapKit

struct MeetupCard: View {
    let meetup: UpcomingMeetup
    let onTap: () -> Void

    @State private var region: MKCoordinateRegion

    init(meetup: UpcomingMeetup, onTap: @escaping () -> Void) {
        self.meetup = meetup
        self.onTap = onTap

        // Initialize region with meetup location
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: meetup.meetupLatitude ?? 0,
                longitude: meetup.meetupLongitude ?? 0
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(hex: "#FF6B6B"),  // Warm red
                        Color(hex: "#FF8E53")   // Warm orange
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(alignment: .leading, spacing: 0) {
                    // Map preview
                    if let latitude = meetup.meetupLatitude,
                       let longitude = meetup.meetupLongitude {
                        Map(coordinateRegion: .constant(region),
                            annotationItems: [MeetupMapLocation(
                                id: 0,
                                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                            )]) { location in
                            MapPin(coordinate: location.coordinate, tint: .red)
                        }
                        .frame(height: 80)
                        .opacity(0.9)
                        .overlay(
                            LinearGradient(
                                colors: [Color.black.opacity(0.3), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }

                    // Content
                    VStack(alignment: .leading, spacing: 12) {
                        // Header
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)

                            Text("Upcoming Meetup")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                                .textCase(.uppercase)
                                .tracking(0.5)

                            Spacer()

                            // Status badge
                            Text(meetup.status.capitalized)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.25))
                                .cornerRadius(6)
                        }

                        // Listing title
                        Text(meetup.listing.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        // Meetup details
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 12))
                                Text(formatMeetupTime(meetup.meetupTime))
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.95))

                            if let location = meetup.meetupLocation, !location.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 12))
                                    Text(location)
                                        .font(.system(size: 13, weight: .medium))
                                        .lineLimit(1)
                                }
                                .foregroundColor(.white.opacity(0.95))
                            }

                            // Other party info
                            HStack(spacing: 8) {
                                let otherParty = meetup.userRole == "buyer" ? meetup.seller : meetup.buyer

                                Text(meetup.userRole == "buyer" ? "Seller:" : "Buyer:")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))

                                if let profilePicture = otherParty.profilePicture, !profilePicture.isEmpty {
                                    BrrowAsyncImage(url: profilePicture) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.white.opacity(0.3))
                                    }
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 24, height: 24)
                                }

                                Text(otherParty.displayName ?? otherParty.username)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                        }

                        // Action button
                        HStack {
                            Spacer()
                            Text("View Details")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 4)
                    }
                    .padding(16)
                }
            }
            .frame(width: 300, height: 240)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.25), radius: 15, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatMeetupTime(_ date: Date?) -> String {
        guard let date = date else { return "TBD" }

        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Today at \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Tomorrow at \(formatter.string(from: date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d 'at' h:mm a"
            return formatter.string(from: date)
        }
    }
}

// Helper struct for map annotation (specific to this card)
private struct MeetupMapLocation: Identifiable {
    let id: Int
    let coordinate: CLLocationCoordinate2D
}
