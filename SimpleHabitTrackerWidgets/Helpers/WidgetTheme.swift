import SwiftUI

struct WidgetTheme {
    let completedColor: Color
    let failedColor: Color
    let notCompletedColor: Color

    static func current() -> WidgetTheme {
        let themeRaw = SharedModelContainer.sharedUserDefaults.string(forKey: "selectedTheme")
            ?? AppTheme.defaultTheme.rawValue
        let theme = AppTheme.from(rawValue: themeRaw)
        return WidgetTheme(
            completedColor: theme.completedColor,
            failedColor: theme.failedColor,
            notCompletedColor: theme.notCompletedColor
        )
    }

    func color(for state: HabitState) -> Color {
        switch state {
        case .notCompleted: return notCompletedColor
        case .completed: return completedColor
        case .failed: return failedColor
        }
    }
}
