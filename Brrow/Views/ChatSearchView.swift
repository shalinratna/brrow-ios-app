//
//  ChatSearchView.swift
//  Brrow
//
//  In-conversation search functionality
//

import SwiftUI

struct ChatSearchView: View {
    @Binding var isPresented: Bool
    let messages: [Message]
    let onMessageSelected: (Message) -> Void

    @State private var searchText = ""
    @State private var searchResults: [Message] = []
    @State private var currentResultIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar

            // Results count
            if !searchResults.isEmpty {
                resultsHeader
            }

            // Search results list
            if searchText.isEmpty {
                emptySearchState
            } else if searchResults.isEmpty {
                noResultsState
            } else {
                searchResultsList
            }
        }
        .background(Theme.Colors.background)
        .onChange(of: searchText) { newValue in
            performSearch(query: newValue)
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Colors.primary)
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.Colors.secondaryText)

                TextField("Search messages...", text: $searchText)
                    .font(.system(size: 16))

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.Colors.surface)
            .cornerRadius(20)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.Colors.background)
    }

    // MARK: - Results Header
    private var resultsHeader: some View {
        HStack {
            Text("\(searchResults.count) result\(searchResults.count == 1 ? "" : "s")")
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.secondaryText)

            Spacer()

            // Navigation buttons
            HStack(spacing: 16) {
                Button(action: previousResult) {
                    Image(systemName: "chevron.up")
                        .foregroundColor(currentResultIndex > 0 ? Theme.Colors.primary : Theme.Colors.secondaryText)
                }
                .disabled(currentResultIndex <= 0)

                Button(action: nextResult) {
                    Image(systemName: "chevron.down")
                        .foregroundColor(currentResultIndex < searchResults.count - 1 ? Theme.Colors.primary : Theme.Colors.secondaryText)
                }
                .disabled(currentResultIndex >= searchResults.count - 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.Colors.surface)
    }

    // MARK: - Empty Search State
    private var emptySearchState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.secondaryText.opacity(0.5))

            Text("Search Messages")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Find specific messages in this conversation")
                .font(.body)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
        .padding()
    }

    // MARK: - No Results State
    private var noResultsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.secondaryText.opacity(0.5))

            Text("No Results")
                .font(.title3)
                .fontWeight(.semibold)

            Text("No messages found for '\(searchText)'")
                .font(.body)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
        .padding()
    }

    // MARK: - Search Results List
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, message in
                    SearchResultRow(
                        message: message,
                        searchText: searchText,
                        isSelected: index == currentResultIndex
                    )
                    .onTapGesture {
                        currentResultIndex = index
                        onMessageSelected(message)
                        isPresented = false
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Search Logic

    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            currentResultIndex = 0
            return
        }

        let lowercasedQuery = query.lowercased()

        searchResults = messages.filter { message in
            message.content.lowercased().contains(lowercasedQuery)
        }

        currentResultIndex = 0
    }

    private func previousResult() {
        if currentResultIndex > 0 {
            currentResultIndex -= 1
            if let message = searchResults[safe: currentResultIndex] {
                onMessageSelected(message)
            }
        }
    }

    private func nextResult() {
        if currentResultIndex < searchResults.count - 1 {
            currentResultIndex += 1
            if let message = searchResults[safe: currentResultIndex] {
                onMessageSelected(message)
            }
        }
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let message: Message
    let searchText: String
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Sender name and timestamp
            HStack {
                Text(message.sender?.username ?? "Unknown")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)

                Spacer()

                Text(formatDate(message.timestamp))
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.secondaryText)
            }

            // Message content with highlighted search term
            highlightedMessageContent
        }
        .padding(12)
        .background(isSelected ? Theme.Colors.primary.opacity(0.1) : Theme.Colors.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
        )
    }

    @ViewBuilder
    private var highlightedMessageContent: some View {
        let content = message.content
        let lowercasedContent = content.lowercased()
        let lowercasedSearch = searchText.lowercased()

        if let range = lowercasedContent.range(of: lowercasedSearch) {
            let beforeRange = content[..<range.lowerBound]
            let matchRange = content[range]
            let afterRange = content[range.upperBound...]

            (Text(beforeRange)
                .foregroundColor(Theme.Colors.text)
            + Text(matchRange)
                .foregroundColor(Theme.Colors.primary)
                .fontWeight(.bold)
            + Text(afterRange)
                .foregroundColor(Theme.Colors.text))
                .background(Theme.Colors.primary.opacity(0.2))
        } else {
            Text(content)
                .foregroundColor(Theme.Colors.text)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}
