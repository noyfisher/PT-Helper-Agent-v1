import XCTest
@testable import PT_Helper

// MARK: - UserProfile Tests

final class UserProfileTests: XCTestCase {

    // MARK: - Construction

    func testDefaultUserProfile() {
        let profile = UserProfile(
            userId: "test-uid",
            firstName: "John",
            lastName: "Doe",
            dateOfBirth: Date(),
            sex: "Male",
            heightFeet: 5,
            heightInches: 10,
            weight: 175.0,
            medicalConditions: [],
            otherMedicalConditions: nil,
            surgeries: [],
            injuries: [],
            activityLevel: "Moderately Active",
            primarySport: nil
        )

        XCTAssertEqual(profile.id, "test-uid")
        XCTAssertEqual(profile.firstName, "John")
        XCTAssertEqual(profile.lastName, "Doe")
        XCTAssertEqual(profile.sex, "Male")
        XCTAssertEqual(profile.heightFeet, 5)
        XCTAssertEqual(profile.heightInches, 10)
        XCTAssertEqual(profile.weight, 175.0)
        XCTAssertTrue(profile.medicalConditions.isEmpty)
        XCTAssertNil(profile.otherMedicalConditions)
        XCTAssertTrue(profile.surgeries.isEmpty)
        XCTAssertTrue(profile.injuries.isEmpty)
        XCTAssertEqual(profile.activityLevel, "Moderately Active")
        XCTAssertNil(profile.primarySport)
    }

    func testIdentifiableUsesUserId() {
        let profile = UserProfile(
            userId: "abc-123",
            firstName: "", lastName: "",
            dateOfBirth: Date(), sex: "",
            heightFeet: 0, heightInches: 0, weight: 0,
            medicalConditions: [], otherMedicalConditions: nil,
            surgeries: [], injuries: [],
            activityLevel: "", primarySport: nil
        )
        XCTAssertEqual(profile.id, "abc-123")
    }

    // MARK: - Age Calculation

    func testAgeCalculation_25YearsOld() {
        let calendar = Calendar.current
        let dob = calendar.date(byAdding: .year, value: -25, to: Date())!
        let profile = makeProfile(dateOfBirth: dob)
        XCTAssertEqual(profile.age, 25)
    }

    func testAgeCalculation_NewbornToday() {
        let profile = makeProfile(dateOfBirth: Date())
        XCTAssertEqual(profile.age, 0)
    }

    func testAgeCalculation_Elderly() {
        let calendar = Calendar.current
        let dob = calendar.date(byAdding: .year, value: -80, to: Date())!
        let profile = makeProfile(dateOfBirth: dob)
        XCTAssertEqual(profile.age, 80)
    }

    // MARK: - Nested Types

    func testSurgeryHasUniqueId() {
        let s1 = UserProfile.Surgery(name: "ACL Repair", year: 2020)
        let s2 = UserProfile.Surgery(name: "ACL Repair", year: 2020)
        XCTAssertNotEqual(s1.id, s2.id)
    }

    func testInjuryHasUniqueId() {
        let i1 = UserProfile.Injury(bodyArea: "Knee", description: "Torn meniscus", isCurrent: true)
        let i2 = UserProfile.Injury(bodyArea: "Knee", description: "Torn meniscus", isCurrent: true)
        XCTAssertNotEqual(i1.id, i2.id)
    }

    // MARK: - Mutability

    func testUserIdIsMutable() {
        var profile = makeProfile()
        profile.userId = "new-uid"
        XCTAssertEqual(profile.userId, "new-uid")
        XCTAssertEqual(profile.id, "new-uid")
    }

    func testMedicalConditionsAreMutable() {
        var profile = makeProfile()
        XCTAssertTrue(profile.medicalConditions.isEmpty)
        profile.medicalConditions = ["Diabetes", "Asthma"]
        XCTAssertEqual(profile.medicalConditions.count, 2)
    }

    // MARK: - Helper

    private func makeProfile(
        userId: String = "test",
        dateOfBirth: Date = Date()
    ) -> UserProfile {
        UserProfile(
            userId: userId,
            firstName: "Test", lastName: "User",
            dateOfBirth: dateOfBirth, sex: "Male",
            heightFeet: 5, heightInches: 10, weight: 175,
            medicalConditions: [], otherMedicalConditions: nil,
            surgeries: [], injuries: [],
            activityLevel: "Active", primarySport: nil
        )
    }
}

// MARK: - BodyRegion Tests

final class BodyRegionTests: XCTestCase {

    func testInitDefaults() {
        let region = BodyRegion(
            name: "Right Knee",
            zoneKey: "right_knee",
            sides: [.front, .back],
            frontPosition: CGPoint(x: 0.6, y: 0.7),
            backPosition: CGPoint(x: 0.4, y: 0.7)
        )
        XCTAssertEqual(region.name, "Right Knee")
        XCTAssertEqual(region.zoneKey, "right_knee")
        XCTAssertFalse(region.isSelected, "Regions should start unselected")
        XCTAssertEqual(region.sides.count, 2)
    }

