import SwiftUI
import MapKit
import PhotosUI

struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct ModernCreateSeekView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EnhancedSeekCreationViewModel()
    @State private var currentSection = 0
    @State private var showLocationPicker = false
    @State private var showDatePicker = false
    @State private var animateHeader = false
    @State private var bounceAnimation = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isRemote = false
    @State private var timePreference = "Flexible"
    
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated gradient background
                AnimatedBackground()
                
                VStack(spacing: 0) {
                    // Custom navigation header
                    customHeader
                    
                    ScrollView {
                        VStack(spacing: 32) {
                            // Animated title section
                            titleSection
                                .padding(.top, 20)
                            
                            // What section with animated cards
                            whatSection

                            // Images section
                            imagesSection

                            // When section with calendar
                            whenSection
                            
                            // Where section with map
                            whereSection
                            
                            // Budget section with slider
                            budgetSection
                            
                            // Urgency section with animated selection
                            urgencySection
                            
                            // Create button
                            createButton
                                .padding(.bottom, 40)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showLocationPicker) {
                SeekLocationPickerView { location, latitude, longitude in
                    viewModel.updateLocation(location, latitude: latitude, longitude: longitude)
                }
            }
            .onAppear {
                startAnimations()
            }
            .onChange(of: viewModel.showSuccess) { showSuccess in
                if showSuccess {
                    HapticManager.notification(type: .success)
                    dismiss()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    private var customHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
            
            Text("Create Seek")
                .font(.headline)
                .scaleEffect(animateHeader ? 1.0 : 0.8)
                .opacity(animateHeader ? 1.0 : 0.0)
            
            Spacer()
            
            // Balance for symmetry
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private var titleSection: some View {
        VStack(spacing: 24) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.primary.opacity(0.2), Theme.Colors.primary.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(bounceAnimation ? 1.1 : 1.0)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundColor(Theme.Colors.primary)
                    .rotationEffect(.degrees(bounceAnimation ? 10 : -10))
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    bounceAnimation = true
                }
            }
            
            VStack(spacing: 8) {
                Text("What are you looking for?")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                
                Text("Create a seek and let others help you find it")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var whatSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("What do you need?", systemImage: "questionmark.circle.fill")
                .font(.headline)
                .foregroundColor(Theme.Colors.primary)
            
            // Title input with floating label
            FloatingLabelTextField(
                text: $viewModel.title,
                placeholder: "e.g., Professional photographer for wedding",
                title: "Title"
            )
            
            // Description with expanding text editor
            VStack(alignment: .leading, spacing: 8) {
                Label("Details", systemImage: "text.alignleft")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                    
                    TextEditor(text: $viewModel.description)
                        .padding(12)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 120)
                    
                    if viewModel.description.isEmpty {
                        Text("Describe what you're looking for in detail...")
                            .foregroundColor(.secondary.opacity(0.6))
                            .padding(16)
                            .allowsHitTesting(false)
                    }
                }
                .frame(minHeight: 120)
            }
            
            // Category cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(seekCategories, id: \.title) { seekCategory in
                        CategoryCard(
                            category: seekCategory,
                            isSelected: viewModel.category == seekCategory.title
                        ) {
                            withAnimation(.spring()) {
                                viewModel.category = seekCategory.title
                                HapticManager.impact(style: .light)
                            }
                        }
                    }
                }
            }
        }
    }

    private var imagesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Reference Photos", systemImage: "photo.on.rectangle")
                .font(.headline)
                .foregroundColor(Theme.Colors.primary)

            Text("Add photos to help others understand what you're looking for")
                .font(.caption)
                .foregroundColor(.secondary)

            // Image grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Selected images
                ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 80)
                            .clipped()
                            .cornerRadius(12)

                        Button(action: {
                            viewModel.removeImage(at: index)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(4)
                    }
                }

                // Add photo button
                if viewModel.selectedImages.count < 5 {
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 5 - viewModel.selectedImages.count, matching: .images) {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(Theme.Colors.primary)

                            Text("Add Photo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }

            if viewModel.isUploadingImages {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Uploading images...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .onChange(of: selectedItems) { newItems in
            Task {
                var newImages: [UIImage] = []
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        newImages.append(image)
                    }
                }
                await MainActor.run {
                    viewModel.addImages(newImages)
                    selectedItems.removeAll()
                }
            }
        }
    }

    private var whenSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("When do you need it?", systemImage: "calendar")
                .font(.headline)
                .foregroundColor(Theme.Colors.primary)
            
            // Date selector with visual calendar
            Button(action: { showDatePicker.toggle() }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Needed by")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.deadline, style: .date)
                            .font(.subheadline.weight(.medium))
                    }
                    
                    Spacer()
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.Colors.primary.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        VStack(spacing: 2) {
                            Text(dayOfMonth)
                                .font(.title2.bold())
                                .foregroundColor(Theme.Colors.primary)
                            
                            Text(monthName)
                                .font(.caption)
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheet(selectedDate: $viewModel.deadline)
            }
            
            // Time preference pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["Morning", "Afternoon", "Evening", "Flexible"], id: \.self) { time in
                        TimePill(
                            title: time,
                            isSelected: timePreference == time
                        ) {
                            timePreference = time
                        }
                    }
                }
            }
        }
    }
    
    private var whereSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Where?", systemImage: "location.fill")
                .font(.headline)
                .foregroundColor(Theme.Colors.primary)
            
            // Location selector with map preview
            Button(action: { showLocationPicker = true }) {
                VStack(spacing: 12) {
                    // Mini map preview
                    if let latitude = viewModel.latitude, let longitude = viewModel.longitude {
                        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        let annotations = [MapAnnotation(coordinate: coordinate)]

                        Map(coordinateRegion: .constant(MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )), annotationItems: annotations) { annotation in
                            MapPin(coordinate: annotation.coordinate, tint: Theme.Colors.primary)
                        }
                        .frame(height: 120)
                        .cornerRadius(12)
                        .disabled(true)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .frame(height: 120)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "map")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                
                                Text("Set location")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(Theme.Colors.primary)
                        
                        Text(viewModel.location.isEmpty ? "Choose location" : viewModel.location)
                            .font(.subheadline)
                            .foregroundColor(!viewModel.location.isEmpty ? .primary : .secondary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                }
            }
            
            // Remote option toggle
            Toggle(isOn: $isRemote) {
                HStack(spacing: 12) {
                    Image(systemName: "laptopcomputer")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Remote option available")
                            .font(.subheadline.weight(.medium))
                        
                        Text("This can be done remotely")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.primary))
        }
    }
    
    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Budget", systemImage: "dollarsign.circle.fill")
                .font(.headline)
                .foregroundColor(Theme.Colors.primary)
            
            // Interactive budget slider
            VStack(spacing: 24) {
                // Budget display
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.primary.opacity(0.1), Theme.Colors.primary.opacity(0.05)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 80)
                    
                    VStack(spacing: 4) {
                        Text(viewModel.formattedBudgetRange)
                            .font(.largeTitle.bold())
                            .foregroundColor(Theme.Colors.primary)
                            .contentTransition(.numericText())

                        Text(viewModel.hasBudgetRange ? "Budget range" : "Not specified")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Custom slider
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                        
                        // Fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.Colors.primary)
                            .frame(width: geometry.size.width * CGFloat((viewModel.maxBudget ?? 100) / 1000), height: 8)
                        
                        // Thumb
                        Circle()
                            .fill(Color.white)
                            .frame(width: 28, height: 28)
                            .shadow(color: .black.opacity(0.2), radius: 4)
                            .offset(x: geometry.size.width * CGFloat((viewModel.maxBudget ?? 100) / 1000) - 14)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let newValue = value.location.x / geometry.size.width * 1000
                                        viewModel.maxBudget = min(max(0, newValue), 1000)
                                        viewModel.hasBudgetRange = true
                                    }
                            )
                    }
                }
                .frame(height: 28)
                
                // Quick select amounts
                HStack {
                    ForEach([50, 100, 250, 500, 1000], id: \.self) { amount in
                        Button(action: {
                            withAnimation(.spring()) {
                                viewModel.maxBudget = Double(amount)
                                viewModel.hasBudgetRange = true
                            }
                        }) {
                            Text("$\(amount)")
                                .font(.caption.weight(.medium))
                                .foregroundColor(Int(viewModel.maxBudget ?? 0) == amount ? .white : Theme.Colors.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Int(viewModel.maxBudget ?? 0) == amount ? Theme.Colors.primary : Theme.Colors.primary.opacity(0.1))
                                )
                        }
                    }
                }
            }
        }
    }
    
    private var urgencySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("How urgent is this?", systemImage: "timer")
                .font(.headline)
                .foregroundColor(Theme.Colors.primary)
            
            // Urgency cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(SeekUrgency.allCases, id: \.self) { urgencyOption in
                    UrgencyCard(
                        urgency: urgencyOption,
                        isSelected: viewModel.urgency == urgencyOption
                    ) {
                        withAnimation(.spring()) {
                            viewModel.urgency = urgencyOption
                            HapticManager.impact(style: .medium)
                        }
                    }
                }
            }
        }
    }
    
    private var createButton: some View {
        Button(action: createSeek) {
            HStack {
                if viewModel.isCreating {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "magnifyingglass")
                }
                Text(viewModel.isCreating ? "Creating..." : "Create Seek")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 10, y: 5)
        }
        .disabled(!viewModel.canCreate || viewModel.isCreating)
        .opacity(viewModel.canCreate && !viewModel.isCreating ? 1.0 : 0.6)
    }
    
    
    private var dayOfMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: viewModel.deadline)
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: viewModel.deadline).uppercased()
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            animateHeader = true
        }
    }
    
    private func createSeek() {
        viewModel.createSeek()
    }
}

