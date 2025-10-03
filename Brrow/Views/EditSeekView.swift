//
//  EditSeekView.swift
//  Brrow
//
//  Edit existing seek functionality
//

import SwiftUI
import PhotosUI

struct EditSeekView: View {
    @Environment(\.dismiss) var dismiss
    @FocusState private var focusedField: Field?

    let seek: Seek

    @State private var title: String
    @State private var description: String
    @State private var selectedCategory: String
    @State private var maxBudget: String
    @State private var searchRadius: Double
    @State private var urgency: UrgencyLevel
    @State private var isSubmitting = false
    @State private var showingDeleteConfirmation = false

    enum Field: Hashable {
        case title
        case description
        case budget
    }

    enum UrgencyLevel: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"

        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return Theme.Colors.primary
            case .high: return .red
            }
        }

        var description: String {
            switch self {
            case .low: return "No rush"
            case .medium: return "Need within a week"
            case .high: return "Need within 24 hours"
            }
        }
    }

    init(seek: Seek) {
        self.seek = seek
        self._title = State(initialValue: seek.title)
        self._description = State(initialValue: seek.description)
        self._selectedCategory = State(initialValue: seek.category)
        self._maxBudget = State(initialValue: seek.maxBudget != nil ? String(format: "%.0f", seek.maxBudget!) : "")
        self._searchRadius = State(initialValue: seek.maxDistance)

        // Map urgency string to enum
        let urgencyMapping: [String: UrgencyLevel] = ["low": .low, "medium": .medium, "high": .high]
        self._urgency = State(initialValue: urgencyMapping[seek.urgency.lowercased()] ?? .medium)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.primary.opacity(0.1))
                                .frame(width: 100, height: 100)

                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Theme.Colors.primary)
                        }

                        Text("Edit Seek")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Theme.Colors.text)
                    }
                    .padding(.top, 20)

                    // Form
                    VStack(spacing: 20) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Label("What are you looking for?", systemImage: "magnifyingglass")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)

                            TextField("e.g., Power drill for weekend project", text: $title)
                                .padding()
                                .background(Theme.Colors.secondaryBackground)
                                .cornerRadius(12)
                                .focused($focusedField, equals: .title)
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Additional Details", systemImage: "text.alignleft")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)

                            ZStack(alignment: .topLeading) {
                                if description.isEmpty {
                                    Text("Describe what you need...")
                                        .foregroundColor(Theme.Colors.tertiaryText)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 20)
                                        .allowsHitTesting(false)
                                }

                                TextEditor(text: $description)
                                    .frame(height: 100)
                                    .padding(12)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .focused($focusedField, equals: .description)
                            }
                            .background(Theme.Colors.secondaryBackground)
                            .cornerRadius(12)
                        }

                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Category", systemImage: "square.grid.2x2")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)

                            Menu {
                                ForEach(CategoryHelper.getPopularCategories(), id: \.self) { category in
                                    Button(category) {
                                        selectedCategory = category
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedCategory)
                                        .foregroundColor(Theme.Colors.text)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(Theme.Colors.secondaryText)
                                }
                                .padding()
                                .background(Theme.Colors.secondaryBackground)
                                .cornerRadius(12)
                            }
                        }

                        // Budget
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Maximum Budget", systemImage: "dollarsign.circle")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)

                            HStack {
                                Text("$")
                                    .foregroundColor(Theme.Colors.secondaryText)
                                TextField("0", text: $maxBudget)
                                    .keyboardType(.decimalPad)
                                    .focused($focusedField, equals: .budget)
                            }
                            .padding()
                            .background(Theme.Colors.secondaryBackground)
                            .cornerRadius(12)
                        }

                        // Search Radius
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Search Radius", systemImage: "location.circle")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)

                            VStack(spacing: 8) {
                                HStack {
                                    Text("\(Int(searchRadius)) miles")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(Theme.Colors.primary)
                                    Spacer()
                                }

                                Slider(value: $searchRadius, in: 1...50, step: 1)
                                    .accentColor(Theme.Colors.primary)
                            }
                        }

                        // Urgency
                        VStack(alignment: .leading, spacing: 12) {
                            Label("How urgent is this?", systemImage: "clock")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)

                            HStack(spacing: 12) {
                                ForEach(UrgencyLevel.allCases, id: \.self) { level in
                                    EditSeekUrgencyButton(
                                        level: level,
                                        isSelected: urgency == level,
                                        action: { urgency = level }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Action Buttons
                    VStack(spacing: 12) {
                        // Save Button
                        Button(action: saveChanges) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Save Changes")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Theme.Colors.primary)
                            .cornerRadius(27)
                        }
                        .disabled(title.isEmpty || isSubmitting)

                        // Delete Button
                        Button(action: { showingDeleteConfirmation = true }) {
                            Text("Delete Seek")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(27)
                        }
                        .disabled(isSubmitting)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        focusedField = nil
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                        .foregroundColor(Theme.Colors.primary)
                    }
                }
            }
            .alert("Delete Seek", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteSeek()
                }
            } message: {
                Text("Are you sure you want to delete this seek? This action cannot be undone.")
            }
        }
    }

    private func saveChanges() {
        focusedField = nil
        guard !title.isEmpty else { return }

        isSubmitting = true

        Task {
            do {
                let updates: [String: Any] = [
                    "title": title,
                    "description": description,
                    "category": selectedCategory,
                    "max_distance": searchRadius,
                    "max_budget": maxBudget.isEmpty ? NSNull() : Double(maxBudget) ?? 0,
                    "urgency": urgency.rawValue.lowercased()
                ]

                _ = try await APIClient.shared.updateSeek(seekId: String(seek.id), updates: updates)

                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    print("Error updating seek: \(error)")
                }
            }
        }
    }

    private func deleteSeek() {
        isSubmitting = true

        Task {
            do {
                try await APIClient.shared.deleteSeek(seekId: String(seek.id))

                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    print("Error deleting seek: \(error)")
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct EditSeekUrgencyButton: View {
    let level: EditSeekView.UrgencyLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(level.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                Text(level.description)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? level.color.opacity(0.8) : Theme.Colors.secondaryText)
            }
            .foregroundColor(isSelected ? .white : Theme.Colors.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? level.color : Theme.Colors.secondaryBackground)
            .cornerRadius(12)
        }
    }
}

