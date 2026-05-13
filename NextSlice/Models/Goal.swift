import Foundation
import SwiftData

@Model
final class Goal {
    var id: UUID = UUID()
    var title: String = ""
    var createdAt: Date = Date.now
    var archivedAt: Date?
    /// 6-char hex without "#". Decoded to SwiftUI Color in views.
    var colorHex: String = "4FACFE"

    @Relationship(deleteRule: .cascade, inverse: \Milestone.goal)
    var milestones: [Milestone] = []

    init(
        title: String,
        colorHex: String = "4FACFE",
        createdAt: Date = .now
    ) {
        self.title = title
        self.colorHex = colorHex
        self.createdAt = createdAt
    }

    var isArchived: Bool { archivedAt != nil }
}
