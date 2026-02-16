import SwiftUI
import Foundation
import FirebaseFirestore
import FirebaseAuth

class RehabPlanViewModel: ObservableObject {
    @Published var rehabPlan: RehabPlan?
    @Published var isSaving = false
    @Published var showSaveSuccess = false

    // Exercise database organized by condition name
    private let exerciseDatabase: [String: [RehabExercise]] = [
        "Patellofemoral Pain Syndrome": [
            RehabExercise(id: UUID(), name: "Quad Sets", targetArea: "Knee", description: "Sit with your leg straight. Tighten the muscle on top of your thigh by pressing the back of your knee into the floor. Hold for 5 seconds, then relax.", sets: 3, reps: "10-15", restSeconds: 30, difficulty: .beginner, demonstrationIcon: "figure.flexibility", tips: ["Keep your leg straight.", "Press knee firmly into the floor.", "You should see your kneecap move upward."], contraindications: ["Avoid if acute knee swelling is present."]),
            RehabExercise(id: UUID(), name: "Straight Leg Raises", targetArea: "Knee", description: "Lie on your back with one knee bent. Keeping the other leg straight, tighten the quad and lift the leg to 45 degrees. Hold 2 seconds, lower slowly.", sets: 3, reps: "10-12", restSeconds: 30, difficulty: .beginner, demonstrationIcon: "figure.strengthtraining.traditional", tips: ["Keep your core engaged.", "Lift slowly and with control.", "Don't arch your back."], contraindications: ["Avoid if hip pain worsens."]),
            RehabExercise(id: UUID(), name: "Wall Sits", targetArea: "Knee", description: "Stand with your back against a wall. Slide down until your knees are bent to about 45 degrees. Hold the position.", sets: 3, reps: "30 seconds", restSeconds: 45, difficulty: .intermediate, demonstrationIcon: "figure.cooldown", tips: ["Keep knees behind toes.", "Press your back flat against the wall.", "Start with a shallow bend and go deeper as you get stronger."], contraindications: ["Avoid deep bending if knee pain increases."]),
            RehabExercise(id: UUID(), name: "Clamshells", targetArea: "Hip/Knee", description: "Lie on your side with knees bent to 45 degrees. Keeping your feet together, raise your top knee as high as you can without rotating your pelvis. Lower slowly.", sets: 3, reps: "12-15", restSeconds: 30, difficulty: .beginner, demonstrationIcon: "figure.flexibility", tips: ["Keep your feet together throughout.", "Don't roll your hips backward.", "Focus on squeezing the glute."], contraindications: ["Avoid if hip pain is present."])
        ],
        "Meniscus Tear": [
            RehabExercise(id: UUID(), name: "Heel Slides", targetArea: "Knee", description: "Lie on your back. Slowly slide your heel toward your buttock, bending your knee. Slide back to the starting position.", sets: 3, reps: "10-12", restSeconds: 30, difficulty: .beginner, demonstrationIcon: "figure.flexibility", tips: ["Move slowly and smoothly.", "Only go as far as comfortable.", "Use a towel under your heel to reduce friction."], contraindications: ["Stop if you feel locking or catching."]),
            RehabExercise(id: UUID(), name: "Step-Ups", targetArea: "Knee", description: "Step up onto a low step with your affected leg. Straighten your knee fully, then step back down slowly.", sets: 3, reps: "10", restSeconds: 45, difficulty: .intermediate, demonstrationIcon: "figure.stairs", tips: ["Use a handrail for balance.", "Keep your knee aligned over your toes.", "Control the descent."], contraindications: ["Avoid if knee gives way or locks."])
        ],
        "Rotator Cuff Strain": [
            RehabExercise(id: UUID(), name: "Pendulum Swings", targetArea: "Shoulder", description: "Lean forward with your unaffected hand on a table. Let your affected arm hang down and swing in small circles, then back and forth.", sets: 2, reps: "30 seconds each direction", restSeconds: 30, difficulty: .beginner, demonstrationIcon: "figure.cooldown", tips: ["Keep your arm relaxed.", "Let gravity do the work.", "Gradually increase the circle size."], contraindications: ["Avoid if severe shoulder pain is present."]),
            RehabExercise(id: UUID(), name: "External Rotation", targetArea: "Shoulder", description: "Stand with your elbow bent 90 degrees at your side. Rotate your forearm outward away from your body, keeping elbow tucked.", sets: 3, reps: "12-15", restSeconds: 30, difficulty: .beginner, demonstrationIcon: "figure.strengthtraining.traditional", tips: ["Keep your elbow at your side.", "Move slowly with control.", "Use a light resistance band if available."], contraindications: ["Stop if sharp pain occurs."]),
            RehabExercise(id: UUID(), name: "Scapular Squeezes", targetArea: "Upper Back/Shoulder", description: "Sit or stand with arms at your sides. Squeeze your shoulder blades together as if pinching a pencil between them. Hold 5 seconds.", sets: 3, reps: "10-12", restSeconds: 30, difficulty: .beginner, demonstrationIcon: "figure.cooldown", tips: ["Keep shoulders down, away from ears.", "Don't shrug.", "Breathe normally while holding."], contraindications: ["Avoid if thoracic spine pain increases."]),
            RehabExercise(id: UUID(), name: "Wall Slides", targetArea: "Shoulder", description: "Stand with your back against a wall, arms in a goalpost position. Slowly slide arms up the wall overhead, then back down.", sets: 3, reps: "10", restSeconds: 30, difficulty: .intermediate, demonstrationIcon: "figure.flexibility", tips: ["Keep your back flat against the wall.", "Only go as high as comfortable.", "Focus on smooth movement."], contraindications: ["Avoid if impingement symptoms worsen."])
        ],
        "Muscle Strain": [
            RehabExercise(id: UUID(), name: "Cat-Cow Stretch", targetArea: "Back", description: "On hands and knees, alternate between arching your back up (cat) and letting it sag down (cow). Move slowly with your breath.", sets: 2, reps: "10", restSeconds: 20, difficulty: .beginner, demonstrationIcon: "figure.flexibility", tips: ["Inhale on cow, exhale on cat.", "Move through each position slowly.", "Keep your core lightly engaged."], contraindications: ["Avoid if back pain significantly worsens."]),
            RehabExercise(id: UUID(), name: "Glute Bridges", targetArea: "Back/Glutes", description: "Lie on your back with knees bent. Squeeze your glutes and lift your hips toward the ceiling. Hold 2 seconds at the top.", sets: 3, reps: "12-15", restSeconds: 30, difficulty: .beginner, demonstrationIcon: "figure.strengthtraining.traditional", tips: ["Don't arch your lower back excessively.", "Squeeze glutes at the top.", "Keep your core engaged."], contraindications: ["Avoid if acute back spasm is present."]),
            RehabExercise(id: UUID(), name: "Bird Dog", targetArea: "Core/Back", description: "On hands and knees, extend one arm forward and the opposite leg backward. Hold for 3 seconds, return, and switch sides.", sets: 3, reps: "8 each side", restSeconds: 30, difficulty: .intermediate, demonstrationIcon: "figure.yoga", tips: ["Keep your back flat like a table.", "Don't rotate your hips.", "Engage your core throughout."], contraindications: ["Modify if shoulder or hip pain occurs."])
        ],
        "Herniated Disc": [
            RehabExercise(id: UUID(), name: "Pelvic Tilts", targetArea: "Lower Back", description: "Lie on your back with knees bent. Flatten your lower back against the floor by tilting your pelvis. Hold 5 seconds.", sets: 3, reps: "10-12", restSeconds: 20, difficulty: .beginner, demonstrationIcon: "figure.flexibility", tips: ["Think of pulling your belly button to your spine.", "Breathe normally.", "The movement is subtle."], contraindications: ["Stop if radiating leg pain worsens."]),
            RehabExercise(id: UUID(), name: "Child's Pose", targetArea: "Lower Back", description: "Kneel on the floor, sit back on your heels, and stretch your arms forward on the floor. Hold the position and breathe deeply.", sets: 2, reps: "30 seconds", restSeconds: 20, difficulty: .beginner, demonstrationIcon: "figure.yoga", tips: ["Relax into the stretch.", "Breathe deeply.", "Widen your knees if needed."], contraindications: ["Avoid if knee pain prevents kneeling."])
        ],
        "Impingement Syndrome": [
            RehabExercise(id: UUID(), name: "Doorway Stretch", targetArea: "Chest/Shoulder", description: "Stand in a doorway with arms on the frame at 90 degrees. Step forward to stretch the front of your shoulders and chest.", sets: 3, reps: "30 seconds", restSeconds: 20, difficulty: .beginner, demonstrationIcon: "figure.flexibility", tips: ["Keep your core tight.", "Don't lean too far forward.", "You should feel the stretch across your chest."], contraindications: ["Avoid if shoulder pops or clicks."])
        ],
        "ACL Sprain": [
            RehabExercise(id: UUID(), name: "Hamstring Curls", targetArea: "Knee/Hamstring", description: "Stand holding a chair for balance. Slowly bend your knee to bring your heel toward your buttock. Lower slowly.", sets: 3, reps: "12-15", restSeconds: 30, difficulty: .beginner, demonstrationIcon: "figure.strengthtraining.traditional", tips: ["Keep your thighs parallel.", "Control the movement.", "Use ankle weights for progression."], contraindications: ["Avoid if knee instability is severe."])
        ]
    ]

