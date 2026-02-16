import SwiftUI

struct MedicalHistoryStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    let conditions: [(String, String)] = [
        ("Diabetes", "drop.fill"),
        ("High Blood Pressure", "heart.fill"),
        ("Asthma", "lungs.fill"),
        ("Heart Disease", "waveform.path.ecg"),
        ("Arthritis", "figure.walk"),
        ("None", "checkmark.shield.fill")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(conditions, id: \.0) { condition, icon in
                        let isSelected = viewModel.userProfile.medicalConditions.contains(condition)
                        Button(action: { toggleCondition(condition) }) {
                            HStack(spacing: 8) {
                                Image(systemName: icon)
                                    .font(.system(size: 14))
                                Text(condition)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundColor(isSelected ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 8)
                            .background(isSelected ? Color.blue : Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(isSelected ? 0 : 0.04), radius: 6, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                }

                CardSection(icon: "plus.circle.fill", color: .orange, title: "Other Conditions") {
                    TextField("e.g. Epilepsy, Thyroid issues...", text: $viewModel.userProfile.otherMedicalConditions.bound)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    private func toggleCondition(_ condition: String) {
        if condition == "None" {
            viewModel.userProfile.medicalConditions = ["None"]
            return
        }
        viewModel.userProfile.medicalConditions.removeAll { $0 == "None" }
        if viewModel.userProfile.medicalConditions.contains(condition) {
            viewModel.userProfile.medicalConditions.removeAll { $0 == condition }
        } else {
            viewModel.userProfile.medicalConditions.append(condition)
        }
    }
}

extension Optional where Wrapped == String {
    var bound: String {
        get { self ?? "" }
        set { self = newValue.isEmpty ? nil : newValue }
    }
}
