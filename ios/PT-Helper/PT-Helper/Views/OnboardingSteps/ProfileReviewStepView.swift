import SwiftUI

struct ProfileReviewStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onComplete: (() -> Void)? = nil
    @State private var isSaving = false
    @State private var showSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Basic info
                ReviewCard(title: "Personal Info", icon: "person.fill", color: .blue) {
                    ReviewRow(label: "Name", value: "\(viewModel.userProfile.firstName) \(viewModel.userProfile.lastName)")
                    ReviewRow(label: "Date of Birth", value: viewModel.userProfile.dateOfBirth.formatted(date: .abbreviated, time: .omitted))
                    ReviewRow(label: "Sex", value: viewModel.userProfile.sex)
                    ReviewRow(label: "Height", value: "\(viewModel.userProfile.heightFeet)' \(viewModel.userProfile.heightInches)\"")
                    ReviewRow(label: "Weight", value: "\(Int(viewModel.userProfile.weight)) lbs")
                }

                // Medical
                ReviewCard(title: "Medical History", icon: "heart.fill", color: .red) {
                    if viewModel.userProfile.medicalConditions.isEmpty {
                        ReviewRow(label: "Conditions", value: "None reported")
                    } else {
                        ReviewRow(label: "Conditions", value: viewModel.userProfile.medicalConditions.joined(separator: ", "))
                    }
                    if let other = viewModel.userProfile.otherMedicalConditions, !other.isEmpty {
                        ReviewRow(label: "Other", value: other)
                    }
                }

                // Surgeries
                ReviewCard(title: "Surgical History", icon: "bandage.fill", color: .orange) {
                    if viewModel.userProfile.surgeries.isEmpty {
                        ReviewRow(label: "", value: "No surgeries reported")
                    } else {
                        ForEach(viewModel.userProfile.surgeries) { surgery in
                            ReviewRow(label: surgery.name, value: "\(surgery.year)")
                        }
                    }
                }

                // Injuries
                ReviewCard(title: "Injuries", icon: "cross.case.fill", color: .red) {
                    if viewModel.userProfile.injuries.isEmpty {
                        ReviewRow(label: "", value: "No injuries reported")
                    } else {
                        ForEach(viewModel.userProfile.injuries) { injury in
                            ReviewRow(label: "\(injury.bodyArea) (\(injury.isCurrent ? "Current" : "Past"))", value: injury.description)
                        }
                    }
                }

                // Activity
                ReviewCard(title: "Activity Level", icon: "figure.run", color: .green) {
                    ReviewRow(label: "Level", value: viewModel.userProfile.activityLevel.isEmpty ? "Not set" : viewModel.userProfile.activityLevel)
                    if let sport = viewModel.userProfile.primarySport, !sport.isEmpty {
                        ReviewRow(label: "Sport", value: sport)
                    }
                }

                // Submit button
                Button(action: {
                    isSaving = true
                    viewModel.saveProfile { success in
                        isSaving = false
                        if success {
                            showSuccess = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                onComplete?()
                            }
                        }
                    }
                }) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else if showSuccess {
                            Image(systemName: "checkmark")
                                .font(.body.weight(.bold))
                            Text("Saved!")
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Submit Profile")
                        }
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(showSuccess ? Color.green.opacity(0.8) : Color.green)
                    .cornerRadius(14)
                }
                .disabled(isSaving || showSuccess)
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
}

struct ReviewCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 26, height: 26)
                    .background(color.opacity(0.15))
                    .cornerRadius(6)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            Divider()
            content
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

struct ReviewRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            if !label.isEmpty {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

