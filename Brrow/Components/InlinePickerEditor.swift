//
//  InlinePickerEditor.swift
//  Brrow
//
//  Created by Claude Code on 11/13/25.
//

import SwiftUI

/// Inline editor for picker fields (category, condition)
struct InlinePickerEditor: View {
    let field: EditableField
    @ObservedObject var viewModel: InlineEditViewModel

    @State private var selectedValue: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(fieldDescription)
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.secondaryText)

            // Options list
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(options, id: \.value) { option in
                    Button(action: {
                        selectedValue = option.value
                        viewModel.updateBuffer(key: bufferKey, value: option.value)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.label)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Theme.Colors.text)

                                if let description = option.description {
                                    Text(description)
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.Colors.secondaryText)
                                }
                            }

                            Spacer()

                            if selectedValue == option.value {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Theme.Colors.primary)
                            } else {
                                Image(systemName: "circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(Theme.Colors.border)
                            }
                        }
                        .padding(Theme.Spacing.md)
                        .background(
                            selectedValue == option.value ?
                            Theme.Colors.primary.opacity(0.1) : Theme.Colors.secondaryBackground
                        )
                        .cornerRadius(Theme.CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                .stroke(
                                    selectedValue == option.value ?
                                    Theme.Colors.primary : Theme.Colors.border,
                                    lineWidth: selectedValue == option.value ? 2 : 1
                                )
                        )
                    }
                }
            }
        }
        .onAppear {
            if field == .condition {
                selectedValue = (viewModel.editBuffer["condition"] as? String) ?? viewModel.listing.condition
            } else if field == .category {
                selectedValue = (viewModel.editBuffer["categoryId"] as? String) ?? viewModel.listing.categoryId
            }
        }
    }

    // MARK: - Field-Specific Properties

    private var fieldDescription: String {
        switch field {
        case .condition:
            return "Select the condition that best describes your item"
        case .category:
            return "Choose the category that best fits your listing"
        default:
            return ""
        }
    }

    private var bufferKey: String {
        switch field {
        case .condition: return "condition"
        case .category: return "categoryId"
        default: return ""
        }
    }

    private var options: [(label: String, value: String, description: String?)] {
        switch field {
        case .condition:
            return [
                ("Brand New", "NEW", "Never used, in original packaging"),
                ("Like New", "LIKE_NEW", "Barely used, excellent condition"),
                ("Excellent", "EXCELLENT", "Lightly used, very good condition"),
                ("Good", "GOOD", "Used with normal wear"),
                ("Fair", "FAIR", "Well used, shows wear")
            ]
        case .category:
            // Simplified - in real implementation, fetch from BrrowCategory enum
            return [
                ("Electronics", "electronics", nil),
                ("Tools & Equipment", "tools", nil),
                ("Sports & Outdoors", "sports", nil),
                ("Home & Garden", "home", nil),
                ("Vehicles", "vehicles", nil),
                ("Other", "other", nil)
            ]
        default:
            return []
        }
    }
}