    func testPositionForSide_Front() {
        let frontPos = CGPoint(x: 0.5, y: 0.3)
        let region = BodyRegion(
            name: "Chest", zoneKey: "chest",
            sides: [.front],
            frontPosition: frontPos, backPosition: nil
        )
        XCTAssertEqual(region.position(for: .front), frontPos)
        XCTAssertNil(region.position(for: .back))
    }

    func testPositionForSide_Back() {
        let backPos = CGPoint(x: 0.5, y: 0.4)
        let region = BodyRegion(
            name: "Upper Back", zoneKey: "upper_back",
            sides: [.back],
            frontPosition: nil, backPosition: backPos
        )
        XCTAssertNil(region.position(for: .front))
        XCTAssertEqual(region.position(for: .back), backPos)
    }

    func testPositionForSide_BothSides() {
        let front = CGPoint(x: 0.6, y: 0.7)
        let back = CGPoint(x: 0.4, y: 0.7)
        let region = BodyRegion(
            name: "Right Knee", zoneKey: "right_knee",
            sides: [.front, .back],
            frontPosition: front, backPosition: back
        )
        XCTAssertEqual(region.position(for: .front), front)
        XCTAssertEqual(region.position(for: .back), back)
    }

    func testIsSelectedToggleable() {
        var region = BodyRegion(
            name: "Test", zoneKey: "test",
            sides: [.front], frontPosition: nil, backPosition: nil
        )
        XCTAssertFalse(region.isSelected)
        region.isSelected = true
        XCTAssertTrue(region.isSelected)
        region.isSelected = false
        XCTAssertFalse(region.isSelected)
    }

    func testUniqueIds() {
        let r1 = BodyRegion(name: "A", zoneKey: "a", sides: [.front], frontPosition: nil, backPosition: nil)
        let r2 = BodyRegion(name: "A", zoneKey: "a", sides: [.front], frontPosition: nil, backPosition: nil)
        XCTAssertNotEqual(r1.id, r2.id, "Each region should get a unique UUID")
    }
}

// MARK: - PainAssessment Enum Tests

final class PainAssessmentEnumTests: XCTestCase {

    func testPainTypeCount() {
        XCTAssertEqual(PainAssessment.PainType.allCases.count, 7)
    }

    func testPainTypeDisplayNames() {
        XCTAssertEqual(PainAssessment.PainType.sharp.displayName, "Sharp")
        XCTAssertEqual(PainAssessment.PainType.dull.displayName, "Dull")
        XCTAssertEqual(PainAssessment.PainType.burning.displayName, "Burning")
        XCTAssertEqual(PainAssessment.PainType.throbbing.displayName, "Throbbing")
        XCTAssertEqual(PainAssessment.PainType.aching.displayName, "Aching")
        XCTAssertEqual(PainAssessment.PainType.stabbing.displayName, "Stabbing")
        XCTAssertEqual(PainAssessment.PainType.tingling.displayName, "Tingling")
    }

    func testPainDurationCount() {
        XCTAssertEqual(PainAssessment.PainDuration.allCases.count, 6)
    }

    func testPainFrequencyCount() {
        XCTAssertEqual(PainAssessment.PainFrequency.allCases.count, 5)
    }

    func testPainOnsetCount() {
        XCTAssertEqual(PainAssessment.PainOnset.allCases.count, 5)
    }

    func testAllEnumsHaveNonEmptyDisplayNames() {
        for painType in PainAssessment.PainType.allCases {
            XCTAssertFalse(painType.displayName.isEmpty, "\(painType) has empty display name")
        }
        for duration in PainAssessment.PainDuration.allCases {
            XCTAssertFalse(duration.displayName.isEmpty, "\(duration) has empty display name")
        }
        for frequency in PainAssessment.PainFrequency.allCases {
            XCTAssertFalse(frequency.displayName.isEmpty, "\(frequency) has empty display name")
        }
        for onset in PainAssessment.PainOnset.allCases {
            XCTAssertFalse(onset.displayName.isEmpty, "\(onset) has empty display name")
        }
    }
}

// MARK: - RehabPlan Tests

final class RehabPlanTests: XCTestCase {

    func testRehabExerciseDifficultyCases() {
        XCTAssertEqual(RehabExercise.Difficulty.allCases.count, 3)
        XCTAssertEqual(RehabExercise.Difficulty.beginner.rawValue, "beginner")
        XCTAssertEqual(RehabExercise.Difficulty.intermediate.rawValue, "intermediate")
        XCTAssertEqual(RehabExercise.Difficulty.advanced.rawValue, "advanced")
    }

