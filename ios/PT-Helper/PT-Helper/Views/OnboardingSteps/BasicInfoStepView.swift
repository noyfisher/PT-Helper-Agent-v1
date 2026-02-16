import SwiftUI

struct BasicInfoStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var weightText: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CardSection(icon: "person.fill", color: .blue, title: "Full Name") {
                    VStack(spacing: 10) {
                        StyledTextField(placeholder: "First Name", text: $viewModel.userProfile.firstName)
                        StyledTextField(placeholder: "Last Name", text: $viewModel.userProfile.lastName)
                    }
                }

                CardSection(icon: "calendar", color: .orange, title: "Date of Birth") {
                    DatePicker("", selection: $viewModel.userProfile.dateOfBirth,
                               in: ...Date(),
                               displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                CardSection(icon: "figure.stand", color: .purple, title: "Sex") {
                    HStack(spacing: 10) {
                        ForEach(["Male", "Female", "Other"], id: \.self) { option in
                            Button(action: { viewModel.userProfile.sex = option }) {
                                Text(option)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(viewModel.userProfile.sex == option ? .white : .primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(viewModel.userProfile.sex == option ? Color.purple : Color(.systemGray5))
                                    .cornerRadius(10)
                            }
                        }
                    }
                }

                CardSection(icon: "ruler", color: .green, title: "Height") {
                    HStack(spacing: 12) {
                        Picker("Feet", selection: $viewModel.userProfile.heightFeet) {
                            ForEach(3..<8) { Text("\($0) ft").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .clipped()

                        Picker("Inches", selection: $viewModel.userProfile.heightInches) {
                            ForEach(0..<12) { Text("\($0) in").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .clipped()
                    }
                }

                CardSection(icon: "scalemass", color: .teal, title: "Weight") {
                    HStack {
                        TextField("Enter weight", text: $weightText)
                            .keyboardType(.decimalPad)
                            .font(.title3.weight(.medium))
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .onChange(of: weightText) { newValue in
                                if let val = Double(newValue) {
                                    viewModel.userProfile.weight = val
                                }
                            }
                        Text("lbs")
                            .foregroundColor(.secondary)
                            .font(.body.weight(.medium))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            if viewModel.userProfile.weight > 0 {
                weightText = String(Int(viewModel.userProfile.weight))
            }
        }
    }
}

// MARK: - Reusable Components

struct CardSection<Content: View>: View {
    let icon: String
    let color: Color
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.15))
                    .cornerRadius(7)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            content
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

struct StyledTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
    }
}