// MARK: - Supporting Views

struct AnimatedBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Theme.Colors.primary.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            GeometryReader { geometry in
                ForEach(0..<5) { i in
                    Circle()
                        .fill(Theme.Colors.primary.opacity(0.05))
                        .frame(width: CGFloat.random(in: 100...300))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .blur(radius: 50)
                        .offset(y: animate ? -50 : 50)
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 5...10))
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.2),
                            value: animate
                        )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            animate = true
        }
    }
}

struct FloatingLabelTextField: View {
    @Binding var text: String
    let placeholder: String
    let title: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isFocused ? Theme.Colors.primary : Color.clear, lineWidth: 2)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(isFocused ? Theme.Colors.primary : .secondary)
                    .offset(y: text.isEmpty && !isFocused ? 18 : 0)
                    .scaleEffect(text.isEmpty && !isFocused ? 1.2 : 1.0, anchor: .leading)

                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .font(.body)
                    .padding(.top, text.isEmpty && !isFocused ? 0 : 14)
                    .opacity(text.isEmpty && !isFocused ? 0 : 1)  // Hide placeholder when title label is in placeholder position
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .animation(.spring(response: 0.3), value: isFocused)
            .animation(.spring(response: 0.3), value: text.isEmpty)
        }
        .frame(height: 60)
    }
}

