import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let weekRecord: WeekRecord
    let currentDayIndex: Int?
    let onToggle: (Int) -> Void
    let onRename: (UUID, String) -> Void

    private let circleSize: CGFloat = 33

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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

            HStack(spacing: 0) {
                ForEach(0..<7) { index in
                    ZStack {
                        // Streak connector - draws behind the circle
                        HStack(spacing: 0) {
                            // Left half connector
                            Rectangle()
                                .fill(shouldConnectLeft(index: index) ? Color.green : Color.clear)
                                .frame(height: 6)
                                .frame(maxWidth: .infinity)

                            // Right half connector
                            Rectangle()
                                .fill(shouldConnectRight(index: index) ? Color.green : Color.clear)
                                .frame(height: 6)
                                .frame(maxWidth: .infinity)
                        }

                        // Circle
                        VStack(spacing: 4) {
                            Circle()
                                .fill(color(for: weekRecord.completedDays[index]))
                                .frame(width: circleSize, height: circleSize)
                                .onTapGesture {
                                    onToggle(index)
                                }

                            // Today indicator
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 4, height: 4)
                                .opacity(currentDayIndex == index ? 1 : 0)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Streak Logic

    private func shouldConnectLeft(index: Int) -> Bool {
        guard index > 0 else { return false }
        return weekRecord.completedDays[index] == .completed
            && weekRecord.completedDays[index - 1] == .completed
    }

    private func shouldConnectRight(index: Int) -> Bool {
        guard index < 6 else { return false }
        return weekRecord.completedDays[index] == .completed
            && weekRecord.completedDays[index + 1] == .completed
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
}
