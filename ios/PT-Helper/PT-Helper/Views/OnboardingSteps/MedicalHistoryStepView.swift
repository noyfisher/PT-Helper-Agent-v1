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
            VStack(spacing: AppSpacing.md) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                    ForEach(conditions, id: \.0) { condition, icon in
                        let isSelected = viewModel.userProfile.medicalConditions.contains(condition)
                        Button(action: { toggleCondition(condition) }) {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: icon)
                                    .font(.system(size: 14))
                                Text(condition)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundColor(isSelected ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.lg)
                            .padding(.horizontal, AppSpacing.sm)
                            .background(isSelected ? Color.blue : AppColors.cardBackground)
                            .cornerRadius(AppCorners.medium)
                            .shadow(color: .black.opacity(isSelected ? 0 : 0.04), radius: 6, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppCorners.medium)
                                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                }

                CardSection(icon: "plus.circle.fill", color: .orange, title: "Other Conditions") {
                    TextField("e.g. Epilepsy, Thyroid issues...", text: $viewModel.userProfile.otherMedicalConditions.bound)
                        .padding(AppSpacing.md)
                        .background(AppColors.inputBackground)
                        .cornerRadius(AppCorners.medium)
                }
                .padding(.top, AppSpacing.sm)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.md)
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
