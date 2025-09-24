//
//  ReviewFiltersView.swift
//  Brrow
//
//  Advanced filtering interface for reviews
//

import SwiftUI

struct ReviewFiltersView: View {
    @Binding var filters: ReviewFilters
    let onApply: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var tempFilters: ReviewFilters

    init(filters: Binding<ReviewFilters>, onApply: @escaping () -> Void) {
        self._filters = filters
        self.onApply = onApply
        self._tempFilters = State(initialValue: filters.wrappedValue)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Rating Filter
                    ratingFilterSection

                    // Review Type Filter
                    reviewTypeFilterSection

                    // Verification Filter
                    verificationFilterSection

                    // Date Range Filter
                    dateRangeFilterSection

                    // Sort Options
                    sortOptionsSection
                }
                .padding()
            }
            .navigationTitle("Filter Reviews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                    }
                    .fontWeight(.semibold)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        resetFilters()
                    }
                }
            }
        }
    }

    private var ratingFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Minimum Rating")
                .font(.headline)

            HStack(spacing: 16) {
                Button("All") {
                    tempFilters.rating = nil
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(tempFilters.rating == nil ? Color.blue : Color(.systemGray5))
                .foregroundColor(tempFilters.rating == nil ? .white : .primary)
                .cornerRadius(8)

                ForEach(1...5, id: \.self) { rating in
                    Button {
                        tempFilters.rating = rating
                    } label: {
                        HStack(spacing: 4) {
                            Text("\(rating)")
                            Image(systemName: "star.fill")
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(tempFilters.rating == rating ? Color.blue : Color(.systemGray5))
                    .foregroundColor(tempFilters.rating == rating ? .white : .primary)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var reviewTypeFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review Type")
                .font(.headline)

            VStack(spacing: 8) {
                reviewTypeOption(nil, title: "All Types")

                ForEach(ReviewType.allCases, id: \.self) { type in
                    reviewTypeOption(type, title: type.displayName)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func reviewTypeOption(_ type: ReviewType?, title: String) -> some View {
        Button {
            tempFilters.reviewType = type
        } label: {
            HStack {
                if let type = type {
                    Image(systemName: type.icon)
                        .foregroundColor(.blue)
                        .frame(width: 20)
                }

                Text(title)
                    .foregroundColor(.primary)

                Spacer()

                if tempFilters.reviewType == type {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }

    private var verificationFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Verification")
                .font(.headline)

            VStack(spacing: 8) {
                verificationOption(nil, title: "All Reviews")
                verificationOption(true, title: "Verified Only")
                verificationOption(false, title: "Unverified Only")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func verificationOption(_ verified: Bool?, title: String) -> some View {
        Button {
            tempFilters.isVerified = verified
        } label: {
            HStack {
                if let verified = verified {
                    Image(systemName: verified ? "checkmark.seal.fill" : "questionmark.circle")
                        .foregroundColor(verified ? .blue : .orange)
                        .frame(width: 20)
                }

                Text(title)
                    .foregroundColor(.primary)

                Spacer()

                if tempFilters.isVerified == verified {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }

    private var dateRangeFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date Range")
                .font(.headline)

            VStack(spacing: 8) {
                dateRangeOption(nil, title: "All Time")
                dateRangeOption(
                    ReviewFilters.DateRange(
                        startDate: ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()),
                        endDate: ISO8601DateFormatter().string(from: Date())
                    ),
                    title: "Last 7 Days"
                )
                dateRangeOption(
                    ReviewFilters.DateRange(
                        startDate: ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()),
                        endDate: ISO8601DateFormatter().string(from: Date())
                    ),
                    title: "Last 30 Days"
                )
                dateRangeOption(
                    ReviewFilters.DateRange(
                        startDate: ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()),
                        endDate: ISO8601DateFormatter().string(from: Date())
                    ),
                    title: "Last 3 Months"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func dateRangeOption(_ range: ReviewFilters.DateRange?, title: String) -> some View {
        Button {
            tempFilters.dateRange = range
        } label: {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                    .frame(width: 20)

                Text(title)
                    .foregroundColor(.primary)

                Spacer()

                if (tempFilters.dateRange == nil && range == nil) ||
                   (tempFilters.dateRange?.startDate == range?.startDate &&
                    tempFilters.dateRange?.endDate == range?.endDate) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }

    private var sortOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sort By")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(ReviewSortOption.allCases, id: \.self) { option in
                    sortOption(option)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private func sortOption(_ option: ReviewSortOption) -> some View {
        Button {
            tempFilters.sortBy = option
        } label: {
            HStack {
                Image(systemName: sortIcon(for: option))
                    .foregroundColor(.blue)
                    .frame(width: 20)

                Text(option.displayName)
                    .foregroundColor(.primary)

                Spacer()

                if tempFilters.sortBy == option {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }

    private func sortIcon(for option: ReviewSortOption) -> String {
        switch option {
        case .newest: return "clock"
        case .oldest: return "clock.arrow.circlepath"
        case .highestRated: return "star.fill"
        case .lowestRated: return "star"
        case .mostHelpful: return "hand.thumbsup"
        }
    }

    private func applyFilters() {
        filters = tempFilters
        onApply()
        dismiss()
    }

    private func resetFilters() {
        tempFilters = ReviewFilters(
            rating: nil,
            reviewType: nil,
            status: .approved,
            isVerified: nil,
            dateRange: nil,
            sortBy: .newest,
            sortOrder: .descending
        )
    }
}

// MARK: - Preview

struct ReviewFiltersView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewFiltersView(
            filters: .constant(ReviewFilters(
                rating: nil,
                reviewType: nil,
                status: .approved,
                isVerified: nil,
                dateRange: nil,
                sortBy: .newest,
                sortOrder: .descending
            ))
        ) {
            // Preview action
        }
    }
}