import Foundation
import Combine
import SwiftUI

@MainActor
class OffersViewModel: ObservableObject {
    @Published var receivedOffers: [Offer] = []
    @Published var sentOffers: [Offer] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTab = 0 // 0: Received, 1: Sent
    
    private var cancellables = Set<AnyCancellable>()
    private let apiClient = APIClient.shared
    private let authManager = AuthManager.shared
    
    init() {
        fetchOffers()
        setupNotificationObserver()
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.publisher(for: .offerStatusChanged)
            .sink { [weak self] notification in
                if let offerId = notification.object as? Int {
                    self?.refreshOfferStatus(offerId: offerId)
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchOffers() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                async let received = apiClient.fetchReceivedOffers()
                async let sent = apiClient.fetchSentOffers()
                
                let (receivedOffers, sentOffers) = try await (received, sent)
                
                await MainActor.run {
                    self.receivedOffers = receivedOffers.sorted { $0.createdAt > $1.createdAt }
                    self.sentOffers = sentOffers.sorted { $0.createdAt > $1.createdAt }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func preloadContent() async {
        // Check if we already have data to avoid unnecessary loading
        if !receivedOffers.isEmpty || !sentOffers.isEmpty {
            return
        }
        
        // Preload offers silently in background
        do {
            async let received = apiClient.fetchReceivedOffers()
            async let sent = apiClient.fetchSentOffers()
            
            let (receivedOffers, sentOffers) = try await (received, sent)
            
            self.receivedOffers = receivedOffers.sorted { $0.createdAt > $1.createdAt }
            self.sentOffers = sentOffers.sorted { $0.createdAt > $1.createdAt }
        } catch {
            // Silently handle errors during preloading
            print("Failed to preload offers: \(error.localizedDescription)")
        }
    }
    
    func acceptOffer(_ offer: Offer) {
        updateOfferStatus(offer, status: .accepted)
    }
    
    func rejectOffer(_ offer: Offer) {
        updateOfferStatus(offer, status: .rejected)
    }
    
    func cancelOffer(_ offer: Offer) {
        updateOfferStatus(offer, status: .cancelled)
    }
    
    private func updateOfferStatus(_ offer: Offer, status: OfferStatus) {
        Task {
            do {
                let updatedOffer = try await apiClient.updateOfferStatus(
                    offerId: offer.id,
                    status: status
                )
                
                await MainActor.run {
                    self.updateOfferInLists(updatedOffer)
                    
                    // If offer was accepted, create transaction
                    if status == .accepted {
                        self.createTransaction(from: updatedOffer)
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func updateOfferInLists(_ updatedOffer: Offer) {
        if let index = receivedOffers.firstIndex(where: { $0.id == updatedOffer.id }) {
            receivedOffers[index] = updatedOffer
        }
        if let index = sentOffers.firstIndex(where: { $0.id == updatedOffer.id }) {
            sentOffers[index] = updatedOffer
        }
    }
    
    private func createTransaction(from offer: Offer) {
        Task {
            do {
                let transaction = Transaction(
                    id: 0,
                    offerId: offer.id,
                    listingId: offer.listingId,
                    borrowerId: offer.borrowerId,
                    lenderId: offer.listing?.ownerId ?? 0,
                    startDate: Date(),
                    endDate: Calendar.current.date(byAdding: .day, value: offer.duration ?? 1, to: Date()) ?? Date(),
                    actualReturnDate: nil,
                    totalCost: offer.amount,
                    securityDeposit: nil,
                    status: .pending,
                    paymentStatus: "unpaid",
                    createdAt: Date(),
                    updatedAt: nil,
                    notes: nil,
                    rating: nil,
                    review: nil
                )
                
                try await apiClient.createTransaction(transaction)
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func refreshOfferStatus(offerId: Int) {
        Task {
            do {
                let updatedOffer = try await apiClient.fetchOfferDetails(id: offerId)
                await MainActor.run {
                    self.updateOfferInLists(updatedOffer)
                }
            } catch {
                print("Failed to refresh offer status: \(error)")
            }
        }
    }
    
    var pendingReceivedCount: Int {
        receivedOffers.filter { $0.status == .pending }.count
    }
    
    var pendingSentCount: Int {
        sentOffers.filter { $0.status == .pending }.count
    }
}