import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let weekRecord: WeekRecord
    let currentDayIndex: Int?
    let onToggle: (Int) -> Void
    let onRename: (UUID, String) -> Void
    @AppStorage("todayIndicatorStyle") private var useDotIndicator = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(habit.name)
                .font(.headline)
                .contextMenu {
                    Button(action: {
                        onRename(habit.id, habit.name)
                    }) {
                        Label("Rename", systemImage: "pencil")
                    }
                }

            HStack {
                ForEach(0..<7, id: \.self) { index in
                    let state = weekRecord.completedDays[index]
                    let isToday = currentDayIndex == index

                    VStack(spacing: 4) {
                        Circle()
                            .fill(color(for: state))
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                if isToday && !useDotIndicator {
                                    Circle()
                                        .strokeBorder(Color.yellow, lineWidth: 2.5)
                                }
                            }
                            .onTapGesture {
                                onToggle(index)
                            }

                        if useDotIndicator {
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 4, height: 4)
                                .opacity(isToday ? 1 : 0)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Helpers

    private func color(for state: HabitState) -> Color {
        switch state {
        case .notCompleted: return .gray.opacity(0.3)
        case .completed: return .green
        case .failed: return .red
        }
    }
}
