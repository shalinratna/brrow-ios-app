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
    
    var icon: String {
        switch self {
        case .createListing: return "plus.circle.fill"
        case .search: return "magnifyingglass.circle.fill"
        case .garageSale: return "house.circle.fill"
        case .seek: return "eye.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .createListing: return Color(red: 0.2, green: 0.8, blue: 0.4) // Vibrant green
        case .search: return Color(red: 0.1, green: 0.5, blue: 0.9) // Vibrant blue
        case .garageSale: return Color(red: 1.0, green: 0.6, blue: 0.1) // Vibrant orange
        case .seek: return Color(red: 0.7, green: 0.3, blue: 0.9) // Vibrant purple
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
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [item.color.opacity(0.95), item.color.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: item.color.opacity(0.4), radius: 8, x: 0, y: 4)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            
            // Icon button
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(item.color)
                        .frame(width: 55, height: 55) // Slightly larger
                        .shadow(color: item.color.opacity(0.6), radius: 12, x: 0, y: 6) // More prominent shadow
                        .shadow(color: item.color.opacity(0.3), radius: 20, x: 0, y: 10) // Additional glow effect

                    Image(systemName: item.icon)
                        .font(.system(size: 22, weight: .bold)) // Slightly larger and bolder
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1) // Icon shadow for contrast
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
                        showSeek: $showSeek
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
    }
}

// MARK: - View Extension
extension View {
    func quickActionsOverlay() -> some View {
        self.modifier(QuickActionsOverlay())
    }
}