    func testRehabPlanCreation() {
        let exercise = RehabExercise(
            id: UUID(),
            name: "Quad Sets",
            targetArea: "Knee",
            description: "Tighten your quad.",
            sets: 3,
            reps: "10-15",
            restSeconds: 30,
            difficulty: .beginner,
            demonstrationIcon: "figure.flexibility",
            tips: ["Keep leg straight"],
            contraindications: ["Avoid if swollen"]
        )

        let plan = RehabPlan(
            id: UUID(),
            planName: "Knee Rehab",
            conditions: ["Patellofemoral Pain"],
            exercises: [exercise],
            weeklySchedule: [[], ["ex1"], [], ["ex1"], [], ["ex1"], []],
            totalWeeks: 4,
            createdDate: Date(),
            notes: "Start gently"
        )

        XCTAssertEqual(plan.planName, "Knee Rehab")
        XCTAssertEqual(plan.conditions.count, 1)
        XCTAssertEqual(plan.exercises.count, 1)
        XCTAssertEqual(plan.weeklySchedule.count, 7)
        XCTAssertEqual(plan.totalWeeks, 4)
        XCTAssertEqual(plan.notes, "Start gently")
    }

    func testRehabPlanWithNilNotes() {
        let plan = RehabPlan(
            id: UUID(),
            planName: "Test",
            conditions: [],
            exercises: [],
            weeklySchedule: [],
            totalWeeks: 4,
            createdDate: Date(),
            notes: nil
        )
        XCTAssertNil(plan.notes)
    }
}

// MARK: - ConditionResult Tests

final class ConditionResultTests: XCTestCase {

    func testRedFlagCondition() {
        let condition = ConditionResult(
            id: UUID(),
            conditionName: "Cauda Equina Syndrome",
            commonName: "Spinal Nerve Emergency",
            confidence: 30,
            explanation: "Urgent condition",
            whatItMeans: "Nerves at the base of your spine are being compressed",
            howToManage: "Go to the emergency room right away",
            isRedFlag: true,
            redFlagMessage: "Seek emergency care immediately",
            nextSteps: ["Go to ER"]
        )
        XCTAssertTrue(condition.isRedFlag)
        XCTAssertNotNil(condition.redFlagMessage)
        XCTAssertEqual(condition.commonName, "Spinal Nerve Emergency")
    }

    func testNonRedFlagCondition() {
        let condition = ConditionResult(
            id: UUID(),
            conditionName: "Muscle Strain",
            commonName: "Pulled Muscle",
            confidence: 80,
            explanation: "Common overuse injury",
            whatItMeans: "Some muscle fibers got stretched too far or torn slightly",
            howToManage: "Rest the area and apply ice for 15 minutes a few times a day",
            isRedFlag: false,
            redFlagMessage: nil,
            nextSteps: ["Rest", "Ice", "Stretch"]
        )
        XCTAssertFalse(condition.isRedFlag)
        XCTAssertNil(condition.redFlagMessage)
        XCTAssertEqual(condition.nextSteps.count, 3)
        XCTAssertEqual(condition.commonName, "Pulled Muscle")
        XCTAssertFalse(condition.whatItMeans.isEmpty)
        XCTAssertFalse(condition.howToManage.isEmpty)
    }
}

// MARK: - Note Tests

final class NoteTests: XCTestCase {

    func testNoteCreation() {
        let note = Note(content: "Feeling better today")
        XCTAssertEqual(note.content, "Feeling better today")
        XCTAssertNotNil(note.dateCreated)
    }

    func testNoteUniqueIds() {
        let n1 = Note(content: "A")
        let n2 = Note(content: "B")
        XCTAssertNotEqual(n1.id, n2.id)
    }
}

// MARK: - WorkoutSession Tests

final class WorkoutSessionTests: XCTestCase {

    func testSessionCreation() {
        let session = WorkoutSession(
            id: UUID(),
            date: Date(),
            duration: 1800, // 30 minutes
            painLevel: 5.0,
            isCompleted: true
        )
        XCTAssertEqual(session.duration, 1800)
        XCTAssertEqual(session.painLevel, 5.0)
        XCTAssertTrue(session.isCompleted)
    }
}

// MARK: - ExerciseTimer Tests

final class ExerciseTimerTests: XCTestCase {

    func testTimerInitialization() {
        let timer = ExerciseTimer(duration: 300)
        XCTAssertEqual(timer.duration, 300)
        XCTAssertEqual(timer.timeRemaining, 300)
        XCTAssertFalse(timer.isRunning)
    }

    func testTimerStateChanges() {
        let timer = ExerciseTimer(duration: 60)
        timer.isRunning = true
        XCTAssertTrue(timer.isRunning)
        timer.timeRemaining = 30
        XCTAssertEqual(timer.timeRemaining, 30)
    }
}