    func generateRehabPlan(from analysisResult: AnalysisResult) {
        let conditions = analysisResult.conditions.map { $0.conditionName }
        let exercises = conditions.flatMap { exerciseDatabase[$0] ?? [] }

        // If no exercises found for exact condition names, provide general exercises
        let finalExercises = exercises.isEmpty ? getGeneralExercises() : exercises

        let weeklySchedule = createWeeklySchedule(
            for: finalExercises,
            activityLevel: analysisResult.userProfileSnapshot.activityLevel
        )

        rehabPlan = RehabPlan(
            id: UUID(),
            planName: "Personalized Rehab Plan",
            conditions: conditions,
            exercises: finalExercises,
            weeklySchedule: weeklySchedule,
            totalWeeks: 4,
            createdDate: Date(),
            notes: nil
        )
    }

    private func createWeeklySchedule(for exercises: [RehabExercise], activityLevel: String) -> [[String]] {
        let exerciseDays: Int
        switch activityLevel.lowercased() {
        case "sedentary", "lightly active":
            exerciseDays = 3
        case "moderately active":
            exerciseDays = 4
        case "very active", "athlete":
            exerciseDays = 5
        default:
            exerciseDays = 3
        }

        let exerciseIds = exercises.map { $0.id.uuidString }
        var schedule: [[String]] = Array(repeating: [], count: 7)

        // Distribute exercises across the week with rest days
        let dayIndices: [Int]
        switch exerciseDays {
        case 3: dayIndices = [1, 3, 5] // Mon, Wed, Fri
        case 4: dayIndices = [1, 2, 4, 5] // Mon, Tue, Thu, Fri
        case 5: dayIndices = [1, 2, 3, 4, 5] // Mon-Fri
        default: dayIndices = [1, 3, 5]
        }

        for dayIndex in dayIndices {
            schedule[dayIndex] = exerciseIds
        }

        return schedule
    }

