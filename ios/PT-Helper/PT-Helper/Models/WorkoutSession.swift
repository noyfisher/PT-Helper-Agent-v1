import Foundation

struct WorkoutSession: Identifiable, Codable {
    var id: UUID
    var date: Date
    var duration: TimeInterval
    var painLevel: Double
    var isCompleted: Bool
}
