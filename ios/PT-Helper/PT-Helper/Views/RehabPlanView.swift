import SwiftUI

struct RehabPlanView: View {
    @StateObject var viewModel = RehabPlanViewModel()

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            if let plan = viewModel.rehabPlan {
                ScrollView {
                    VStack(spacing: 16) {
                        planHeader(plan: plan)
                        weeklyCalendar(plan: plan)
                        exerciseList(for: plan)
                        savePlanButton
                    }
                    .padding(20)
                }
            } else {
                emptyState
            }
        }
        .navigationTitle("Rehab Plan")
    }

    private func planHeader(plan: RehabPlan) -> some View {
        CardSection(icon: "calendar", color: .blue, title: plan.planName) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Conditions: \(plan.conditions.joined(separator: ", "))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Duration: \(plan.totalWeeks) weeks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Start Date: \(plan.createdDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func weeklyCalendar(plan: RehabPlan) -> some View {
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { day in
                VStack(spacing: 6) {
                    Text(dayNames[day])
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Circle()
                        .fill(plan.weeklySchedule.indices.contains(day) && !plan.weeklySchedule[day].isEmpty ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func exerciseList(for plan: RehabPlan) -> some View {
        VStack(spacing: 16) {
            ForEach(plan.exercises) { exercise in
                NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                    exerciseCard(for: exercise)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func exerciseCard(for exercise: RehabExercise) -> some View {
        CardSection(icon: exercise.demonstrationIcon, color: .green, title: exercise.name) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Target Area: \(exercise.targetArea)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("\(exercise.sets) sets × \(exercise.reps)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                DisclosureGroup("Description & Tips") {
                    Text(exercise.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    ForEach(exercise.tips, id: \.self) { tip in
                        Text("• \(tip)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var savePlanButton: some View {
        Button(action: { viewModel.savePlanToFirestore() }) {
            Text("Save Plan")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("No Plan Available")
                .font(.title2.bold())
                .foregroundColor(.primary)
            Text("Generate a plan from your analysis results.")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - DateFormatter extensions

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()

    static let shortWeekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
}
