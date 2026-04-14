import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var createdDate: Date
    var sortOrder: Int
    var colorTheme: String?
    var targetDaysPerWeek: Int?

    @Relationship(deleteRule: .cascade, inverse: \WeekRecord.habit)
    var weekRecords: [WeekRecord] = []

    init(
        id: UUID = UUID(),
        name: String,
        createdDate: Date = Date(),
        sortOrder: Int = 0,
        colorTheme: String? = nil,
        targetDaysPerWeek: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.createdDate = createdDate
        self.sortOrder = sortOrder
        self.colorTheme = colorTheme
        self.targetDaysPerWeek = targetDaysPerWeek
    }
}
