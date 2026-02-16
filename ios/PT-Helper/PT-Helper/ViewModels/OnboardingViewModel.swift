import SwiftUI
import Foundation
import FirebaseFirestore
import FirebaseAuth

class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 1
    @Published var userProfile = UserProfile(userId: Auth.auth().currentUser?.uid ?? "",
                                             firstName: "",
                                             lastName: "",
                                             dateOfBirth: Date(),
                                             sex: "",
                                             heightFeet: 0,
                                             heightInches: 0,
                                             weight: 0.0,
                                             medicalConditions: [],
                                             otherMedicalConditions: nil,
                                             surgeries: [],
                                             injuries: [],
                                             activityLevel: "",
                                             primarySport: nil)

    private let db = Firestore.firestore()

    func saveProfile(completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try db.collection("users").document(uid).collection("profile").document("health").setData(from: userProfile) { error in
                if let error = error {
                    print("Error saving profile: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        } catch {
            print("Error encoding profile: \(error.localizedDescription)")
            completion(false)
        }
    }

    func loadProfile(completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).collection("profile").document("health").getDocument { snapshot, error in
            if let error = error {
                print("Error loading profile: \(error.localizedDescription)")
                completion(false)
            } else if let snapshot = snapshot, snapshot.exists {
                do {
                    self.userProfile = try snapshot.data(as: UserProfile.self)
                    completion(true)
                } catch {
                    print("Error decoding profile: \(error.localizedDescription)")
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }

    func nextStep() {
        if currentStep < 6 {
            currentStep += 1
        }
    }

    func previousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }
}
