import Foundation
import SwiftUI

class InjuryAnalysisViewModel: ObservableObject {
    @Published var assessments: [PainAssessment] = []
    @Published var currentRegionIndex: Int = 0
    @Published var analysisResult: AnalysisResult?

    private let userProfile: UserProfile
    private let selectedRegions: [BodyRegion]

    init(userProfile: UserProfile, selectedRegions: [BodyRegion]) {
        self.userProfile = userProfile
        self.selectedRegions = selectedRegions
    }

    func addAssessment(_ assessment: PainAssessment) {
        assessments.append(assessment)
        currentRegionIndex += 1
    }

    func analyze() {
        analysisResult = InjuryAnalyzer.analyze(assessments: assessments, profile: userProfile)
    }

    var currentRegion: BodyRegion? {
        guard currentRegionIndex < selectedRegions.count else { return nil }
        return selectedRegions[currentRegionIndex]
    }

    var isLastRegion: Bool {
        return currentRegionIndex == selectedRegions.count - 1
    }

    var totalRegions: Int {
        return selectedRegions.count
    }

    var selectedRegionNames: [String] {
        return selectedRegions.map { $0.name }
    }
}
