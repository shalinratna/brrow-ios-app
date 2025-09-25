//
//  EditGarageSaleView.swift
//  Brrow
//
//  Edit existing garage sale functionality
//

import SwiftUI
import PhotosUI

struct StandaloneEditGarageSaleView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = EditGarageSaleViewModel()
    
    let garageSale: GarageSale
    
    // Form fields
    @State private var title: String
    @State private var description: String
    @State private var address: String
    @State private var saleDate: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var tags: Set<String>
    
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
    
    init(garageSale: GarageSale) {
        self.garageSale = garageSale
        self._title = State(initialValue: garageSale.title)
        self._description = State(initialValue: garageSale.description ?? "")
        self._address = State(initialValue: garageSale.address ?? "")
        
        // Parse dates from strings
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self._saleDate = State(initialValue: formatter.date(from: garageSale.saleDate) ?? Date())
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        self._startTime = State(initialValue: timeFormatter.date(from: garageSale.startTime) ?? Date())
        self._endTime = State(initialValue: timeFormatter.date(from: garageSale.endTime) ?? Date())
        
        self._tags = State(initialValue: Set(garageSale.tags))
        self._existingImages = State(initialValue: garageSale.images)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Images Section
                    imagesSection
                    
                    // Basic Information
                    basicInfoSection
                    
                    // Date & Time Section
                    dateTimeSection
                    
                    // Categories Section
                    categoriesSection
                    
                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Edit Garage Sale")
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
                maxSelectionCount: 10,
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
            .alert("Delete Garage Sale", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteGarageSale()
                }
            } message: {
                Text("Are you sure you want to delete this garage sale? This action cannot be undone.")
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Your garage sale has been updated successfully!")
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
            Text("Photos")
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
                    if totalImageCount() < 10 {
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
            
            Text("\(totalImageCount())/10 photos")
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
                TextField("Garage Sale Title", text: $title)
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
                Text("Address")
                    .font(.caption)
                    .foregroundColor(.gray)
                TextField("Full address", text: $address)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Date & Time")
                .font(.headline)
            
            DatePicker("Sale Date", selection: $saleDate, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Start Time")
                        .font(.caption)
                        .foregroundColor(.gray)
                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("End Time")
                        .font(.caption)
                        .foregroundColor(.gray)
                    DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
        }
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                ForEach(["Furniture", "Clothing", "Electronics", "Toys", "Books", "Antiques", "Tools", "Household", "Sports", "Jewelry"], id: \.self) { tag in
                    Button(action: {
                        if tags.contains(tag) {
                            tags.remove(tag)
                        } else {
                            tags.insert(tag)
                        }
                    }) {
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(tags.contains(tag) ? Theme.Colors.primary : Color.gray.opacity(0.2))
                            .foregroundColor(tags.contains(tag) ? .white : Theme.Colors.text)
                            .cornerRadius(15)
                    }
                }
            }
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
                    Text("Delete Garage Sale")
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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        
        let originalSaleDate = formatter.date(from: garageSale.saleDate) ?? Date()
        let originalStartTime = timeFormatter.date(from: garageSale.startTime) ?? Date()
        let originalEndTime = timeFormatter.date(from: garageSale.endTime) ?? Date()
        
        return title != garageSale.title ||
               description != (garageSale.description ?? "") ||
               address != (garageSale.address ?? "") ||
               saleDate != originalSaleDate ||
               startTime != originalStartTime ||
               endTime != originalEndTime ||
               tags != Set(garageSale.tags) ||
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
                    "sale_id": garageSale.id
                ]
                
                // Add changed fields
                if title != garageSale.title { updates["title"] = title }
                if description != (garageSale.description ?? "") { updates["description"] = description }
                if address != (garageSale.address ?? "") { updates["address"] = address }
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm:ss"
                
                let originalSaleDate = formatter.date(from: garageSale.saleDate) ?? Date()
                if saleDate != originalSaleDate {
                    updates["sale_date"] = formatter.string(from: saleDate)
                }
                
                let originalStartTime = timeFormatter.date(from: garageSale.startTime) ?? Date()
                if startTime != originalStartTime {
                    updates["start_time"] = timeFormatter.string(from: startTime)
                }
                
                let originalEndTime = timeFormatter.date(from: garageSale.endTime) ?? Date()
                if endTime != originalEndTime {
                    updates["end_time"] = timeFormatter.string(from: endTime)
                }
                
                // Update tags
                if tags != Set(garageSale.tags) {
                    updates["tags"] = Array(tags)
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
                
                // Call API to update garage sale
                let _ = try await APIClient.shared.updateGarageSale(
                    saleId: String(garageSale.id),
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
    
    private func deleteGarageSale() {
        guard !isLoading else { return }
        
        isLoading = true
        
        Task {
            do {
                try await APIClient.shared.deleteGarageSale(saleId: String(garageSale.id))
                
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

// MARK: - View Model
class EditGarageSaleViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
}


// MARK: - Preview
struct EditGarageSaleView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview temporarily disabled due to complex GarageSale model
        Text("Preview not available")
    }
}