import SwiftUI

import Foundation
import FirebaseFirestore
import FirebaseAuth

class SavedPlansViewModel: ObservableObject {
    @Published var rehabPlans: [RehabPlan] = []
    @Published var isLoading: Bool = false
    
    private let db = Firestore.firestore()
    
    init() {
        fetchRehabPlans()
    }
    
    func fetchRehabPlans() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        db.collection("users").document(uid).collection("rehabPlans").getDocuments { snapshot, error in
            self.isLoading = false
            if let error = error {
                print("Error fetching rehab plans: \(error.localizedDescription)")
                return
            }
            self.rehabPlans = snapshot?.documents.compactMap { document in
                try? document.data(as: RehabPlan.self)
            } ?? []
        }
    }
}
