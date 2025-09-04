//
//  MemoryEfficientComponents.swift
//  Brrow
//
//  Created by Claude on 7/26/25.
//  Memory-optimized UI components for better performance
//

import SwiftUI
import Combine

// MARK: - Lazy Loading List
struct LazyLoadingList<T: Identifiable, Content: View>: View {
    let items: [T]
    let content: (T) -> Content
    let onLoadMore: (() -> Void)?
    let itemsPerPage: Int
    
    @State private var visibleRange: Range<Int> = 0..<20
    @State private var isLoading = false
    
    init(
        items: [T],
        itemsPerPage: Int = 20,
        onLoadMore: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.items = items
        self.itemsPerPage = itemsPerPage
        self.onLoadMore = onLoadMore
        self.content = content
    }
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(visibleItems) { item in
                content(item)
                    .onAppear {
                        if item.id == visibleItems.last?.id {
                            expandVisibleRange()
                        }
                    }
            }
            
            if isLoading {
                ProgressView()
                    .frame(height: 50)
            }
        }
    }
    
    private var visibleItems: ArraySlice<T> {
        let endIndex = min(visibleRange.upperBound, items.count)
        return items[visibleRange.lowerBound..<endIndex]
    }
    
    private func expandVisibleRange() {
        guard !isLoading else { return }
        
        let newUpperBound = min(visibleRange.upperBound + itemsPerPage, items.count)
        
        if newUpperBound > visibleRange.upperBound {
            isLoading = true
            visibleRange = visibleRange.lowerBound..<newUpperBound
            
            // Simulate loading delay and call onLoadMore if needed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isLoading = false
                if newUpperBound >= items.count {
                    onLoadMore?()
                }
            }
        }
    }
}

// MARK: - Memory-Efficient Grid
struct MemoryEfficientGrid<T: Identifiable, Content: View>: View {
    let items: [T]
    let columns: [GridItem]
    let content: (T) -> Content
    let visibleThreshold: Int = 50
    
    @State private var visibleItems: Set<T.ID> = []
    
    init(
        items: [T],
        columns: [GridItem],
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.items = items
        self.columns = columns
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items) { item in
                    if visibleItems.contains(item.id) || visibleItems.count < visibleThreshold {
                        content(item)
                            .onAppear {
                                visibleItems.insert(item.id)
                            }
                            .onDisappear {
                                // Keep items in memory briefly after disappearing
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    if visibleItems.count > visibleThreshold {
                                        visibleItems.remove(item.id)
                                    }
                                }
                            }
                    } else {
                        // Placeholder for invisible items
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .aspectRatio(1, contentMode: .fit)
                            .onAppear {
                                visibleItems.insert(item.id)
                            }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Lightweight Image Card
struct LightweightImageCard: View {
    let imageUrl: String
    let title: String
    let subtitle: String?
    let price: String?
    let onTap: () -> Void
    
    @State private var isVisible = false
    
    private let cardSize = CGSize(width: 160, height: 200)
    private let imageSize = CGSize(width: 160, height: 120)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Optimized image loading using our new component
            if let url = URL(string: imageUrl) {
                OptimizedImageView(url: url, contentMode: .fill)
                    .frame(width: imageSize.width, height: imageSize.height)
                    .clipped()
                    .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: imageSize.width, height: imageSize.height)
                    .cornerRadius(12)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if let price = price {
                    Text(price)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.primary)
                }
            }
        }
        .frame(width: cardSize.width)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onAppear {
            isVisible = true
        }
        .onDisappear {
            isVisible = false
        }
    }
}

// MARK: - Shimmer Loading Effect
struct ShimmerEffect: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.gray.opacity(0.3),
                Color.gray.opacity(0.1),
                Color.gray.opacity(0.3)
            ]),
            startPoint: UnitPoint(x: phase - 0.3, y: 0.5),
            endPoint: UnitPoint(x: phase + 0.3, y: 0.5)
        )
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                phase = 1
            }
        }
    }
}

