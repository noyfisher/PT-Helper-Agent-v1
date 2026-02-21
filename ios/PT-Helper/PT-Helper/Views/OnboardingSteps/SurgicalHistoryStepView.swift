import SwiftUI

struct SurgicalHistoryStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private var yearRange: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((1950...currentYear).reversed())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Toggle card
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Have you had any surgeries?")
                            .font(.body.weight(.medium))
                        Text(viewModel.userProfile.surgeries.isEmpty ? "Tap to add" : "\(viewModel.userProfile.surgeries.count) recorded")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: viewModel.userProfile.surgeries.isEmpty ? "bandage" : "bandage.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
                .padding(AppSpacing.lg)
                .background(AppColors.cardBackground)
                .cornerRadius(AppCorners.card)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)

                // Surgery entries
                ForEach(Array(viewModel.userProfile.surgeries.enumerated()), id: \.element.id) { index, surgery in
                    VStack(spacing: AppSpacing.sm) {
                        HStack {
                            Text("Surgery \(index + 1)")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.orange)
                            Spacer()
                            Button(action: {
                                viewModel.userProfile.surgeries.remove(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }

                        StyledTextField(placeholder: "Name of surgery", text: Binding(
                            get: { viewModel.userProfile.surgeries[safe: index]?.name ?? "" },
                            set: { if index < viewModel.userProfile.surgeries.count { viewModel.userProfile.surgeries[index].name = $0 } }
                        ))

                        // Year picker
                        HStack {
                            Text("Year")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Picker("Year", selection: Binding(
                                get: { viewModel.userProfile.surgeries[safe: index]?.year ?? Calendar.current.component(.year, from: Date()) },
                                set: { if index < viewModel.userProfile.surgeries.count { viewModel.userProfile.surgeries[index].year = $0 } }
                            )) {
                                ForEach(yearRange, id: \.self) { year in
                                    Text(String(year)).tag(year)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.orange)
                        }
                        .padding(AppSpacing.md)
                        .background(AppColors.inputBackground)
                        .cornerRadius(AppCorners.medium)
                    }
                    .padding(AppSpacing.lg)
                    .background(AppColors.cardBackground)
                    .cornerRadius(AppCorners.card)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                }

                // Add button
                Button(action: {
                    let currentYear = Calendar.current.component(.year, from: Date())
                    viewModel.userProfile.surgeries.append(UserProfile.Surgery(name: "", year: currentYear))
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Surgery")
                    }
                    .font(.body.weight(.medium))
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                    .background(Color.orange.opacity(0.1))
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

// MARK: - Safe array subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
