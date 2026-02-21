import Foundation

struct UserProfile: Codable, Identifiable {
    var id: String { userId }
    var userId: String
    var firstName: String
    var lastName: String
    var dateOfBirth: Date
    var sex: String
    var heightFeet: Int
    var heightInches: Int
    var weight: Double
    var medicalConditions: [String]
    var otherMedicalConditions: String?
    var surgeries: [Surgery]
    var injuries: [Injury]
    var activityLevel: String
    var primarySport: String?

    var age: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year ?? 0
    }

    struct Surgery: Codable, Identifiable {
        var id: UUID = UUID()
        var name: String
        var year: Int
    }

    struct Injury: Codable, Identifiable {
        var id: UUID = UUID()
        var bodyArea: String
        var description: String
        var isCurrent: Bool
    }
}