struct MemoryShimmerCard: View {
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .overlay(ShimmerEffect())
                .frame(width: width, height: height * 0.6)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Rectangle()
                    .overlay(ShimmerEffect())
                    .frame(width: width * 0.8, height: 16)
                    .cornerRadius(4)
                
                Rectangle()
                    .overlay(ShimmerEffect())
                    .frame(width: width * 0.6, height: 12)
                    .cornerRadius(4)
                
                Rectangle()
                    .overlay(ShimmerEffect())
                    .frame(width: width * 0.4, height: 14)
                    .cornerRadius(4)
            }
        }
        .frame(width: width)
    }
}

// MARK: - Performance-Optimized ScrollView
struct PerformantScrollView<Content: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    let content: () -> Content
    
    @State private var scrollOffset: CGPoint = .zero
    @State private var visibleBounds: CGRect = .zero
    
    init(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.content = content
    }
    
    var body: some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            GeometryReader { geometry in
                Color.clear
                    .preference(key: MemoryScrollOffsetPreferenceKey.self, value: CGPoint(x: -geometry.frame(in: .named("scroll")).minX, y: -geometry.frame(in: .named("scroll")).minY))
                    .preference(key: VisibleBoundsPreferenceKey.self, value: geometry.frame(in: .global))
            }
            .frame(height: 0)
            
            content()
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(MemoryScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
        }
        .onPreferenceChange(VisibleBoundsPreferenceKey.self) { value in
            visibleBounds = value
        }
    }
}

// MARK: - Preference Keys
struct MemoryScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
}

struct VisibleBoundsPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {}
}

// MARK: - Memory-Optimized List Item
struct MemoryOptimizedListItem<Content: View>: View {
    let id: String
    let content: () -> Content
    
    @State private var isInViewport = false
    @ObservedObject private var performanceManager = PerformanceManager.shared
    
    var body: some View {
        if isInViewport || performanceManager.alertLevel == .normal {
            content()
                .onAppear {
                    isInViewport = true
                }
                .onDisappear {
                    // Delay marking as not in viewport to prevent flickering
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        isInViewport = false
                    }
                }
        } else {
            // Lightweight placeholder
            Rectangle()
                .fill(Color.clear)
                .frame(height: 80)
                .onAppear {
                    isInViewport = true
                }
        }
    }
}

// MARK: - Batch Loading View
struct BatchLoadingView<T: Identifiable, Content: View>: View {
    let items: [T]
    let batchSize: Int
    let content: (T) -> Content
    
    @State private var loadedBatches = 1
    @State private var isLoading = false
    
    init(
        items: [T],
        batchSize: Int = 20,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.items = items
        self.batchSize = batchSize
        self.content = content
    }
    
    var body: some View {
        LazyVStack {
            ForEach(visibleItems) { item in
                content(item)
                    .onAppear {
                        if item.id == visibleItems.last?.id {
                            loadNextBatch()
                        }
                    }
            }
            
            if hasMoreItems && isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading more...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 50)
            }
        }
    }
    
    private var visibleItems: ArraySlice<T> {
        let endIndex = min(loadedBatches * batchSize, items.count)
        return items[0..<endIndex]
    }
    
    private var hasMoreItems: Bool {
        loadedBatches * batchSize < items.count
    }
    
    private func loadNextBatch() {
        guard hasMoreItems && !isLoading else { return }
        
        isLoading = true
        
        // Simulate loading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            loadedBatches += 1
            isLoading = false
        }
    }
}

// MARK: - View Modifier for Memory Optimization
struct MemoryOptimizationModifier: ViewModifier {
    @ObservedObject private var performanceManager = PerformanceManager.shared
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(performanceManager.alertLevel != .normal ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: performanceManager.alertLevel)
    }
}

extension View {
    func optimizeForMemory() -> some View {
        modifier(MemoryOptimizationModifier())
    }
}