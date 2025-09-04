import Foundation
import SwiftUI

@MainActor
class CreatorStatusViewModel: ObservableObject {
    @Published var isCreator = false
    @Published var creatorCode: String?
    @Published var applicationPending = false
    @Published var isLoading = false
    
    func loadCreatorStatus() async {
        isLoading = true
        
        do {
            let status = try await APIClient.shared.getCreatorStatus()
            
            self.isCreator = status.isCreator
            self.creatorCode = status.creatorCode
            self.applicationPending = status.applicationStatus == "pending"
        } catch {
            // User might not have any creator status yet
            self.isCreator = false
            self.creatorCode = nil
            self.applicationPending = false
        }
        
        isLoading = false
    }
}