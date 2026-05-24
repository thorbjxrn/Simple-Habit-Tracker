import Foundation
import SwiftData

enum SharedModelContainer {
    static let appGroupID = "group.thorbjxrn.SimpleHabitTracker"

    static var sharedUserDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func create(forWidget: Bool = false) throws -> ModelContainer {
        let config: ModelConfiguration
        if !forWidget {
            let syncEnabled = sharedUserDefaults.bool(forKey: "iCloudSyncEnabled")
            let isPremium = sharedUserDefaults.bool(forKey: "isPremiumCached")
            if syncEnabled && isPremium {
                config = ModelConfiguration(
                    url: storeURL,
                    cloudKitDatabase: .private("iCloud.thorbjxrn.SimpleHabitTracker")
                )
            } else {
                config = ModelConfiguration(url: storeURL, cloudKitDatabase: .none)
            }
        } else {
            config = ModelConfiguration(url: storeURL, cloudKitDatabase: .none)
        }
        return try ModelContainer(for: Habit.self, configurations: config)
    }

    private static var storeURL: URL {
        let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        )!
        return containerURL.appendingPathComponent("SimpleHabitTracker.store")
    }

    // MARK: - Store Migration

    static func migrateStoreToAppGroupIfNeeded() {
        let fileManager = FileManager.default
        let appGroupURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        )!
        let newStoreURL = appGroupURL.appendingPathComponent("SimpleHabitTracker.store")

        guard !fileManager.fileExists(atPath: newStoreURL.path) else { return }

        let defaultURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("default.store")

        guard fileManager.fileExists(atPath: defaultURL.path) else { return }

        let extensions = ["", "-wal", "-shm"]
        var copied: [URL] = []
        do {
            for ext in extensions {
                let src = URL(fileURLWithPath: defaultURL.path + ext)
                let dst = URL(fileURLWithPath: newStoreURL.path + ext)
                guard fileManager.fileExists(atPath: src.path) else { continue }
                try fileManager.copyItem(at: src, to: dst)
                copied.append(dst)
            }
        } catch {
            for dst in copied {
                try? fileManager.removeItem(at: dst)
            }
        }
    }

    // MARK: - Widget Data Helpers

    static func todayDayIndex() -> Int {
        var calendar = Calendar.current
        calendar.locale = Locale.current
        let firstWeekday = calendar.firstWeekday
        let weekday = calendar.component(.weekday, from: Date())
        return (weekday - firstWeekday + 7) % 7
    }

    static func weekStartDate(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    static func currentWeekRecord(for habit: Habit, context: ModelContext) -> WeekRecord {
        let startOfWeek = weekStartDate(for: Date())
        let calendar = Calendar.current

        if let existing = habit.weekRecords.first(where: {
            calendar.isDate($0.weekStartDate, equalTo: startOfWeek, toGranularity: .day)
        }) {
            return existing
        }

        let record = WeekRecord(weekStartDate: startOfWeek)
        context.insert(record)
        habit.weekRecords.append(record)
        try? context.save()
        return record
    }

    static func toggleDay(habitID: UUID, dayIndex: Int) {
        guard dayIndex >= 0 && dayIndex < 7 else { return }

        do {
            let container = try create(forWidget: true)
            let context = ModelContext(container)

            let descriptor = FetchDescriptor<Habit>()
            let habits = try context.fetch(descriptor)
            guard let habit = habits.first(where: { $0.id == habitID }) else { return }

            let record = currentWeekRecord(for: habit, context: context)
            guard dayIndex < record.completedDays.count else { return }

            var days = record.completedDays
            switch days[dayIndex] {
            case .notCompleted: days[dayIndex] = .completed
            case .completed: days[dayIndex] = .failed
            case .failed: days[dayIndex] = .notCompleted
            }
            record.completedDays = days
            try context.save()
        } catch {
            print("Widget toggleDay failed: \(error)")
        }
    }

    static func dayLabels() -> [String] {
        var calendar = Calendar.current
        calendar.locale = Locale.current
        let symbols = calendar.veryShortWeekdaySymbols
        let firstWeekday = calendar.firstWeekday
        var reordered: [String] = []
        for i in 0..<7 {
            let index = (firstWeekday - 1 + i) % 7
            reordered.append(symbols[index])
        }
        return reordered
    }
}
