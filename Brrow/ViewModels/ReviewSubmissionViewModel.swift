//
//  ReviewSubmissionViewModel.swift
//  Brrow
//
//  ViewModel for handling review submission and validation
//

import Foundation
import SwiftUI

@MainActor
class ReviewSubmissionViewModel: ObservableObject {
    @Published var isSubmitting = false
    @Published var submitSuccess = false
    @Published var errorMessage: String?

    private let reviewService = ReviewService.shared

    func submitReview(_ request: CreateReviewRequest) async throws {
        isSubmitting = true
        errorMessage = nil

        do {
            let review = try await reviewService.submitReview(request)
            submitSuccess = true
            print("✅ Review submitted successfully: \(review.id)")
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }

        isSubmitting = false
    }

    func validateReview(rating: Int, content: String, requiredCriteria: [String]) -> Bool {
        guard rating > 0 && rating <= 5 else { return false }
        guard content.count >= 10 else { return false }
        return true
    }

    func resetForm() {
        isSubmitting = false
        submitSuccess = false
        errorMessage = nil
    }
}