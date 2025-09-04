//
//  QuickActionsButton.swift
//  Brrow
//
//  Floating quick actions button for easy access to common features
//

import SwiftUI

struct QuickActionsButton: View {
    @State private var isExpanded = false
    @State private var selectedAction: QuickActionItem? = nil
    @Binding var showCreateListing: Bool
    @Binding var showGarageSale: Bool
    @Binding var showSeek: Bool
    @Binding var showCalculator: Bool
    
    // Animation states
    @State private var animateButtons = false
    @State private var rotateMainButton = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Backdrop when expanded
            if isExpanded {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isExpanded = false
                            animateButtons = false
                        }
                    }
            }
            
            // Quick action buttons
            if isExpanded {
                VStack(alignment: .trailing, spacing: 12) {
                    ForEach(QuickActionItem.allCases, id: \.self) { item in
                        QuickActionButtonItem(
                            item: item,
                            isExpanded: isExpanded,
                            animateButtons: animateButtons,
                            action: {
                                handleAction(item)
                            }
                        )
                        .scaleEffect(animateButtons ? 1 : 0.1)
                        .opacity(animateButtons ? 1 : 0)
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.7)
                            .delay(Double(item.index) * 0.05),
                            value: animateButtons
                        )
                    }
                }
                .padding(.bottom, 80)
                .padding(.trailing, 8)
            }
            
            // Main floating button
            Button(action: toggleExpanded) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primary)
                        .frame(width: 60, height: 60)
                        .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                    
                    Image(systemName: isExpanded ? "xmark" : "bolt.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(rotateMainButton ? 180 : 0))
                }
            }
            .scaleEffect(isExpanded ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isExpanded)
        }
    }
    
    private func toggleExpanded() {
        withAnimation(.spring()) {
            isExpanded.toggle()
            rotateMainButton.toggle()
        }
        
        if isExpanded {
            // Delay the button animations slightly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    animateButtons = true
                }
            }
        } else {
            animateButtons = false
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func handleAction(_ item: QuickActionItem) {
        // Close the menu
        withAnimation(.spring()) {
            isExpanded = false
            animateButtons = false
        }
        
        // Perform the action
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            switch item {
            case .createListing:
                showCreateListing = true
            case .search:
                TabSelectionManager.shared.switchToMarketplaceWithSearch()
            case .garageSale:
                showGarageSale = true
            case .seek:
                showSeek = true
            case .calculator:
                showCalculator = true
            }
        }
    }
}

// MARK: - Quick Action Item
enum QuickActionItem: String, CaseIterable {
    case createListing = "List Item"
    case search = "Search"
    case garageSale = "Garage Sale"
    case seek = "Create Seek"
    case calculator = "Calculator"
    
    var icon: String {
        switch self {
        case .createListing: return "plus.circle.fill"
        case .search: return "magnifyingglass.circle.fill"
        case .garageSale: return "house.circle.fill"
        case .seek: return "eye.circle.fill"
        case .calculator: return "number.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .createListing: return Theme.Colors.primary
        case .search: return Color.blue
        case .garageSale: return Color.orange
        case .seek: return Color.purple
        case .calculator: return Color.pink
        }
    }
    
    var index: Int {
        QuickActionItem.allCases.firstIndex(of: self) ?? 0
    }
}

// MARK: - Quick Action Button Item
struct QuickActionButtonItem: View {
    let item: QuickActionItem
    let isExpanded: Bool
    let animateButtons: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Label
            if isExpanded && animateButtons {
                Text(item.rawValue)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            
            // Icon button
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(item.color)
                        .frame(width: 50, height: 50)
                        .shadow(color: item.color.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }, perform: {})
        }
    }
}

// MARK: - Quick Actions Overlay Modifier
struct QuickActionsOverlay: ViewModifier {
    @State private var showCreateListing = false
    @State private var showGarageSale = false
    @State private var showSeek = false
    @State private var showCalculator = false
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    QuickActionsButton(
                        showCreateListing: $showCreateListing,
                        showGarageSale: $showGarageSale,
                        showSeek: $showSeek,
                        showCalculator: $showCalculator
                    )
                    .padding(.trailing, 20)
                    .padding(.bottom, 90) // Above tab bar
                }
            }
        }
        .sheet(isPresented: $showCreateListing) {
            NavigationView {
                ModernPostCreationView(onListingCreated: { listingId in
                    // Navigation will be handled by the parent view that has access to navigation manager
                    print("Listing created with ID: \(listingId)")
                })
            }
        }
        .sheet(isPresented: $showGarageSale) {
            NavigationView {
                ModernCreateGarageSaleView()
            }
        }
        .sheet(isPresented: $showSeek) {
            NavigationView {
                CreateSeekView()
            }
        }
        .sheet(isPresented: $showCalculator) {
            Text("Calculator Coming Soon!")
                .font(.title)
                .padding()
        }
    }
}

// MARK: - View Extension
extension View {
    func quickActionsOverlay() -> some View {
        self.modifier(QuickActionsOverlay())
    }
}