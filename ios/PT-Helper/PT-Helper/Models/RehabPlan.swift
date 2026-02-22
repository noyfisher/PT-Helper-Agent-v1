import Foundation

struct RehabPlan: Codable, Identifiable {
    let id: UUID
    let planName: String
    let conditions: [String]
    let exercises: [RehabExercise]
    let weeklySchedule: [[String]]
    let totalWeeks: Int
    let createdDate: Date
    let notes: String?
}

struct RehabExercise: Codable, Identifiable {
    let id: UUID
    let name: String
    let targetArea: String
    let description: String
    let sets: Int
    let reps: String
    let restSeconds: Int
    let difficulty: Difficulty
    let demonstrationIcon: String
    let tips: [String]
    let contraindications: [String]

    enum Difficulty: String, Codable, CaseIterable {
        case beginner, intermediate, advanced
    }
}
