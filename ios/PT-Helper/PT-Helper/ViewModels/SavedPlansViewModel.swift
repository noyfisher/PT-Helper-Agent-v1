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
        db.collection("users").document(uid).collection("rehabPlans")
            .order(by: "createdDate", descending: true)
            .getDocuments { snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    print("Error fetching rehab plans: \(error.localizedDescription)")
                    return
                }
                self.rehabPlans = snapshot?.documents.compactMap { document -> RehabPlan? in
                    let data = document.data()
                    guard let idString = data["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let planName = data["planName"] as? String else {
                        return nil
                    }

                    let exercises: [RehabExercise] = (data["exercises"] as? [[String: Any]] ?? []).compactMap { e in
                        guard let eidStr = e["id"] as? String,
                              let eid = UUID(uuidString: eidStr),
                              let name = e["name"] as? String else { return nil }
                        let diffStr = e["difficulty"] as? String ?? "beginner"
                        let difficulty: RehabExercise.Difficulty
                        switch diffStr {
                        case "intermediate": difficulty = .intermediate
                        case "advanced": difficulty = .advanced
                        default: difficulty = .beginner
                        }
                        return RehabExercise(
                            id: eid,
                            name: name,
                            targetArea: e["targetArea"] as? String ?? "",
                            description: e["description"] as? String ?? "",
                            sets: e["sets"] as? Int ?? 3,
                            reps: e["reps"] as? String ?? "10",
                            restSeconds: e["restSeconds"] as? Int ?? 30,
                            difficulty: difficulty,
                            demonstrationIcon: e["demonstrationIcon"] as? String ?? "figure.flexibility",
                            tips: e["tips"] as? [String] ?? [],
                            contraindications: e["contraindications"] as? [String] ?? []
                        )
                    }

                    // Decode weeklySchedule: supports both dictionary format (new) and nested array format (legacy)
                    let weeklySchedule: [[String]]
                    if let scheduleDict = data["weeklySchedule"] as? [String: [String]] {
                        // New format: dictionary keyed by day index
                        var schedule: [[String]] = Array(repeating: [], count: 7)
                        for (key, exercises) in scheduleDict {
                            if let dayIndex = Int(key), dayIndex >= 0, dayIndex < 7 {
                                schedule[dayIndex] = exercises
                            }
                        }
                        weeklySchedule = schedule
                    } else if let scheduleArray = data["weeklySchedule"] as? [[String]] {
                        // Legacy format: nested array
                        weeklySchedule = scheduleArray
                    } else {
                        weeklySchedule = []
                    }

                    return RehabPlan(
                        id: id,
                        planName: planName,
                        conditions: data["conditions"] as? [String] ?? [],
                        exercises: exercises,
                        weeklySchedule: weeklySchedule,
                        totalWeeks: data["totalWeeks"] as? Int ?? 4,
                        createdDate: (data["createdDate"] as? Timestamp)?.dateValue() ?? Date(),
                        notes: data["notes"] as? String
                    )
                } ?? []
            }
        }
    }

    func deletePlan(_ plan: RehabPlan) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let planId = plan.id.uuidString

        // Remove locally first for instant UI feedback
        rehabPlans.removeAll { $0.id == plan.id }

        // Remove from Firestore
        db.collection("users").document(uid).collection("rehabPlans")
            .document(planId)
            .delete { error in
                if let error = error {
                    print("Error deleting plan: \(error.localizedDescription)")
                    // Re-fetch to restore consistent state
                    self.fetchRehabPlans()
                }
            }
    }
}
