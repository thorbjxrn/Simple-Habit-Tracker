import XCTest
import SwiftData
@testable import SimpleHabitTracker

final class SimpleHabitTrackerTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var viewModel: HabitViewModel!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Habit.self, WeekRecord.self, configurations: config)
        context = ModelContext(container)
        viewModel = HabitViewModel(modelContext: context)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
        viewModel = nil
    }

    // MARK: - 1. testAddHabit

    func testAddHabit() throws {
        viewModel.addHabit(name: "Exercise")

        let habits = viewModel.fetchHabits()
        XCTAssertEqual(habits.count, 1)
        XCTAssertEqual(habits.first?.name, "Exercise")
        XCTAssertEqual(habits.first?.sortOrder, 0)
        XCTAssertNotNil(habits.first?.createdDate)
        // Should also create a WeekRecord for the current week
        XCTAssertEqual(habits.first?.weekRecords.count, 1)
    }

    func testAddMultipleHabitsIncrementsSort() throws {
        viewModel.addHabit(name: "First")
        viewModel.addHabit(name: "Second")
        viewModel.addHabit(name: "Third")

        let habits = viewModel.fetchHabits()
        XCTAssertEqual(habits.count, 3)
        XCTAssertEqual(habits[0].sortOrder, 0)
        XCTAssertEqual(habits[1].sortOrder, 1)
        XCTAssertEqual(habits[2].sortOrder, 2)
    }

    // MARK: - 2. testDeleteHabitCascadesWeekRecords

    func testDeleteHabitCascadesWeekRecords() throws {
        viewModel.addHabit(name: "Reading")

        let habits = viewModel.fetchHabits()
        XCTAssertEqual(habits.count, 1)
        let habit = habits.first!
        let weekRecordID = habit.weekRecords.first!.id

        viewModel.removeHabit(habit)

        XCTAssertEqual(viewModel.fetchHabits().count, 0)

        // Verify the WeekRecord was cascade-deleted
        let descriptor = FetchDescriptor<WeekRecord>()
        let remainingRecords = try context.fetch(descriptor)
        let orphanedRecord = remainingRecords.first(where: { $0.id == weekRecordID })
        XCTAssertNil(orphanedRecord, "WeekRecord should be cascade-deleted with its Habit")
    }

    // MARK: - 3. testRenameHabit

    func testRenameHabit() throws {
        viewModel.addHabit(name: "Running")

        let habit = viewModel.fetchHabits().first!
        XCTAssertEqual(habit.name, "Running")

        viewModel.renameHabit(habit, newName: "Jogging")
        XCTAssertEqual(habit.name, "Jogging")
    }

    // MARK: - 4. testToggleDayState

    func testToggleDayState() throws {
        viewModel.addHabit(name: "Meditate")

        let habit = viewModel.fetchHabits().first!
        let weekRecord = viewModel.currentWeekRecord(for: habit)

        // Initially notCompleted
        XCTAssertEqual(weekRecord.completedDays[0], .notCompleted)

        // First toggle: notCompleted -> completed
        viewModel.toggleDay(weekRecord: weekRecord, dayIndex: 0)
        XCTAssertEqual(weekRecord.completedDays[0], .completed)

        // Second toggle: completed -> failed
        viewModel.toggleDay(weekRecord: weekRecord, dayIndex: 0)
        XCTAssertEqual(weekRecord.completedDays[0], .failed)

        // Third toggle: failed -> notCompleted
        viewModel.toggleDay(weekRecord: weekRecord, dayIndex: 0)
        XCTAssertEqual(weekRecord.completedDays[0], .notCompleted)
    }

    func testToggleDayOutOfBoundsDoesNothing() throws {
        viewModel.addHabit(name: "Test")

        let habit = viewModel.fetchHabits().first!
        let weekRecord = viewModel.currentWeekRecord(for: habit)

        // Should not crash or mutate anything
        viewModel.toggleDay(weekRecord: weekRecord, dayIndex: -1)
        viewModel.toggleDay(weekRecord: weekRecord, dayIndex: 7)
        viewModel.toggleDay(weekRecord: weekRecord, dayIndex: 100)

        // All days should still be notCompleted
        for day in weekRecord.completedDays {
            XCTAssertEqual(day, .notCompleted)
        }
    }

    // MARK: - 5. testWeekRecordCreation

    func testWeekRecordCreation() throws {
        viewModel.addHabit(name: "Stretch")

        let habit = viewModel.fetchHabits().first!
        let weekRecord = habit.weekRecords.first!

        // Should have 7 days, all notCompleted
        XCTAssertEqual(weekRecord.completedDays.count, 7)
        for day in weekRecord.completedDays {
            XCTAssertEqual(day, .notCompleted)
        }

        // weekStartDate should be the start of the current week
        let expectedStart = viewModel.weekStartDate(for: Date())
        let calendar = Calendar.current
        XCTAssertTrue(
            calendar.isDate(weekRecord.weekStartDate, equalTo: expectedStart, toGranularity: .day),
            "WeekRecord weekStartDate should match the current week start"
        )
    }

    // MARK: - 6. testFreeHabitLimit

    func testFreeHabitLimit() throws {
        // Free users can have up to 5 habits
        for i in 0..<5 {
            viewModel.addHabit(name: "Habit \(i)")
        }
        XCTAssertEqual(viewModel.fetchHabits().count, 5)

        // Should NOT be able to add a 6th habit on free tier
        XCTAssertFalse(viewModel.canAddHabit(isPremium: false))
    }

    func testFreeHabitLimitAllowsUpToFive() throws {
        for i in 0..<4 {
            viewModel.addHabit(name: "Habit \(i)")
        }
        // Can still add one more (total would be 5)
        XCTAssertTrue(viewModel.canAddHabit(isPremium: false))

        viewModel.addHabit(name: "Habit 4")
        // Now at 5, cannot add more
        XCTAssertFalse(viewModel.canAddHabit(isPremium: false))
    }

    // MARK: - 7. testPremiumUnlimitedHabits

    func testPremiumUnlimitedHabits() throws {
        for i in 0..<10 {
            viewModel.addHabit(name: "Habit \(i)")
        }
        XCTAssertEqual(viewModel.fetchHabits().count, 10)

        // Premium users should always be able to add more
        XCTAssertTrue(viewModel.canAddHabit(isPremium: true))
    }

    // MARK: - 8. testWeeklyGoalCalculation

    func testWeeklyGoalCalculation() throws {
        viewModel.addHabit(name: "Workout")

        let habit = viewModel.fetchHabits().first!
        viewModel.setWeeklyGoal(for: habit, target: 3)
        XCTAssertEqual(habit.targetDaysPerWeek, 3)

        let weekRecord = viewModel.currentWeekRecord(for: habit)

        // No completions yet - goal not met
        XCTAssertEqual(viewModel.isWeeklyGoalMet(for: habit, weekRecord: weekRecord), false)

        // Complete 2 days - still not met
        viewModel.toggleDay(weekRecord: weekRecord, dayIndex: 0) // -> completed
        viewModel.toggleDay(weekRecord: weekRecord, dayIndex: 1) // -> completed
        XCTAssertEqual(viewModel.isWeeklyGoalMet(for: habit, weekRecord: weekRecord), false)
        XCTAssertEqual(viewModel.weeklyCompletionCount(for: habit, weekRecord: weekRecord), 2)

        // Complete 3rd day - goal met
        viewModel.toggleDay(weekRecord: weekRecord, dayIndex: 2) // -> completed
        XCTAssertEqual(viewModel.isWeeklyGoalMet(for: habit, weekRecord: weekRecord), true)
        XCTAssertEqual(viewModel.weeklyCompletionCount(for: habit, weekRecord: weekRecord), 3)
    }

    func testWeeklyGoalNilReturnsNil() throws {
        viewModel.addHabit(name: "Casual")

        let habit = viewModel.fetchHabits().first!
        let weekRecord = viewModel.currentWeekRecord(for: habit)

        // No target set -> isWeeklyGoalMet returns nil
        XCTAssertNil(viewModel.isWeeklyGoalMet(for: habit, weekRecord: weekRecord))
    }

    // MARK: - 9. testWeekStartDateNormalization

    func testWeekStartDateNormalization() throws {
        let calendar = Calendar.current

        // Get two different dates in the same week
        let today = Date()
        let todayWeekStart = viewModel.weekStartDate(for: today)

        // Add 1 day to today (still same week unless it's the last day)
        // Use a concrete approach: start of week + 0 and start of week + 3 both normalize to same start
        let midWeek = calendar.date(byAdding: .day, value: 3, to: todayWeekStart)!
        let midWeekNormalized = viewModel.weekStartDate(for: midWeek)

        XCTAssertTrue(
            calendar.isDate(todayWeekStart, equalTo: midWeekNormalized, toGranularity: .day),
            "Dates in the same week should normalize to the same week start date"
        )

        // A date exactly 7 days later should have a different start
        let nextWeekDate = calendar.date(byAdding: .day, value: 7, to: todayWeekStart)!
        let nextWeekStart = viewModel.weekStartDate(for: nextWeekDate)

        XCTAssertFalse(
            calendar.isDate(todayWeekStart, equalTo: nextWeekStart, toGranularity: .day),
            "Dates in different weeks should normalize to different week start dates"
        )
    }

    // MARK: - 10. testMigrationFromUserDefaults

    func testMigrationFromUserDefaults() throws {
        // Reset migration flag
        UserDefaults.standard.removeObject(forKey: "didMigrateToSwiftData_v1")

        // Set up legacy data in UserDefaults
        struct LegacyHabit: Codable {
            let id: UUID
            var name: String
            var completedDays: [LegacyHabitState]

            enum LegacyHabitState: String, Codable {
                case notCompleted
                case completed
                case failed
            }
        }

        let legacyHabits = [
            LegacyHabit(
                id: UUID(),
                name: "Legacy Reading",
                completedDays: [.completed, .notCompleted, .failed, .completed, .notCompleted, .notCompleted, .completed]
            ),
            LegacyHabit(
                id: UUID(),
                name: "Legacy Running",
                completedDays: [.notCompleted, .completed, .completed, .notCompleted, .failed, .notCompleted, .completed]
            ),
        ]

        let encodedHabits = try JSONEncoder().encode(legacyHabits)
        UserDefaults.standard.set(encodedHabits, forKey: "habits")

        let encodedDate = try JSONEncoder().encode(Date())
        UserDefaults.standard.set(encodedDate, forKey: "date")

        // Run migration
        MigrationManager.migrateIfNeeded(context: context)

        // Verify habits were created
        let habits = viewModel.fetchHabits()
        XCTAssertEqual(habits.count, 2)

        let habitNames = habits.map(\.name).sorted()
        XCTAssertTrue(habitNames.contains("Legacy Reading"))
        XCTAssertTrue(habitNames.contains("Legacy Running"))

        // Verify each habit has a week record with the correct states
        for habit in habits {
            XCTAssertEqual(habit.weekRecords.count, 1)
            let record = habit.weekRecords.first!
            XCTAssertEqual(record.completedDays.count, 7)
        }

        let readingHabit = habits.first(where: { $0.name == "Legacy Reading" })!
        let readingRecord = readingHabit.weekRecords.first!
        XCTAssertEqual(readingRecord.completedDays[0], .completed)
        XCTAssertEqual(readingRecord.completedDays[1], .notCompleted)
        XCTAssertEqual(readingRecord.completedDays[2], .failed)
        XCTAssertEqual(readingRecord.completedDays[3], .completed)

        // Verify migration flag was set
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "didMigrateToSwiftData_v1"))

        // Verify UserDefaults data was cleaned up
        XCTAssertNil(UserDefaults.standard.data(forKey: "habits"))
        XCTAssertNil(UserDefaults.standard.data(forKey: "date"))

        // Clean up
        UserDefaults.standard.removeObject(forKey: "didMigrateToSwiftData_v1")
    }

    func testMigrationSkipsWhenAlreadyMigrated() throws {
        // Set the flag as if migration already ran
        UserDefaults.standard.set(true, forKey: "didMigrateToSwiftData_v1")

        // Even if there's data, migration should be skipped
        MigrationManager.migrateIfNeeded(context: context)

        let habits = viewModel.fetchHabits()
        XCTAssertEqual(habits.count, 0)

        // Clean up
        UserDefaults.standard.removeObject(forKey: "didMigrateToSwiftData_v1")
    }
}
