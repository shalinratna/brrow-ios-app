//
//  MapPinPopupCard.swift
//  Brrow
//
//  3D popup card for map pin interactions (GTA Dynasty style)
//

import SwiftUI

struct MapPinPopupCard: View {
    let username: String
    let profilePictureUrl: String?
    let arrivalStatus: String
    let isArrived: Bool
    let distanceText: String
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var offsetY: CGFloat = 20

    var body: some View {
        ZStack {
            // Backdrop - tap to dismiss
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }

            // 3D Card
            VStack(spacing: 0) {
                // Card Content
                VStack(spacing: Theme.Spacing.md) {
                    // Profile Section
                    HStack(spacing: Theme.Spacing.sm) {
                        // Profile Picture
                        AsyncImage(url: URL(string: profilePictureUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 4)

                        // User Info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(username)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)

                            // Arrival Status Badge
                            HStack(spacing: 4) {
                                Image(systemName: isArrived ? "checkmark.circle.fill" : "clock.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(isArrived ? Theme.Colors.success : Theme.Colors.warning)

                                Text(arrivalStatus)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(isArrived ? Theme.Colors.success : Theme.Colors.warning)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isArrived ? Theme.Colors.success.opacity(0.1) : Theme.Colors.warning.opacity(0.1))
                            .cornerRadius(12)
                        }

                        Spacer()
                    }

                    // Distance Info
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.primary)

                        Text(distanceText)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Theme.Colors.secondaryText)

                        Spacer()
                    }
                    .padding(Theme.Spacing.sm)
                    .background(Theme.Colors.surface)
                    .cornerRadius(10)
                }
                .padding(Theme.Spacing.md)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)

                // Arrow pointing down
                TriangleArrow()
                    .fill(Color.white)
                    .frame(width: 20, height: 10)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(y: offsetY)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
                offsetY = 0
            }
        }
    }

    private func dismissWithAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 0.8
            opacity = 0
            offsetY = 20
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// Triangle shape for arrow
private struct TriangleArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    MapPinPopupCard(
        username: "ballinshalin",
        profilePictureUrl: nil,
        arrivalStatus: "Arrived",
        isArrived: true,
        distanceText: "150 ft from meetup",
        onDismiss: {}
    )
}
