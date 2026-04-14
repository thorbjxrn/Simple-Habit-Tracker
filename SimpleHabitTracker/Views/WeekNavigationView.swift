import SwiftUI
import SwiftData

struct WeekNavigationView: View {
    @Binding var weekOffset: Int
    let isPremium: Bool
    let canNavigate: (Int) -> Bool
    @Binding var showPaywall: Bool

    var body: some View {
        HStack {
            Button(action: {
                let newOffset = weekOffset - 1
                if canNavigate(newOffset) {
                    weekOffset = newOffset
                } else {
                    showPaywall = true
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(weekLabel(for: weekOffset))
                .font(.headline)

            Spacer()

            Button(action: {
                if weekOffset < 0 {
                    weekOffset += 1
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(weekOffset < 0 ? .primary : .gray.opacity(0.3))
            }
            .buttonStyle(.plain)
            .disabled(weekOffset >= 0)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Week Label

    private func weekLabel(for offset: Int) -> String {
        switch offset {
        case 0:
            return "This Week"
        case -1:
            return "Last Week"
        default:
            let calendar = Calendar.current
            let today = Date()
            guard let startOfCurrentWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
                return "Week"
            }
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: offset, to: startOfCurrentWeek) else {
                return "Week"
            }
            guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
                return "Week"
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let startStr = formatter.string(from: weekStart)
            let endStr = formatter.string(from: weekEnd)
            return "\(startStr) - \(endStr)"
        }
    }
}

struct DayOfWeekHeaderView: View {
    var body: some View {
        HStack(spacing: 0) {
            ForEach(dayLabels(), id: \.self) { label in
                Text(label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func dayLabels() -> [String] {
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
