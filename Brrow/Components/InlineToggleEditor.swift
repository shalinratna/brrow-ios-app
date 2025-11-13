//
//  InlineToggleEditor.swift
//  Brrow
//
//  Created by Claude Code on 11/13/25.
//

import SwiftUI

/// Inline editor for toggle fields (delivery options, negotiable)
struct InlineToggleEditor: View {
    let field: EditableField
    @ObservedObject var viewModel: InlineEditViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            if field == .deliveryOptions {
                deliveryOptionsEditor
            } else if field == .negotiable {
                negotiableEditor
            }
        }
    }

    // MARK: - Delivery Options Editor

    private var deliveryOptionsEditor: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("How will you fulfill transactions?")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.secondaryText)

            VStack(spacing: Theme.Spacing.sm) {
                // Pickup
                toggleOption(
                    title: "Pickup Available",
                    description: "Buyers can pick up in person",
                    icon: "car.fill",
                    isOn: Binding(
                        get: {
                            if let options = viewModel.editBuffer["deliveryOptions"] as? DeliveryOptions {
                                return options.pickup
                            }
                            return viewModel.listing.deliveryOptions?.pickup ?? false
                        },
                        set: { newValue in
                            let currentOptions = (viewModel.editBuffer["deliveryOptions"] as? DeliveryOptions) ?? viewModel.listing.deliveryOptions ?? DeliveryOptions(pickup: false, delivery: false, shipping: false)
                            let options = DeliveryOptions(pickup: newValue, delivery: currentOptions.delivery, shipping: currentOptions.shipping)
                            viewModel.updateBuffer(key: "deliveryOptions", value: options)
                        }
                    )
                )

                // Delivery
                toggleOption(
                    title: "Delivery Available",
                    description: "You can deliver to the buyer",
                    icon: "shippingbox.fill",
                    isOn: Binding(
                        get: {
                            if let options = viewModel.editBuffer["deliveryOptions"] as? DeliveryOptions {
                                return options.delivery
                            }
                            return viewModel.listing.deliveryOptions?.delivery ?? false
                        },
                        set: { newValue in
                            let currentOptions = (viewModel.editBuffer["deliveryOptions"] as? DeliveryOptions) ?? viewModel.listing.deliveryOptions ?? DeliveryOptions(pickup: false, delivery: false, shipping: false)
                            let options = DeliveryOptions(pickup: currentOptions.pickup, delivery: newValue, shipping: currentOptions.shipping)
                            viewModel.updateBuffer(key: "deliveryOptions", value: options)
                        }
                    )
                )

                // Shipping
                toggleOption(
                    title: "Shipping Available",
                    description: "You can ship the item",
                    icon: "airplane",
                    isOn: Binding(
                        get: {
                            if let options = viewModel.editBuffer["deliveryOptions"] as? DeliveryOptions {
                                return options.shipping
                            }
                            return viewModel.listing.deliveryOptions?.shipping ?? false
                        },
                        set: { newValue in
                            let currentOptions = (viewModel.editBuffer["deliveryOptions"] as? DeliveryOptions) ?? viewModel.listing.deliveryOptions ?? DeliveryOptions(pickup: false, delivery: false, shipping: false)
                            let options = DeliveryOptions(pickup: currentOptions.pickup, delivery: currentOptions.delivery, shipping: newValue)
                            viewModel.updateBuffer(key: "deliveryOptions", value: options)
                        }
                    )
                )
            }
        }
    }

    // MARK: - Negotiable Editor

    private var negotiableEditor: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Would you like to receive offers on this listing?")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.secondaryText)

            toggleOption(
                title: "Allow Offers",
                description: "Buyers can make offers below your asking price",
                icon: "dollarsign.circle.fill",
                isOn: Binding(
                    get: {
                        (viewModel.editBuffer["negotiable"] as? Bool) ?? viewModel.listing.isNegotiable
                    },
                    set: { newValue in
                        viewModel.updateBuffer(key: "negotiable", value: newValue)
                    }
                )
            )
        }
    }

    // MARK: - Helper View

    private func toggleOption(title: String, description: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isOn.wrappedValue ? Theme.Colors.primary : Theme.Colors.secondaryText)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Theme.Colors.primary)
        }
        .padding(Theme.Spacing.md)
        .background(isOn.wrappedValue ? Theme.Colors.primary.opacity(0.05) : Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.CornerRadius.md)
    }
}
