import SwiftUI

struct ExerciseDetailView: View {
    let exercise: RehabExercise

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    demonstrationIcon
                    exerciseInfo
                    formTips
                    contraindications
                    if exercise.reps.contains("seconds") {
                        timerView
                    }
                }
                .padding(20)
            }
        }
    }

    private var demonstrationIcon: some View {
        Image(systemName: exercise.demonstrationIcon)
            .font(.system(size: 100))
            .foregroundColor(.blue)
            .symbolEffect(.bounce)
            .padding()
    }

    private var exerciseInfo: some View {
        CardSection(icon: "info.circle", color: .blue, title: exercise.name) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Target Area: \(exercise.targetArea)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(exercise.description)
                    .font(.body)
                    .foregroundColor(.primary)
                HStack {
                    Text("Sets: \(exercise.sets)")
                    Text("Reps: \(exercise.reps)")
                    Text("Rest: \(exercise.restSeconds) sec")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }

    private var formTips: some View {
        CardSection(icon: "lightbulb", color: .yellow, title: "Form Tips") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(exercise.tips, id: \.self) { tip in
                    Text("- \(tip)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var contraindications: some View {
        CardSection(icon: "exclamationmark.triangle", color: .red, title: "Contraindications") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(exercise.contraindications, id: \.self) { contraindication in
                    Text("- \(contraindication)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var timerView: some View {
        CardSection(icon: "timer", color: .purple, title: "Timer") {
            Text("\(exercise.reps) remaining")
                .font(.title2)
                .foregroundColor(.primary)
        }
    }
}
