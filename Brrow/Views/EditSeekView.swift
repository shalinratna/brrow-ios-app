//
//  EditSeekView.swift
//  Brrow
//
//  Edit existing seek functionality
//

import SwiftUI
import PhotosUI

// NOTE: EditSeekView temporarily disabled due to Seek model incompatibility
// This view needs to be updated to match the actual Seek model structure
struct EditSeekView: View {
    var body: some View {
        Text("Edit Seek functionality coming soon")
            .padding()
    }
}

// Original implementation commented out for build compatibility
/*
struct EditSeekView_Original: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = EditSeekViewModel()
    
    let seek: Seek
    
    // Form fields
    @State private var title: String
    @State private var description: String
    @State private var category: String
    @State private var budgetMin: String
    @State private var budgetMax: String
    @State private var urgency: String
    @State private var location: String
    @State private var duration: String
    @State private var specificRequirements: String
    
    // Images
    @State private var existingImages: [String]
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var newImages: [UIImage] = []
    @State private var imagesToDelete: Set<String> = []
    @State private var showingImagePicker = false
    
    // UI State
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showDeleteConfirmation = false
    @State private var showSuccessAlert = false
    
    init(seek: Seek) {
        self.seek = seek
        self._title = State(initialValue: seek.title)
        self._description = State(initialValue: seek.description)
        self._category = State(initialValue: seek.category)
        self._budgetMin = State(initialValue: String(format: "%.2f", seek.budgetMin ?? 0))
        self._budgetMax = State(initialValue: String(format: "%.2f", seek.budgetMax ?? 0))
        self._urgency = State(initialValue: seek.urgency ?? "normal")
        self._location = State(initialValue: seek.location)
        self._duration = State(initialValue: seek.duration ?? "")
        self._specificRequirements = State(initialValue: seek.specificRequirements ?? "")
        self._existingImages = State(initialValue: seek.images ?? [])
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Images Section
                    imagesSection
                    
                    // Basic Information
                    basicInfoSection
                    
                    // Budget Section
                    budgetSection
                    
                    // Details Section
                    detailsSection
                    
                    // Requirements Section
                    requirementsSection
                    
                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Edit Seek")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(isLoading || !hasChanges())
                }
            }
            .photosPicker(
                isPresented: $showingImagePicker,
                selection: $selectedImages,
                maxSelectionCount: 5,
                matching: .images
            )
            .onChange(of: selectedImages) { _, items in
                loadSelectedImages(items)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Delete Seek", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteSeek()
                }
            } message: {
                Text("Are you sure you want to delete this seek? This action cannot be undone.")
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Your seek has been updated successfully!")
            }
            .overlay {
                if isLoading {
                    ProgressView("Saving...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var imagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos (Optional)")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Existing images
                    ForEach(existingImages, id: \.self) { imageUrl in
                        if !imagesToDelete.contains(imageUrl) {
                            ZStack(alignment: .topTrailing) {
                                AsyncImage(url: URL(string: imageUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .overlay(ProgressView())
                                }
                                .frame(width: 100, height: 100)
                                .cornerRadius(10)
                                
                                Button(action: {
                                    imagesToDelete.insert(imageUrl)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .background(Color.white.clipShape(Circle()))
                                }
                                .offset(x: 5, y: -5)
                            }
                        }
                    }
                    
                    // New images
                    ForEach(Array(newImages.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .cornerRadius(10)
                            
                            Button(action: {
                                newImages.remove(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .background(Color.white.clipShape(Circle()))
                            }
                            .offset(x: 5, y: -5)
                        }
                    }
                    
                    // Add photo button
                    if totalImageCount() < 5 {
                        Button(action: { showingImagePicker = true }) {
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 30))
                                Text("Add Photo")
                                    .font(.caption)
                            }
                            .foregroundColor(.gray)
                            .frame(width: 100, height: 100)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
            }
            
            Text("\(totalImageCount())/5 photos")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.caption)
                    .foregroundColor(.gray)
                TextField("What are you looking for?", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.caption)
                    .foregroundColor(.gray)
                TextEditor(text: $description)
                    .frame(minHeight: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.caption)
                    .foregroundColor(.gray)
                Picker("Category", selection: $category) {
                    ForEach(["Electronics", "Tools", "Furniture", "Appliances", "Sports", "Outdoor", "Party", "Clothing", "Toys", "Other"], id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Range")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Minimum")
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack {
                        Text("$")
                        TextField("0.00", text: $budgetMin)
                            .keyboardType(.decimalPad)
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Text("to")
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Maximum")
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack {
                        Text("$")
                        TextField("0.00", text: $budgetMax)
                            .keyboardType(.decimalPad)
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Urgency")
                    .font(.caption)
                    .foregroundColor(.gray)
                Picker("Urgency", selection: $urgency) {
                    Text("Low").tag("low")
                    Text("Normal").tag("normal")
                    Text("High").tag("high")
                    Text("Urgent").tag("urgent")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Location")
                    .font(.caption)
                    .foregroundColor(.gray)
                TextField("City, State", text: $location)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration Needed")
                    .font(.caption)
                    .foregroundColor(.gray)
                TextField("e.g., 1 day, 1 week, 1 month", text: $duration)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
    
    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Specific Requirements (Optional)")
                .font(.headline)
            
            TextEditor(text: $specificRequirements)
                .frame(minHeight: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: saveChanges) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Changes")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isLoading || !hasChanges())
            
            Button(action: { showDeleteConfirmation = true }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete Seek")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(10)
            }
            .disabled(isLoading)
        }
    }
    
    // MARK: - Helper Methods
    
    private func totalImageCount() -> Int {
        let existingCount = existingImages.count - imagesToDelete.count
        return existingCount + newImages.count
    }
    
    private func hasChanges() -> Bool {
        return title != seek.title ||
               description != seek.description ||
               category != seek.category ||
               budgetMin != String(format: "%.2f", seek.budgetMin ?? 0) ||
               budgetMax != String(format: "%.2f", seek.budgetMax ?? 0) ||
               urgency != (seek.urgency ?? "normal") ||
               location != seek.location ||
               duration != (seek.duration ?? "") ||
               specificRequirements != (seek.specificRequirements ?? "") ||
               !imagesToDelete.isEmpty ||
               !newImages.isEmpty
    }
    
    private func loadSelectedImages(_ items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        newImages.append(image)
                    }
                }
            }
            selectedImages = []
        }
    }
    
    private func saveChanges() {
        guard !isLoading else { return }
        
        isLoading = true
        
        Task {
            do {
                var updates: [String: Any] = [
                    "seek_id": seek.id
                ]
                
                // Add changed fields
                if title != seek.title { updates["title"] = title }
                if description != seek.description { updates["description"] = description }
                if category != seek.category { updates["category"] = category }
                if location != seek.location { updates["location"] = location }
                if duration != (seek.duration ?? "") { updates["duration"] = duration }
                if specificRequirements != (seek.specificRequirements ?? "") {
                    updates["specific_requirements"] = specificRequirements
                }
                if urgency != (seek.urgency ?? "normal") { updates["urgency"] = urgency }
                
                // Handle budget
                if let minBudget = Double(budgetMin), minBudget != (seek.budgetMin ?? 0) {
                    updates["budget_min"] = minBudget
                }
                if let maxBudget = Double(budgetMax), maxBudget != (seek.budgetMax ?? 0) {
                    updates["budget_max"] = maxBudget
                }
                
                // Handle images if changed
                if !newImages.isEmpty || !imagesToDelete.isEmpty {
                    var imageData: [String] = []
                    
                    // Convert new images to base64
                    for image in newImages {
                        if let data = image.jpegData(compressionQuality: 0.8) {
                            imageData.append(data.base64EncodedString())
                        }
                    }
                    
                    if !imageData.isEmpty {
                        updates["images"] = imageData
                        updates["replace_images"] = !imagesToDelete.isEmpty
                    }
                }
                
                // Add coordinates if available
                // Note: In a real app, you'd get these from location services
                updates["latitude"] = seek.latitude
                updates["longitude"] = seek.longitude
                
                // Call API to update seek
                let _ = try await APIClient.shared.updateSeek(
                    seekId: seek.id,
                    updates: updates
                )
                
                await MainActor.run {
                    isLoading = false
                    showSuccessAlert = true
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func deleteSeek() {
        guard !isLoading else { return }
        
        isLoading = true
        
        Task {
            do {
                try await APIClient.shared.deleteSeek(seekId: seek.id)
                
                await MainActor.run {
                    isLoading = false
                    presentationMode.wrappedValue.dismiss()
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}
*/

// MARK: - View Model
class EditSeekViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
}


// MARK: - Preview
struct EditSeekView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview temporarily disabled due to Seek model differences
        Text("Preview not available")
    }
}