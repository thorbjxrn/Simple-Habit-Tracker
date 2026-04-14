import SwiftUI
import Charts

struct TrendGraphPanel: View {
    let viewModel: HabitViewModel
    let isPremium: Bool

    private var chartData: [WeekDataPoint] {
        let weekCount = isPremium ? 12 : 2
        let data = viewModel.completionData(weekCount: weekCount)
        return data.enumerated().map { index, item in
            WeekDataPoint(
                weekStart: item.weekStart,
                percentage: item.percentage,
                label: weekLabel(for: item.weekStart)
            )
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Weekly Trend")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 16)

            if chartData.isEmpty {
                ContentUnavailableView(
                    "No Data Yet",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Start tracking habits to see trends.")
                )
            } else {
                Chart(chartData) { point in
                    LineMark(
                        x: .value("Week", point.weekStart, unit: .weekOfYear),
                        y: .value("Completion %", point.percentage)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue)

                    AreaMark(
                        x: .value("Week", point.weekStart, unit: .weekOfYear),
                        y: .value("Completion %", point.percentage)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue.opacity(0.1))

                    PointMark(
                        x: .value("Week", point.weekStart, unit: .weekOfYear),
                        y: .value("Completion %", point.percentage)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(30)
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)%")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                    }
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 16)

                if !isPremium {
                    Text("Upgrade to Premium for full history")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)
                }
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Helpers

    private func weekLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

// MARK: - Data Model

private struct WeekDataPoint: Identifiable {
    let id = UUID()
    let weekStart: Date
    let percentage: Double
    let label: String
}
