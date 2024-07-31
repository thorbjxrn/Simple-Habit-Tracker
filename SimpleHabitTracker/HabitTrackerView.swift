import SwiftUI

// Habit model with completion and failure states
struct Habit: Identifiable {
    let id = UUID()
    let name: String
    var completedDays: [HabitState]

    enum HabitState {
        case notCompleted
        case completed
        case failed
    }
}

// Main View
struct HabitTrackerView: View {
    @State private var habits: [Habit] = [
        Habit(name: "Drink Water", completedDays: Array(repeating: .notCompleted, count: 7)),
        Habit(name: "Exercise", completedDays: Array(repeating: .notCompleted, count: 7))
    ]

    @State private var lastTapTime: Date? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach($habits) { $habit in
                    VStack(alignment: .leading) {
                        Text(habit.name)
                            .font(.headline)

                        HStack {
                            ForEach(0..<7) { index in
                                Circle()
                                    .fill(color(for: habit.completedDays[index]))
                                    .frame(width: 30, height: 30)
                                    .onTapGesture {
                                        handleTap(index: index, for: &habit.completedDays)
                                    }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Habit Tracker")
        }
    }

    // Helper functions

    func color(for state: Habit.HabitState) -> Color {
        switch state {
        case .notCompleted:
            return Color.gray
        case .completed:
            return Color.green
        case .failed:
            return Color.red
        }
    }

    func handleTap(index: Int, for days: inout [Habit.HabitState]) {
        let now = Date()

        if let lastTap = lastTapTime, now.timeIntervalSince(lastTap) < 0.3 {
            // Double tap detected
            markAsFailed(index: index, in: &days)
        } else {
            // Single tap detected
            markAsCompleted(index: index, in: &days)
        }

        lastTapTime = now
    }

    func markAsCompleted(index: Int, in days: inout [Habit.HabitState]) {
        if days[index] != .completed {
            days[index] = .completed
        } else {
            days[index] = .notCompleted
        }
    }

    func markAsFailed(index: Int, in days: inout [Habit.HabitState]) {
        days[index] = .failed
    }
}

// Preview
struct HabitTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        HabitTrackerView()
    }
}

#Preview {
    HabitTrackerView()
}
