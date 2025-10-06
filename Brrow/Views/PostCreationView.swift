//
//  PostCreationView.swift
//  Brrow
//
//  Create New Listing or Seek Post
//

import SwiftUI
import PhotosUI

struct PostCreationView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = PostCreationViewModel()
    @State private var selectedTab = 0
    @State private var showingPhotoPicker = false
    @State private var selectedImages: [PhotosPickerItem] = []
    
    private let tabs = ["List Item", "Post Seek"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                tabSelector
                
                // Content
                TabView(selection: $selectedTab) {
                    // List Item Tab
                    createListingView
                        .tag(0)
                    
                    // Post Seek Tab
                    createSeekView
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(Theme.Colors.background)
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        Task {
                            await viewModel.createPost(type: selectedTab == 0 ? .listing : .seek)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.canPost)
                }
            }
            .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedImages, maxSelectionCount: 5, matching: .images)
            .onChange(of: selectedImages) { newItems in
                viewModel.loadImages(from: newItems)
            }
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(selectedTab == index ? Theme.Colors.primary : Theme.Colors.secondaryText)
                        
                        Rectangle()
                            .fill(selectedTab == index ? Theme.Colors.primary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .background(Theme.Colors.surface)
    }
    
    // MARK: - Create Listing View
    private var createListingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                // Photos section
                photosSection
                
                // Basic info
                basicInfoSection
                
                // Pricing
                pricingSection
                
                // Location & availability
                locationSection
            }
            .padding(Theme.Spacing.lg)
        }
    }
    
    // MARK: - Create Seek View
    private var createSeekView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                // What I need
                seekInfoSection
                
                // AI suggestions
                if !viewModel.aiSuggestions.isEmpty {
                    aiSuggestionsSection
                }
                
                // Budget & timeline
                seekBudgetSection
            }
            .padding(Theme.Spacing.lg)
        }
    }
    
    // MARK: - Sections
    
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Photos")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Add photo button
                    Button(action: { showingPhotoPicker = true }) {
                        VStack {
                            Image(systemName: "plus")
                                .font(.system(size: 24))
                                .foregroundColor(Theme.Colors.primary)
                            
                            Text("Add Photos")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.primary)
                        }
                        .frame(width: 100, height: 100)
                        .background(Theme.Colors.primary.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.Colors.primary, style: StrokeStyle(lineWidth: 2, dash: [5]))
                        )
                    }
                    
                    // Selected photos
                    ForEach(Array(viewModel.selectedPhotos.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .cornerRadius(12)
                                .clipped()
                            
                            Button(action: {
                                viewModel.removePhoto(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(10)
                            }
                            .offset(x: -5, y: 5)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Basic Information")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            VStack(spacing: Theme.Spacing.md) {
                textField("Title", text: $viewModel.title, placeholder: "What are you lending?")
                textField("Description", text: $viewModel.description, placeholder: "Describe your item...", isMultiline: true)
                
                // Category picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                    
                    Menu {
                        ForEach(viewModel.categories, id: \.self) { category in
                            Button(category) {
                                viewModel.selectedCategory = category
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedCategory)
                                .foregroundColor(Theme.Colors.text)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                        .padding(Theme.Spacing.md)
                        .background(Theme.Colors.surface)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Pricing")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            VStack(spacing: Theme.Spacing.md) {
                Toggle("Free to borrow", isOn: $viewModel.isFree)
                    .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.primary))
                
                if !viewModel.isFree {
                    HStack {
                        Text("$")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Theme.Colors.text)
                        
                        TextField("0.00", text: $viewModel.price)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 18))
                        
                        Text("per day")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.surface)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Location & Availability")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            VStack(spacing: Theme.Spacing.md) {
                textField("Location", text: $viewModel.location, placeholder: "Where can people pick this up?")
                
                Toggle("Available immediately", isOn: $viewModel.availableNow)
                    .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.primary))
                
                if !viewModel.availableNow {
                    DatePicker("Available from", selection: $viewModel.availableDate, displayedComponents: .date)
                }
            }
        }
    }
    
    private var seekInfoSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("What do you need?")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            VStack(spacing: Theme.Spacing.md) {
                textField("Item needed", text: $viewModel.seekTitle, placeholder: "What are you looking for?")
                textField("Description", text: $viewModel.seekDescription, placeholder: "Describe what you need and when...", isMultiline: true)
                    .onChange(of: viewModel.seekDescription) { _ in
                        viewModel.generateAISuggestions()
                    }
            }
        }
    }
    
    private var aiSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(Theme.Colors.primary)
                Text("AI Suggestions")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.text)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(viewModel.aiSuggestions, id: \.self) { suggestion in
                    Button(action: {
                        viewModel.applySuggestion(suggestion)
                    }) {
                        Text(suggestion)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.Colors.primary.opacity(0.1))
                            .cornerRadius(16)
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.primary.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var seekBudgetSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Budget & Timeline")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.text)
            
            VStack(spacing: Theme.Spacing.md) {
                HStack {
                    Text("Max budget: $")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.text)
                    
                    TextField("0.00", text: $viewModel.maxBudget)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 16))
                    
                    Text("per day")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.surface)
                .cornerRadius(12)
                
                DatePicker("Needed by", selection: $viewModel.neededBy, displayedComponents: .date)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func textField(_ title: String, text: Binding<String>, placeholder: String, isMultiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.text)
            
            if isMultiline {
                TextEditor(text: text)
                    .frame(minHeight: 80)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.surface)
                    .cornerRadius(12)
            } else {
                TextField(placeholder, text: text)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.surface)
                    .cornerRadius(12)
            }
        }
    }
}

#Preview {
    PostCreationView()
}