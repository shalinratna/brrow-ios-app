//
//  SpecialRequestsView.swift
//  Brrow
//
//  Special requests input for bookings
//

import SwiftUI

struct SpecialRequestsView: View {
    @Binding var requests: String
    @Environment(\.dismiss) private var dismiss

    @State private var localText: String = ""

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Special Requests")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Let the owner know if you need anything specific or have questions about the item.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your message (optional)")
                        .font(.headline)

                    TextEditor(text: $localText)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .textInputAutocapitalization(.sentences)

                    HStack {
                        Spacer()
                        Text("\(localText.count)/500")
                            .font(.caption)
                            .foregroundColor(localText.count > 500 ? .red : .secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Common requests:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(commonRequests, id: \.self) { request in
                            Button {
                                if localText.isEmpty {
                                    localText = request
                                } else {
                                    localText += "\n\n" + request
                                }
                            } label: {
                                Text(request)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(16)
                                    .lineLimit(2)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }

                Spacer()

                Button {
                    requests = localText
                    dismiss()
                } label: {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .font(.headline)
                }
            }
            .padding()
            .navigationTitle("Special Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            })
            .onAppear {
                localText = requests
            }
            .onChange(of: localText) { newValue in
                if newValue.count > 500 {
                    localText = String(newValue.prefix(500))
                }
            }
        }
    }

    private let commonRequests = [
        "Please include any accessories",
        "I need pickup instructions",
        "Can we arrange a different time?",
        "Do you offer delivery?",
        "I'm a first-time renter",
        "Can you provide a brief tutorial?",
        "I need this for a special event",
        "Please include the manual"
    ]
}

// MARK: - Preview

struct SpecialRequestsView_Previews: PreviewProvider {
    static var previews: some View {
        SpecialRequestsView(requests: .constant(""))
    }
}