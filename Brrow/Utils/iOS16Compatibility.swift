//
//  iOS16Compatibility.swift
//  Brrow
//
//  iOS 16+ feature compatibility layer for iOS 15.0 deployment target
//

import SwiftUI
import Foundation

// MARK: - NavigationPath Compatibility
@available(iOS 15.0, *)
public struct NavigationPathCompat {
    private var paths: [String] = []

    public init() {}

    public mutating func append(_ value: String) {
        paths.append(value)
    }

    public mutating func removeLast(_ count: Int = 1) {
        guard count <= paths.count else { return }
        paths.removeLast(count)
    }

    public var count: Int {
        return paths.count
    }

    public var isEmpty: Bool {
        return paths.isEmpty
    }
}

// MARK: - PhotosPicker Compatibility
@available(iOS 15.0, *)
public struct PhotosPickerItemCompat: Identifiable {
    public let id = UUID()
    public let itemIdentifier: String

    public init(itemIdentifier: String) {
        self.itemIdentifier = itemIdentifier
    }
}

// MARK: - View Extensions for iOS 16+ Features
@available(iOS 15.0, *)
extension View {
    @ViewBuilder
    func iOS16ScrollContentBackground(_ visibility: Bool) -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(visibility ? .visible : .hidden)
        } else {
            self
        }
    }

    @ViewBuilder
    func iOS16FontWeight(_ weight: Font.Weight) -> some View {
        if #available(iOS 16.0, *) {
            self.fontWeight(weight)
        } else {
            self.font(.system(size: 17, weight: weight))
        }
    }

    @ViewBuilder
    func iOS16LineLimit(_ limit: Int?) -> some View {
        if #available(iOS 16.0, *) {
            self.lineLimit(limit)
        } else {
            self.lineLimit(limit ?? 1)
        }
    }

    @ViewBuilder
    func iOS16ForegroundStyle<S: ShapeStyle>(_ style: S) -> some View {
        if #available(iOS 16.0, *) {
            self.foregroundStyle(style)
        } else {
            self.foregroundColor(.primary)
        }
    }

    @ViewBuilder
    func iOS17ContainerBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(.fill.tertiary, for: .widget)
        } else {
            self.background(Color(.systemBackground))
        }
    }

    @ViewBuilder
    func iOS17OnChange<V: Equatable>(of value: V, initial: Bool = false, action: @escaping () -> Void) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value, initial: initial) { _, _ in
                action()
            }
        } else {
            self.onChange(of: value) { _ in
                action()
            }
        }
    }

    @ViewBuilder
    func iOS16ScrollIndicators(_ visibility: Bool) -> some View {
        if #available(iOS 16.0, *) {
            self.scrollIndicators(visibility ? .visible : .hidden)
        } else {
            self
        }
    }

    @ViewBuilder
    func iOS16GridCellColumns(_ count: Int) -> some View {
        if #available(iOS 16.0, *) {
            self.gridCellColumns(count)
        } else {
            self
        }
    }

    @ViewBuilder
    func iOS16ToolbarColorScheme(_ colorScheme: ColorScheme) -> some View {
        if #available(iOS 16.0, *) {
            self.toolbarColorScheme(colorScheme, for: .automatic)
        } else {
            self
        }
    }

    @ViewBuilder
    func iOS16ContentTransition() -> some View {
        if #available(iOS 16.0, *) {
            self.contentTransition(.opacity)
        } else {
            self
        }
    }
}

// MARK: - TextField Compatibility
@available(iOS 15.0, *)
struct TextFieldCompat: View {
    let titleKey: LocalizedStringKey
    @Binding var text: String
    let axis: Axis?

    init(_ titleKey: LocalizedStringKey, text: Binding<String>, axis: Axis? = nil) {
        self.titleKey = titleKey
        self._text = text
        self.axis = axis
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            if let axis = axis {
                TextField(titleKey, text: $text, axis: axis)
            } else {
                TextField(titleKey, text: $text)
            }
        } else {
            TextField(titleKey, text: $text)
        }
    }
}

// MARK: - Grid Compatibility
@available(iOS 15.0, *)
struct GridCompat<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            Grid {
                content
            }
        } else {
            VStack {
                content
            }
        }
    }
}

@available(iOS 15.0, *)
struct GridRowCompat<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            GridRow {
                content
            }
        } else {
            HStack {
                content
            }
        }
    }
}

// MARK: - Chart Compatibility (Fallback to simple views)
@available(iOS 15.0, *)
struct ChartCompat<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            // Import Charts framework would be needed here
            // For now, show fallback
            VStack {
                Text("Chart Placeholder")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 100)
            }
        } else {
            VStack {
                Text("Chart Placeholder")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 100)
            }
        }
    }
}