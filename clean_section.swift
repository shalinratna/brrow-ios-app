    private var enhancedImagesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Photos")
                    .font(.headline)
                Spacer()
                Text("0/5")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Text("Image upload temporarily disabled")
                .foregroundColor(.gray)
                .italic()
        }
        .padding()
    }

    private var enhancedBasicInfoSection: some View {