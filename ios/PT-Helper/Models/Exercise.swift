import Foundation

enum ExerciseDifficulty: String, Codable {
    case easy, medium, hard
}

enum ExerciseCategory: String, Codable {
    case strength, cardio, flexibility
}

struct Exercise: Identifiable, Codable {
    var id: UUID
    var name: String
    var description: String
    var instructions: [String]
    var duration: Int?
    var repetitions: Int?
    var sets: Int?
    var difficulty: ExerciseDifficulty
    var category: ExerciseCategory
    var imageURL: String?
    var videoURL: String?
}
