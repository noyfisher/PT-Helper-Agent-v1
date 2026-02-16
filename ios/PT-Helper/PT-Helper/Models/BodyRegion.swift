import Foundation
import CoreGraphics

struct BodyRegion: Identifiable, Codable {
    let id: UUID
    let name: String
    let zoneKey: String
    let relativePosition: CGPoint
    var isSelected: Bool

    init(name: String, zoneKey: String, relativePosition: CGPoint) {
        self.id = UUID()
        self.name = name
        self.zoneKey = zoneKey
        self.relativePosition = relativePosition
        self.isSelected = false
    }
}
