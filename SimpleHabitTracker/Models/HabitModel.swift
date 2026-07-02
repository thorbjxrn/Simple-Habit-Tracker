import Foundation
import SwiftData

@Model
final class Habit {
    // Inline defaults are required for CloudKit-backed SwiftData:
    // every stored property must be optional or have a default value.
    var id: UUID = UUID()
    var name: String = ""
    var createdDate: Date = Date()
    var sortOrder: Int = 0
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
