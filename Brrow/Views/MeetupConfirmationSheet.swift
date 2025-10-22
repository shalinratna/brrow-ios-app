//
//  MeetupConfirmationSheet.swift
//  Brrow
//
//  Confirmation screen before scheduling meetup
//

import SwiftUI
import MapKit

struct MeetupConfirmationSheet: View {
    let location: CLLocationCoordinate2D
    let address: String
    let scheduledTime: Date
    let notes: String?
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var region: MKCoordinateRegion

    init(location: CLLocationCoordinate2D, address: String, scheduledTime: Date, notes: String?, onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.location = location
        self.address = address
        self.scheduledTime = scheduledTime
        self.notes = notes
        self.onConfirm = onConfirm
        self.onCancel = onCancel

        _region = State(initialValue: MKCoordinateRegion(
            center: location,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Map Preview
                    mapPreview

                    // Details Summary
                    detailsSection

                    // Action Buttons
                    actionButtons
                }
                .padding(20)
            }
            .background(
                LinearGradient(
                    colors: [
                        Theme.Colors.primary.opacity(0.03),
                        Color.white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Confirm Meetup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        onCancel()
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Cancel")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(Theme.Colors.text)
                    }
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.primary.opacity(0.2),
                                Theme.Colors.primary.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("Review Meetup Details")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.Colors.text)

            Text("Please confirm the meetup information before scheduling")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 20)
    }

    // MARK: - Map Preview
    private var mapPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "map.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.primary)

                Text("Meetup Location")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
            }

            Map(coordinateRegion: .constant(region), annotationItems: [MapPoint(coordinate: location)]) { item in
                MapMarker(coordinate: item.coordinate, tint: Theme.Colors.primary)
            }
            .frame(height: 200)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 2)
            )

            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.Colors.primary)

                Text(address)
                    .font(.system(size: 15))
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(2)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.Colors.primary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.Colors.primary.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(spacing: 16) {
            // Date and Time
            DetailRow(
                icon: "calendar",
                title: "Date & Time",
                value: scheduledTime.formatted(date: .abbreviated, time: .shortened)
            )

            Divider()

            // Time from now
            DetailRow(
                icon: "clock",
                title: "Time from now",
                value: timeFromNow(scheduledTime)
            )

            if let notes = notes, !notes.isEmpty {
                Divider()

                DetailRow(
                    icon: "note.text",
                    title: "Notes",
                    value: notes
                )
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                HapticManager.impact(style: .medium)
                onConfirm()
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Confirm & Schedule")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(
                    color: Theme.Colors.primary.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }

            Button(action: {
                onCancel()
                dismiss()
            }) {
                Text("Go Back & Edit")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 20)
    }

    // MARK: - Helper Functions
    private func timeFromNow(_ date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 24 {
            let days = hours / 24
            return "in \(days) day\(days == 1 ? "" : "s")"
        } else if hours > 0 {
            return "in \(hours) hour\(hours == 1 ? "" : "s") \(minutes) min"
        } else {
            return "in \(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.Colors.text)
            }

            Spacer()
        }
    }
}

// MARK: - Map Point Helper
private struct MapPoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Preview
#Preview {
    MeetupConfirmationSheet(
        location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        address: "San Francisco, CA",
        scheduledTime: Date().addingTimeInterval(3600),
        notes: "Meet at the main entrance",
        onConfirm: {},
        onCancel: {}
    )
}
