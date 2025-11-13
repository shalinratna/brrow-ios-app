//
//  InlineTextEditor.swift
//  Brrow
//
//  Created by Claude Code on 11/13/25.
//

import SwiftUI

/// Inline editor for text fields (title, description, tags)
struct InlineTextEditor: View {
    let field: EditableField
    @ObservedObject var viewModel: InlineEditViewModel
    @FocusState private var isFocused: Bool

    // Local state for text input
    @State private var text: String = ""
    @State private var tagInput: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            switch field {
            case .title:
                titleEditor
            case .description:
                descriptionEditor
            case .tags:
                tagsEditor
            default:
                EmptyView()
            }
        }
        .onAppear {
            // Initialize from edit buffer
            if field == .title, let title = viewModel.editBuffer["title"] as? String {
                text = title
            } else if field == .description, let desc = viewModel.editBuffer["description"] as? String {
                text = desc
            }
            isFocused = true
        }
    }

    // MARK: - Title Editor

    private var titleEditor: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            TextField("Enter listing title", text: $text)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(Theme.CornerRadius.md)
                .focused($isFocused)
                .onChange(of: text) { newValue in
                    viewModel.updateBuffer(key: "title", value: newValue)
                }

            HStack {
                Text("\(text.count)/60")
                    .font(.system(size: 14))
                    .foregroundColor(
                        text.count > 60 ? Theme.Colors.error : Theme.Colors.secondaryText
                    )

                Spacer()

                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        viewModel.updateBuffer(key: "title", value: "")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }

            Text("Choose a clear, descriptive title for your listing")
                .font(.system(size: 13))
                .foregroundColor(Theme.Colors.secondaryText)
        }
    }

    // MARK: - Description Editor

    private var descriptionEditor: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Describe your item in detail...")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.secondaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $text)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.text)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(Theme.CornerRadius.md)
                    .focused($isFocused)
                    .onChange(of: text) { newValue in
                        viewModel.updateBuffer(key: "description", value: newValue)
                    }
            }

            HStack {
                Text("\(text.count)/500")
                    .font(.system(size: 14))
                    .foregroundColor(
                        text.count > 500 ? Theme.Colors.error : Theme.Colors.secondaryText
                    )

                Spacer()

                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        viewModel.updateBuffer(key: "description", value: "")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }

            Text("Include condition, features, dimensions, or anything buyers should know")
                .font(.system(size: 13))
                .foregroundColor(Theme.Colors.secondaryText)
        }
    }

    // MARK: - Tags Editor

    private var tagsEditor: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Current tags
            if let tags = viewModel.editBuffer["tags"] as? [String], !tags.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Current Tags")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.secondaryText)

                    FlowLayout(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            TagChip(text: tag, onDelete: {
                                var updatedTags = tags
                                updatedTags.removeAll { $0 == tag }
                                viewModel.updateBuffer(key: "tags", value: updatedTags)
                            })
                        }
                    }
                }
            }

            // Add new tag
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.sm) {
                    TextField("Add a tag...", text: $tagInput)
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.text)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Colors.secondaryBackground)
                        .cornerRadius(Theme.CornerRadius.md)
                        .focused($isFocused)
                        .onSubmit {
                            addTag()
                        }

                    Button(action: addTag) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Theme.Colors.primary)
                    }
                    .disabled(tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Text("Press return or tap + to add tags (helps users find your listing)")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
    }

    // MARK: - Helper Methods

    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var tags = (viewModel.editBuffer["tags"] as? [String]) ?? []
        if !tags.contains(trimmed) {
            tags.append(trimmed)
            viewModel.updateBuffer(key: "tags", value: tags)
        }

        tagInput = ""
    }
}

// MARK: - Supporting Views

/// Tag chip with delete button
struct TagChip: View {
    let text: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.text)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
}

/// Flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}
