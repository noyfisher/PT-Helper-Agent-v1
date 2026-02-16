import SwiftUI

struct SurgicalHistoryStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private var yearRange: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((1950...currentYear).reversed())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Toggle card
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
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
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)

                // Surgery entries
                ForEach(Array(viewModel.userProfile.surgeries.enumerated()), id: \.element.id) { index, surgery in
                    VStack(spacing: 10) {
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
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(14)
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
                    .padding(.vertical, 14)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
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
