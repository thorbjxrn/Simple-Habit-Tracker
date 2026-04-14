import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let weekRecord: WeekRecord
    let currentDayIndex: Int?
    let onToggle: (Int) -> Void
    let onRename: (UUID, String) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(habit.name)
                .lineLimit(nil)
                .font(.headline)
                .contextMenu {
                    Button(action: {
                        onRename(habit.id, habit.name)
                    }) {
                        Label("Rename", systemImage: "pencil")
                    }
                }
            GeometryReader { geometry in
                VStack(alignment: .center, spacing: 0) {
                    HStack(alignment: .center) {
                        ForEach(0..<7) { index in
                            VStack(alignment: .center, spacing: 4.5) {
                                Circle()
                                    .fill(color(for: weekRecord.completedDays[index]))
                                    .frame(width: 33, height: 33)
                                    .onTapGesture {
                                        onToggle(index)
                                    }
                                Circle()
                                    .fill(todayIndicatorColor(day: index))
                                    .frame(width: 3, height: 3, alignment: .center)
                                    .shadow(color: .yellow, radius: 0.5, y: 0.25)
                            }
                        }
                    }
                    .overlay(
                        LineConnectingConsecutiveDays(days: weekRecord.completedDays, geometry: geometry)
                    )
                }
            }
        }
        .padding(.vertical, 25)
    }

    // MARK: - Helpers

    func color(for state: HabitState) -> Color {
        switch state {
        case .notCompleted:
            return Color.gray
        case .completed:
            return Color.green
        case .failed:
            return Color.red
        }
    }

    func todayIndicatorColor(day: Int) -> Color {
        guard let currentDay = currentDayIndex else {
            return Color(.yellow).opacity(0)
        }
        if day == currentDay {
            return Color(.yellow).opacity(1)
        } else {
            return Color(.yellow).opacity(0)
        }
    }
}
