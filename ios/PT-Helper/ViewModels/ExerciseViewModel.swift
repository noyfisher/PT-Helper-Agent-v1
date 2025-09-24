import Foundation
import Combine

class ExerciseViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var selectedExercise: Exercise?
    private var exerciseService = ExerciseService()
    
    func loadExercises() {
        exercises = exerciseService.fetchExercises()
    }
}
