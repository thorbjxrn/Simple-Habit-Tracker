import SwiftUI

// 1. Habit model
struct Habit: Identifiable {
    let id = UUID()
    let name: String
    var completedDays: [Bool]  // Array to track completion of each day
}

// 2. Main View
struct HabitTrackerView: View {
    @State private var habits: [Habit] = [
        Habit(name: "Drink Water", completedDays: Array(repeating: false, count: 7)),
        Habit(name: "Exercise", completedDays: Array(repeating: false, count: 7))
    ]

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
                                    .fill(habit.completedDays[index] ? Color.green : Color.gray)
                                    .frame(width: 30, height: 30)
                                    .onTapGesture {
                                        habit.completedDays[index].toggle()
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
}

// 3. Preview
struct HabitTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        HabitTrackerView()
    }
}
