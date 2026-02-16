import Foundation

struct Note: Identifiable, Codable {
    let id: UUID
    var content: String
    let dateCreated: Date
    
    init(content: String) {
        self.id = UUID()
        self.content = content
        self.dateCreated = Date()
    }
}
