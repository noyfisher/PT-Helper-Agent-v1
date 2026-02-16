import SwiftUI

struct PainDetailView: View {
    @ObservedObject var viewModel: InjuryAnalysisViewModel
    @State private var selectedPainType: PainAssessment.PainType = .sharp
    @State private var painIntensity: Double = 5
    @State private var selectedPainDuration: PainAssessment.PainDuration = .today
    @State private var selectedPainFrequency: PainAssessment.PainFrequency = .constant
    @State private var selectedPainOnset: PainAssessment.PainOnset = .sudden
    @State private var aggravatingFactors: [String] = []
    @State private var relievingFactors: [String] = []
    @State private var additionalNotes: String = ""

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            // Hidden navigation link — activates when analysis completes
            if let result = viewModel.analysisResult {
                NavigationLink(
                    destination: AnalysisResultView(analysisResult: result),
                    isActive: Binding(
                        get: { viewModel.analysisResult != nil },
                        set: { if !$0 { viewModel.analysisResult = nil } }
                    )
                ) {
                    EmptyView()
                }
            }

            ScrollView {
                VStack(spacing: 16) {
                    // Progress indicator
                    if !viewModel.selectedRegionNames.isEmpty {
                        HStack {
                            Text("Region \(viewModel.currentRegionIndex + 1) of \(viewModel.totalRegions)")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.blue)
                                .cornerRadius(12)
                            Spacer()
                        }
                    }

                    if let currentRegion = viewModel.currentRegion {
                        CardSection(icon: "figure.walk", color: .blue, title: "Assessing: \(currentRegion.name)") {
                            painTypeSelection
                            painIntensitySlider
                            painDurationPicker
                            painFrequencyPicker
                            painOnsetPicker
                            aggravatingFactorsSelection
                            relievingFactorsSelection
                            additionalNotesField
                        }
                        navigationButtons
                    } else if viewModel.analysisResult == nil {
                        Text("No region selected")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Pain Assessment")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var painTypeSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pain Type")
                .font(.headline)
            HStack {
                ForEach(PainAssessment.PainType.allCases, id: \.self) { type in
                    Button(action: { selectedPainType = type }) {
                        Image(systemName: iconName(for: type))
                            .padding()
                            .background(selectedPainType == type ? Color.blue : Color(.systemGray5))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }

    private var painIntensitySlider: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pain Intensity")
                .font(.headline)
            Slider(value: $painIntensity, in: 1...10, step: 1)
                .accentColor(.red)
            Text("Intensity: \(Int(painIntensity))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var painDurationPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pain Duration")
                .font(.headline)
            Picker("Duration", selection: $selectedPainDuration) {
                ForEach(PainAssessment.PainDuration.allCases, id: \.self) { duration in
                    Text(duration.displayName).tag(duration)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    private var painFrequencyPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pain Frequency")
                .font(.headline)
            Picker("Frequency", selection: $selectedPainFrequency) {
                ForEach(PainAssessment.PainFrequency.allCases, id: \.self) { frequency in
                    Text(frequency.displayName).tag(frequency)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    private var painOnsetPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pain Onset")
                .font(.headline)
            Picker("Onset", selection: $selectedPainOnset) {
                ForEach(PainAssessment.PainOnset.allCases, id: \.self) { onset in
                    Text(onset.displayName).tag(onset)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    private var aggravatingFactorsSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Aggravating Factors")
                .font(.headline)
            ForEach(["Walking", "Sitting", "Lifting", "Twisting", "Climbing stairs", "Running", "Reaching overhead"], id: \.self) { factor in
                Toggle(isOn: Binding(
                    get: { aggravatingFactors.contains(factor) },
                    set: { isSelected in
                        if isSelected {
                            aggravatingFactors.append(factor)
                        } else {
                            aggravatingFactors.removeAll { $0 == factor }
                        }
                    }
                )) {
                    Text(factor)
                }
            }
        }
    }

    private var relievingFactorsSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Relieving Factors")
                .font(.headline)
            ForEach(["Rest", "Ice", "Heat", "Stretching", "Medication", "Elevation"], id: \.self) { factor in
                Toggle(isOn: Binding(
                    get: { relievingFactors.contains(factor) },
                    set: { isSelected in
                        if isSelected {
                            relievingFactors.append(factor)
                        } else {
                            relievingFactors.removeAll { $0 == factor }
                        }
                    }
                )) {
                    Text(factor)
                }
            }
        }
    }

    private var additionalNotesField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Additional Notes")
                .font(.headline)
            TextField("Enter any additional notes", text: $additionalNotes)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }

    private var navigationButtons: some View {
        HStack {
            if viewModel.currentRegionIndex > 0 {
                Button("Back") {
                    viewModel.currentRegionIndex -= 1
                }
                .buttonStyle(.bordered)
            }
            Spacer()
            if viewModel.isLastRegion {
                Button("Review & Analyze") {
                    let assessment = PainAssessment(
                        id: UUID(),
                        selectedRegion: viewModel.currentRegion!,
                        painType: selectedPainType,
                        painIntensity: Int(painIntensity),
                        painDuration: selectedPainDuration,
                        painFrequency: selectedPainFrequency,
                        painOnset: selectedPainOnset,
                        aggravatingFactors: aggravatingFactors,
                        relievingFactors: relievingFactors,
                        additionalNotes: additionalNotes
                    )
                    viewModel.addAssessment(assessment)
                    viewModel.analyze()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Next") {
                    let assessment = PainAssessment(
                        id: UUID(),
                        selectedRegion: viewModel.currentRegion!,
                        painType: selectedPainType,
                        painIntensity: Int(painIntensity),
                        painDuration: selectedPainDuration,
                        painFrequency: selectedPainFrequency,
                        painOnset: selectedPainOnset,
                        aggravatingFactors: aggravatingFactors,
                        relievingFactors: relievingFactors,
                        additionalNotes: additionalNotes
                    )
                    viewModel.addAssessment(assessment)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func iconName(for type: PainAssessment.PainType) -> String {
        switch type {
        case .sharp: return "bolt.fill"
        case .dull: return "cloud.fill"
        case .burning: return "flame.fill"
        case .throbbing: return "waveform.path.ecg"
        case .aching: return "tortoise.fill"
        case .stabbing: return "scissors"
        case .tingling: return "sparkles"
        }
    }
}
