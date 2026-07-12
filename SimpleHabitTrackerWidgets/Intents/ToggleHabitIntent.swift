import AppIntents
import WidgetKit

struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Habit"
    static var description: IntentDescription = "Toggle a habit's completion for today"

    @Parameter(title: "Habit ID")
    var habitID: String

    @Parameter(title: "Day Index")
    var dayIndex: Int

    @Parameter(title: "Source Widget Kind")
    var sourceKind: String

    static let allKinds = ["SingleHabitToday", "SingleHabitWeek", "MultiHabitToday", "Heatmap"]

    init() {
        self.sourceKind = ""
    }

    init(habitID: UUID, dayIndex: Int, sourceKind: String = "") {
        self.habitID = habitID.uuidString
        self.dayIndex = dayIndex
        self.sourceKind = sourceKind
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: habitID) else {
            return .result()
        }
        await SharedModelContainer.toggleDay(habitID: uuid, dayIndex: dayIndex)
        // The system reloads the tapped widget automatically (budget-exempt).
        // Only sibling kinds need explicit reloads — those DO count against the
        // extension's daily reload budget, so don't waste it on the source kind.
        for kind in Self.allKinds where kind != sourceKind {
            WidgetCenter.shared.reloadTimelines(ofKind: kind)
        }
        return .result()
    }
}
