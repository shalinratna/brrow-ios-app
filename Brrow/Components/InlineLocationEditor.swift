//
//  InlineLocationEditor.swift
//  Brrow
//
//  Created by Claude Code on 11/13/25.
//

import SwiftUI

/// Inline editor for location field
struct InlineLocationEditor: View {
    @ObservedObject var viewModel: InlineEditViewModel

    @State private var addressText: String = ""
    @State private var cityText: String = ""
    @State private var stateText: String = ""
    @State private var zipText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Update listing location")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.secondaryText)

            // Address
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Street Address")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Colors.secondaryText)

                TextField("123 Main St", text: $addressText)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.text)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(Theme.CornerRadius.md)
            }

            // City
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("City")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Colors.secondaryText)

                TextField("San Francisco", text: $cityText)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.text)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(Theme.CornerRadius.md)
            }

            // State & Zip
            HStack(spacing: Theme.Spacing.md) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("State")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.secondaryText)

                    TextField("CA", text: $stateText)
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.text)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(Theme.CornerRadius.md)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Zip Code")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.secondaryText)

                    TextField("94102", text: $zipText)
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.text)
                        .keyboardType(.numberPad)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(Theme.CornerRadius.md)
                }
            }

            Button(action: {
                // Update location in buffer
                let location = Location(
                    address: addressText,
                    city: cityText,
                    state: stateText,
                    zipCode: zipText,
                    country: viewModel.listing.location.country,
                    latitude: viewModel.listing.location.latitude,
                    longitude: viewModel.listing.location.longitude
                )
                viewModel.updateBuffer(key: "location", value: location)
            }) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Use Current Location")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.Colors.primary)
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.primary.opacity(0.1))
                .cornerRadius(Theme.CornerRadius.md)
            }
        }
        .onAppear {
            if let location = viewModel.editBuffer["location"] as? Location {
                addressText = location.address
                cityText = location.city
                stateText = location.state
                zipText = location.zipCode
            } else {
                addressText = viewModel.listing.location.address
                cityText = viewModel.listing.location.city
                stateText = viewModel.listing.location.state
                zipText = viewModel.listing.location.zipCode
            }
        }
    }
}
