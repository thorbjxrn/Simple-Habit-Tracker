import AppIntents
import WidgetKit

struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Habit"
    static var description: IntentDescription = "Toggle a habit's completion for today"

    @Parameter(title: "Habit ID")
    var habitID: String

    @Parameter(title: "Day Index")
    var dayIndex: Int

    init() {}

    init(habitID: UUID, dayIndex: Int) {
        self.habitID = habitID.uuidString
        self.dayIndex = dayIndex
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: habitID) else {
            return .result()
        }
        await SharedModelContainer.toggleDay(habitID: uuid, dayIndex: dayIndex)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
