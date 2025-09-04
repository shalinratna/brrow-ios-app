//
//  TestLaunchView.swift
//  Brrow
//
//  Simple test view to verify app launches
//

import SwiftUI

struct TestLaunchView: View {
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("🎉 App Launched Successfully!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Brrow is ready for production")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding(.top, 20)
                }
            }
            .padding()
        }
        .onAppear {
            // Simulate loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isLoading = false
            }
        }
    }
}

#Preview {
    TestLaunchView()
}