    private func getGeneralExercises() -> [RehabExercise] {
        [
            RehabExercise(id: UUID(), name: "Gentle Stretching", targetArea: "Full Body", description: "Perform gentle full-body stretches, holding each for 15-30 seconds. Focus on areas of tightness.", sets: 1, reps: "5-10 minutes", restSeconds: 0, difficulty: .beginner, demonstrationIcon: "figure.flexibility", tips: ["Never bounce while stretching.", "Breathe deeply.", "Stop if you feel sharp pain."], contraindications: ["Avoid stretching acutely injured areas."]),
            RehabExercise(id: UUID(), name: "Walking", targetArea: "General", description: "Walk at a comfortable pace. Start with 10 minutes and gradually increase duration.", sets: 1, reps: "10-20 minutes", restSeconds: 0, difficulty: .beginner, demonstrationIcon: "figure.walk", tips: ["Wear supportive shoes.", "Walk on flat surfaces.", "Maintain good posture."], contraindications: ["Avoid if weight-bearing causes significant pain."])
        ]
    }

    func savePlanToFirestore() {
        guard let userId = Auth.auth().currentUser?.uid, let plan = rehabPlan else { return }
        isSaving = true
        let db = Firestore.firestore()
        do {
            try db.collection("users").document(userId).collection("rehabPlans").document(plan.id.uuidString).setData(from: plan) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isSaving = false
                    if let error = error {
                        print("Error saving plan: \(error)")
                    } else {
                        self?.showSaveSuccess = true
                    }
                }
            }
        } catch {
            isSaving = false
            print("Error encoding plan: \(error)")
        }
    }
}
