import SwiftUI
import Charts

struct ProgressChartView: View {
    @StateObject private var viewModel = WorkoutViewModel()

    var body: some View {
        ZStack {
            AppColors.pageBackground
                .ignoresSafeArea()

            if viewModel.sessions.isEmpty {
                EmptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "No Data Yet",
                    subtitle: "Complete workout sessions to see your progress over time"
                )
                .padding(.horizontal, AppSpacing.xl)
            } else {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        painTrendChart
                        summaryStats
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.vertical, AppSpacing.md)
                }
            }
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Pain Trend Chart

    private var painTrendChart: some View {
        CardSection(icon: "chart.line.uptrend.xyaxis", color: .blue, title: "Pain Trend") {
            Chart(viewModel.sessions, id: \.id) { session in
                LineMark(
                    x: .value("Date", session.date),
                    y: .value("Pain", session.painLevel)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                AreaMark(
                    x: .value("Date", session.date),
                    y: .value("Pain", session.painLevel)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.2), .blue.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                PointMark(
                    x: .value("Date", session.date),
                    y: .value("Pain", session.painLevel)
                )
                .foregroundStyle(.blue)
                .symbolSize(30)
            }
            .chartYScale(domain: 0...10)
            .chartYAxis {
                AxisMarks(values: [0, 2, 4, 6, 8, 10]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.gray.opacity(0.3))
                    AxisValueLabel()
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 220)
        }
    }

    // MARK: - Summary Stats

    private var summaryStats: some View {
        HStack(spacing: AppSpacing.md) {
            statCard(
                icon: "number",
                color: .blue,
                value: "\(viewModel.sessions.count)",
                label: "Sessions"
            )

            statCard(
                icon: "waveform.path.ecg",
                color: averagePainColor,
                value: String(format: "%.1f", averagePain),
                label: "Avg Pain"
            )

            statCard(
                icon: "clock",
                color: .orange,
                value: "\(totalMinutes)",
                label: "Total Min"
            )
        }
    }

    private func statCard(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .cornerRadius(AppCorners.small)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCorners.card)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Computed Properties

    private var averagePain: Double {
        guard !viewModel.sessions.isEmpty else { return 0 }
        let total = viewModel.sessions.reduce(0.0) { $0 + $1.painLevel }
        return total / Double(viewModel.sessions.count)
    }

    private var averagePainColor: Color {
        switch Int(averagePain) {
        case 0...3: return .green
        case 4...6: return .orange
        default: return .red
        }
    }

    private var totalMinutes: Int {
        Int(viewModel.sessions.reduce(0.0) { $0 + $1.duration } / 60)
    }
}
