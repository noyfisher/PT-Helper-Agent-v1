import SwiftUI

struct OnboardingView: View {
    var onComplete: (() -> Void)? = nil
    var onSkip: (() -> Void)? = nil
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with skip
                HStack {
                    Spacer()
                    if let onSkip = onSkip {
                        Button(action: onSkip) {
                            Text("Skip")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Step indicator header
                VStack(spacing: 14) {
                    Text("Step \(viewModel.currentStep) of 6")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(12)

                    HStack(spacing: 6) {
                        ForEach(1...6, id: \.self) { step in
                            Capsule()
                                .fill(step <= viewModel.currentStep ? Color.blue : Color.gray.opacity(0.25))
                                .frame(height: 5)
                                .animation(.spring(response: 0.35), value: viewModel.currentStep)
                        }
                    }
                    .padding(.horizontal, 32)

                    Text(stepTitle)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(stepSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 8)

                // Step content
                TabView(selection: $viewModel.currentStep) {
                    BasicInfoStepView(viewModel: viewModel).tag(1)
                    MedicalHistoryStepView(viewModel: viewModel).tag(2)
                    SurgicalHistoryStepView(viewModel: viewModel).tag(3)
                    InjuryHistoryStepView(viewModel: viewModel).tag(4)
                    ActivityLevelStepView(viewModel: viewModel).tag(5)
                    ProfileReviewStepView(viewModel: viewModel, onComplete: onComplete).tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)

                // Navigation buttons
                HStack(spacing: 12) {
                    if viewModel.currentStep > 1 {
                        Button(action: { viewModel.previousStep() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Back")
                            }
                            .font(.body.weight(.medium))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(14)
                        }
                    }

                    if viewModel.currentStep < 6 {
                        Button(action: { viewModel.nextStep() }) {
                            HStack(spacing: 4) {
                                Text("Continue")
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(14)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }

    private var stepTitle: String {
        switch viewModel.currentStep {
        case 1: return "About You"
        case 2: return "Medical History"
        case 3: return "Past Surgeries"
        case 4: return "Injuries"
        case 5: return "Activity Level"
        case 6: return "Review & Submit"
        default: return ""
        }
    }

    private var stepSubtitle: String {
        switch viewModel.currentStep {
        case 1: return "Let's start with some basic information"
        case 2: return "Select any conditions that apply to you"
        case 3: return "Tell us about any past surgical procedures"
        case 4: return "Any current or previous injuries?"
        case 5: return "How active are you day to day?"
        case 6: return "Make sure everything looks correct"
        default: return ""
        }
    }
}
