import Foundation

struct ExerciseSession: Identifiable, Codable {
    var id: UUID
    var exerciseId: UUID
    var startTime: Date
    var endTime: Date?
    var completedSets: Int
    var completedReps: Int
    var notes: String?
    var painLevel: Int?
    var isCompleted: Bool
}
