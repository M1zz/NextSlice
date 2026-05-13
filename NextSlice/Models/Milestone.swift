import Foundation
import SwiftData

@Model
final class Milestone {
    var id: UUID = UUID()
    var title: String = ""
    var date: Date = Date.now
    var doneAt: Date?
    var goal: Goal?

    init(
        title: String,
        date: Date,
        goal: Goal? = nil,
        doneAt: Date? = nil
    ) {
        self.title = title
        self.date = date
        self.goal = goal
        self.doneAt = doneAt
    }

    var isDone: Bool { doneAt != nil }
}
