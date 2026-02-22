import SwiftUI

struct InjuryHistoryStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header card
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Any current or past injuries?")
                            .font(.body.weight(.medium))
                        Text(viewModel.userProfile.injuries.isEmpty ? "Tap to add" : "\(viewModel.userProfile.injuries.count) recorded")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: viewModel.userProfile.injuries.isEmpty ? "cross.case" : "cross.case.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                .padding(AppSpacing.lg)
                .background(AppColors.cardBackground)
                .cornerRadius(AppCorners.card)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)

                // Injury entries
                ForEach(Array(viewModel.userProfile.injuries.enumerated()), id: \.element.id) { index, injury in
                    VStack(spacing: AppSpacing.sm) {
                        HStack {
                            Text("Injury \(index + 1)")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.red)
                            Spacer()
                            Button(action: {
                                viewModel.userProfile.injuries.remove(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }

                        StyledTextField(placeholder: "Body area (e.g. Left Knee)", text: Binding(
                            get: { viewModel.userProfile.injuries[safe: index]?.bodyArea ?? "" },
                            set: { if index < viewModel.userProfile.injuries.count { viewModel.userProfile.injuries[index].bodyArea = $0 } }
                        ))

                        StyledTextField(placeholder: "Description", text: Binding(
                            get: { viewModel.userProfile.injuries[safe: index]?.description ?? "" },
                            set: { if index < viewModel.userProfile.injuries.count { viewModel.userProfile.injuries[index].description = $0 } }
                        ))

                        // Current / Past toggle
                        HStack(spacing: AppSpacing.sm) {
                            let isCurrent = viewModel.userProfile.injuries[safe: index]?.isCurrent ?? false
                            ForEach(["Current", "Past"], id: \.self) { label in
                                let selected = (label == "Current") == isCurrent
                                Button(action: {
                                    if index < viewModel.userProfile.injuries.count {
                                        viewModel.userProfile.injuries[index].isCurrent = (label == "Current")
                                    }
                                }) {
                                    Text(label)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(selected ? .white : .primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, AppSpacing.sm)
                                        .background(selected ? Color.red.opacity(0.8) : AppColors.subtleBorder)
                                        .cornerRadius(AppCorners.small)
                                }
                            }
                        }
                    }
                    .padding(AppSpacing.lg)
                    .background(AppColors.cardBackground)
                    .cornerRadius(AppCorners.card)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                }

                // Add button
                Button(action: {
                    viewModel.userProfile.injuries.append(UserProfile.Injury(bodyArea: "", description: "", isCurrent: true))
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Injury")
                    }
                    .font(.body.weight(.medium))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(AppCorners.medium)
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.md)
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