struct CategoryCard: View {
    let category: SeekCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(category.color)
                        .scaleEffect(isSelected ? 1.2 : 1.0)
                }
                
                Text(category.title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(isSelected ? category.color : .secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? category.color.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct TimePill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Theme.Colors.primary : Color(.systemGray6))
                )
        }
    }
}

struct UrgencyCard: View {
    let urgency: SeekUrgency
    let isSelected: Bool
    let action: () -> Void
    @State private var pulse = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(urgency.color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    if isSelected && urgency == .urgent {
                        Circle()
                            .stroke(urgency.color, lineWidth: 2)
                            .frame(width: 50, height: 50)
                            .scaleEffect(pulse ? 1.3 : 1.0)
                            .opacity(pulse ? 0 : 1)
                            .animation(
                                Animation.easeOut(duration: 1)
                                    .repeatForever(autoreverses: false),
                                value: pulse
                            )
                    }
                    
                    Image(systemName: urgency.icon)
                        .font(.title3)
                        .foregroundColor(urgency.color)
                }
                
                VStack(spacing: 4) {
                    Text(urgency.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isSelected ? urgency.color : .primary)
                    
                    Text(urgency.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? urgency.color.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? urgency.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            if urgency == .urgent {
                pulse = true
            }
        }
    }
}

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SeekLocationPickerView: View {
    let onLocationSelected: (String, Double, Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region, showsUserLocation: true)
                .ignoresSafeArea()
                .overlay(
                    Image(systemName: "mappin")
                        .font(.largeTitle)
                        .foregroundColor(Theme.Colors.primary)
                        .shadow(radius: 3)
                )
                .navigationTitle("Select Location")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Select") {
                            onLocationSelected(
                                "Selected Location",
                                region.center.latitude,
                                region.center.longitude
                            )
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
        }
    }
}

// Supporting models
struct SeekCategory {
    let icon: String
    let title: String
    let color: Color
}

let seekCategories = [
    SeekCategory(icon: "camera.fill", title: "Photography", color: .purple),
    SeekCategory(icon: "paintbrush.fill", title: "Design", color: .pink),
    SeekCategory(icon: "wrench.fill", title: "Repair", color: .orange),
    SeekCategory(icon: "car.fill", title: "Transport", color: .blue),
    SeekCategory(icon: "house.fill", title: "Home", color: .green),
    SeekCategory(icon: "ellipsis", title: "Other", color: .gray)
]

// Location model placeholder for seek
struct SeekLocation: Identifiable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    let address: String
}


// MARK: - Preview

struct ModernCreateSeekView_Previews: PreviewProvider {
    static var previews: some View {
        ModernCreateSeekView()
    }
}