import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @StateObject private var savedPlansViewModel = SavedPlansViewModel()
    @State private var userName: String = ""
    @State private var showOnboarding = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Welcome header
                        VStack(spacing: 6) {
                            Text(greetingText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(userName.isEmpty ? "Welcome!" : "Hi, \(userName)!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                        .padding(.bottom, 8)

                        // Quick Actions header
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.blue)
                            Text("Quick Actions")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)

                        // Quick actions
                        VStack(spacing: 12) {
                            // Injury Analysis
                            NavigationLink(destination: BodyMapView()) {
                                HStack(spacing: 14) {
                                    Image(systemName: "figure.run.circle")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            LinearGradient(
                                                colors: [.red, .orange],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .cornerRadius(14)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Injury Analysis")
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(.primary)
                                        Text("Assess pain and get guidance")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                .padding(16)
                                .background(Color(.systemBackground))
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                            }

                            // Update Health Info
                            Button(action: { showOnboarding = true }) {
                                HStack(spacing: 14) {
                                    Image(systemName: "heart.text.clipboard")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            LinearGradient(
                                                colors: [.blue, .cyan],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .cornerRadius(14)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Update Health Info")
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(.primary)
                                        Text("Review or update your health profile")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                .padding(16)
                                .background(Color(.systemBackground))
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                            }

                            // Recovery Notes
                            NavigationLink(destination: NotesView()) {
                                HStack(spacing: 14) {
                                    Image(systemName: "note.text")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            LinearGradient(
                                                colors: [.green, .mint],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .cornerRadius(14)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Recovery Notes")
                                            .font(.body.weight(.semibold))
                                            .foregroundColor(.primary)
                                        Text("Track your recovery journey")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                .padding(16)
                                .background(Color(.systemBackground))
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                            }
                        }
                        .padding(.horizontal, 20)

                        // My Rehab Plans section
                        myRehabPlansSection
                            .padding(.horizontal, 20)

                        Spacer(minLength: 40)

                        // Sign out
                        Button(action: {
                            try? Auth.auth().signOut()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 14))
                                Text("Sign Out")
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundColor(.red)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("PT Helper")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchUserName()
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingEditView()
            }
        }
    }

    // MARK: - My Rehab Plans

    private var myRehabPlansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "list.clipboard.fill")
                    .foregroundColor(.purple)
                Text("My Rehab Plans")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }

            if savedPlansViewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 20)
            } else if savedPlansViewModel.rehabPlans.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No Rehab Plans Yet")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.secondary)
                    Text("Complete an injury analysis to get a personalized plan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            } else {
                ForEach(savedPlansViewModel.rehabPlans) { plan in
                    NavigationLink(destination: RehabPlanView()) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(plan.planName)
                                .font(.body.weight(.semibold))
                                .foregroundColor(.primary)
                            HStack(spacing: 6) {
                                ForEach(plan.conditions, id: \.self) { condition in
                                    Text(condition)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                            Text(plan.createdDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    private func fetchUserName() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).collection("profile").document("health").getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user name: \(error.localizedDescription)")
            } else if let snapshot = snapshot, let data = snapshot.data() {
                let first = data["firstName"] as? String ?? ""
                userName = first.isEmpty ? (data["name"] as? String ?? "") : first
            }
        }
    }
}

// MARK: - Onboarding Edit Wrapper (for updating profile from home)
struct OnboardingEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading your profile...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 0) {
                    // Top bar with close button
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("Update Profile")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.clear)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    // Step indicator
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
                        ProfileReviewStepView(viewModel: viewModel, onComplete: {
                            dismiss()
                        }).tag(6)
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
        .onAppear {
            viewModel.loadProfile { success in
                viewModel.currentStep = 1
                isLoading = false
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
