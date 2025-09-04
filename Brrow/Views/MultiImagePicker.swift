//
//  MultiImagePicker.swift
//  Brrow
//
//  Multi-image picker for garage sales
//

import SwiftUI
import PhotosUI

struct MultiImagePicker: View {
    @Binding var selectedImages: [UIImage]
    let maxSelection: Int
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItems: [PhotosPickerItem] = []
    
    var body: some View {
        NavigationView {
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: maxSelection,
                matching: .images
            ) {
                VStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Select up to \(maxSelection) photos")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onChange(of: selectedItems) { items in
                Task {
                    selectedImages = []
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImages.append(image)
                        }
                    }
                    dismiss()
                }
            }
            .navigationTitle("Select Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}