// MARK: - AnalysisResult Tests

final class AnalysisResultTests: XCTestCase {

    private func makeProfile() -> UserProfile {
        UserProfile(
            userId: "test",
            firstName: "Test", lastName: "User",
            dateOfBirth: Date(), sex: "Male",
            heightFeet: 5, heightInches: 10, weight: 175,
            medicalConditions: [], otherMedicalConditions: nil,
            surgeries: [], injuries: [],
            activityLevel: "Active", primarySport: nil
        )
    }

    private func makeAssessment() -> PainAssessment {
        let region = BodyRegion(
            name: "Right Knee", zoneKey: "right_knee",
            sides: [.front],
            frontPosition: CGPoint(x: 0.5, y: 0.5),
            backPosition: nil
        )
        return PainAssessment(
            id: UUID(),
            selectedRegion: region,
            painType: .sharp,
            painIntensity: 7,
            painDuration: .twoToFourWeeks,
            painFrequency: .onlyWithActivity,
            painOnset: .gradual,
            aggravatingFactors: ["Running"],
            relievingFactors: ["Rest"],
            additionalNotes: nil
        )
    }

    func testAnalysisResultCreation() {
        let profile = makeProfile()
        let assessment = makeAssessment()
        let condition = ConditionResult(
            id: UUID(),
            conditionName: "Patellofemoral Pain Syndrome",
            commonName: "Runner's Knee",
            confidence: 85,
            explanation: "Test explanation",
            whatItMeans: "The cartilage under your kneecap is irritated",
            howToManage: "Avoid stairs when possible and ice after activity",
            isRedFlag: false,
            redFlagMessage: nil,
            nextSteps: ["Rest", "PT"]
        )

        let result = AnalysisResult(
            id: UUID(),
            assessments: [assessment],
            conditions: [condition],
            overallSummary: "Test summary",
            disclaimerText: "Test disclaimer",
            generatedDate: Date(),
            userProfileSnapshot: profile
        )

        XCTAssertEqual(result.assessments.count, 1)
        XCTAssertEqual(result.conditions.count, 1)
        XCTAssertEqual(result.conditions.first?.conditionName, "Patellofemoral Pain Syndrome")
        XCTAssertEqual(result.conditions.first?.commonName, "Runner's Knee")
        XCTAssertEqual(result.overallSummary, "Test summary")
        XCTAssertEqual(result.disclaimerText, "Test disclaimer")
        XCTAssertEqual(result.userProfileSnapshot.firstName, "Test")
    }

    func testAnalysisResultWithMultipleConditions() {
        let profile = makeProfile()
        let conditions = [
            ConditionResult(id: UUID(), conditionName: "Condition A", commonName: "Common A", confidence: 90, explanation: "A", whatItMeans: "Body info A", howToManage: "Manage A", isRedFlag: false, redFlagMessage: nil, nextSteps: ["Step 1"]),
            ConditionResult(id: UUID(), conditionName: "Condition B", commonName: "Common B", confidence: 70, explanation: "B", whatItMeans: "Body info B", howToManage: "Manage B", isRedFlag: false, redFlagMessage: nil, nextSteps: ["Step 2"]),
            ConditionResult(id: UUID(), conditionName: "Condition C", commonName: "Common C", confidence: 40, explanation: "C", whatItMeans: "Body info C", howToManage: "Manage C", isRedFlag: true, redFlagMessage: "Urgent", nextSteps: ["Step 3"])
        ]

        let result = AnalysisResult(
            id: UUID(),
            assessments: [makeAssessment()],
            conditions: conditions,
            overallSummary: "Multiple conditions found",
            disclaimerText: "Disclaimer",
            generatedDate: Date(),
            userProfileSnapshot: profile
        )

        XCTAssertEqual(result.conditions.count, 3)
        let redFlags = result.conditions.filter { $0.isRedFlag }
        XCTAssertEqual(redFlags.count, 1)
        XCTAssertEqual(redFlags.first?.conditionName, "Condition C")
    }

    func testAnalysisResultPreservesProfileSnapshot() {
        var profile = makeProfile()
        profile.medicalConditions = ["Diabetes", "Asthma"]
        profile.surgeries = [UserProfile.Surgery(name: "Knee Surgery", year: 2020)]

        let result = AnalysisResult(
            id: UUID(),
            assessments: [makeAssessment()],
            conditions: [],
            overallSummary: "Summary",
            disclaimerText: "Disclaimer",
            generatedDate: Date(),
            userProfileSnapshot: profile
        )

        XCTAssertEqual(result.userProfileSnapshot.medicalConditions.count, 2)
        XCTAssertEqual(result.userProfileSnapshot.surgeries.count, 1)
        XCTAssertEqual(result.userProfileSnapshot.surgeries.first?.name, "Knee Surgery")
    }
}
