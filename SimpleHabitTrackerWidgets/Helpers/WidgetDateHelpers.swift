import Foundation

enum WidgetDateHelpers {
    static var todayDayIndex: Int {
        SharedModelContainer.todayDayIndex()
    }

    static var dayLabels: [String] {
        SharedModelContainer.dayLabels()
    }

    static func weekStartDate(for date: Date = Date()) -> Date {
        SharedModelContainer.weekStartDate(for: date)
    }
}
