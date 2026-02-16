import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class BodyMapViewModel: ObservableObject {
    @Published var regions: [BodyRegion] = []
    @Published var userProfile = UserProfile(
        userId: Auth.auth().currentUser?.uid ?? "",
        firstName: "", lastName: "",
        dateOfBirth: Date(), sex: "",
        heightFeet: 0, heightInches: 0, weight: 0.0,
        medicalConditions: [], otherMedicalConditions: nil,
        surgeries: [], injuries: [],
        activityLevel: "", primarySport: nil
    )

    private let db = Firestore.firestore()

    init() {
        loadRegions()
        loadUserProfile()
    }

    func toggleSelection(for region: BodyRegion) {
        if let index = regions.firstIndex(where: { $0.id == region.id }) {
            regions[index].isSelected.toggle()
        }
    }

    func clearAll() {
        for i in regions.indices {
            regions[i].isSelected = false
        }
    }

    var selectedRegions: [BodyRegion] {
        regions.filter { $0.isSelected }
    }

    private func loadRegions() {
        regions = [
            BodyRegion(name: "Head/Neck", zoneKey: "head_neck", relativePosition: CGPoint(x: 0.5, y: 0.08)),
            BodyRegion(name: "Left Shoulder", zoneKey: "left_shoulder", relativePosition: CGPoint(x: 0.3, y: 0.2)),
            BodyRegion(name: "Right Shoulder", zoneKey: "right_shoulder", relativePosition: CGPoint(x: 0.7, y: 0.2)),
            BodyRegion(name: "Chest", zoneKey: "chest", relativePosition: CGPoint(x: 0.5, y: 0.25)),
            BodyRegion(name: "Upper Back", zoneKey: "upper_back", relativePosition: CGPoint(x: 0.5, y: 0.32)),
            BodyRegion(name: "Left Elbow", zoneKey: "left_elbow", relativePosition: CGPoint(x: 0.2, y: 0.38)),
            BodyRegion(name: "Right Elbow", zoneKey: "right_elbow", relativePosition: CGPoint(x: 0.8, y: 0.38)),
            BodyRegion(name: "Lower Back", zoneKey: "lower_back", relativePosition: CGPoint(x: 0.5, y: 0.42)),
            BodyRegion(name: "Abdomen", zoneKey: "abdomen", relativePosition: CGPoint(x: 0.5, y: 0.48)),
            BodyRegion(name: "Left Wrist/Hand", zoneKey: "left_wrist_hand", relativePosition: CGPoint(x: 0.15, y: 0.52)),
            BodyRegion(name: "Right Wrist/Hand", zoneKey: "right_wrist_hand", relativePosition: CGPoint(x: 0.85, y: 0.52)),
            BodyRegion(name: "Left Hip", zoneKey: "left_hip", relativePosition: CGPoint(x: 0.38, y: 0.55)),
            BodyRegion(name: "Right Hip", zoneKey: "right_hip", relativePosition: CGPoint(x: 0.62, y: 0.55)),
            BodyRegion(name: "Left Knee", zoneKey: "left_knee", relativePosition: CGPoint(x: 0.38, y: 0.72)),
            BodyRegion(name: "Right Knee", zoneKey: "right_knee", relativePosition: CGPoint(x: 0.62, y: 0.72)),
            BodyRegion(name: "Left Ankle/Foot", zoneKey: "left_ankle_foot", relativePosition: CGPoint(x: 0.35, y: 0.9)),
            BodyRegion(name: "Right Ankle/Foot", zoneKey: "right_ankle_foot", relativePosition: CGPoint(x: 0.65, y: 0.9))
        ]
    }

    private func loadUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).collection("profile").document("health").getDocument { snapshot, error in
            if let error = error {
                print("Error loading user profile: \(error.localizedDescription)")
            } else if let snapshot = snapshot, snapshot.exists {
                do {
                    self.userProfile = try snapshot.data(as: UserProfile.self)
                } catch {
                    print("Error decoding user profile: \(error.localizedDescription)")
                }
            }
        }
    }
}
