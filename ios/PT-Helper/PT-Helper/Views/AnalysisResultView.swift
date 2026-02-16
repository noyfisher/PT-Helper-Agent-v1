import SwiftUI

struct AnalysisResultView: View {
    let analysisResult: AnalysisResult
    @State private var showRehabPlan = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    if analysisResult.conditions.contains(where: { $0.isRedFlag }) {
                        redFlagAlert
                    }
                    disclaimerBanner
                    overallSummaryCard
                    ForEach(Array(analysisResult.conditions.prefix(3))) { condition in
                        conditionCard(for: condition)
                    }
                    buildRehabPlanButton
                }
                .padding(20)
            }
        }
        .navigationTitle("Analysis Results")
        .sheet(isPresented: $showRehabPlan) {
            NavigationView {
                RehabPlanView()
            }
        }
    }

    private var disclaimerBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamation.triangle.fill")
                .foregroundColor(.orange)
            Text("This is not a medical diagnosis. Always consult a healthcare professional.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(14)
    }

    private var overallSummaryCard: some View {
        CardSection(icon: "note.text", color: .blue, title: "Overall Summary") {
            Text(analysisResult.overallSummary)
                .font(.body)
                .foregroundColor(.primary)
        }
    }

    private func conditionCard(for condition: ConditionResult) -> some View {
        CardSection(icon: "star.fill", color: .green, title: condition.conditionName) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Confidence: \(Int(condition.confidence))%")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    ProgressView(value: condition.confidence, total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: condition.confidence > 60 ? .green : .orange))
                        .frame(width: 100)
                }
                Text(condition.explanation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if condition.isRedFlag {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamation.triangle.fill")
                            .font(.caption2)
                        Text("Seek Immediate Care")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                DisclosureGroup("Next Steps") {
                    ForEach(condition.nextSteps, id: \.self) { step in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                            Text(step)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var redFlagAlert: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamation.triangle.fill")
                .font(.title2)
                .foregroundColor(.red)
            VStack(alignment: .leading, spacing: 4) {
                Text("Urgent Attention Needed")
                    .font(.headline)
                    .foregroundColor(.red)
                Text(analysisResult.conditions.first(where: { $0.isRedFlag })?.redFlagMessage ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(14)
    }

    private var buildRehabPlanButton: some View {
        Button(action: { showRehabPlan = true }) {
            Text("Build Rehab Plan")
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
        .padding(.top, 16)
    }
}
