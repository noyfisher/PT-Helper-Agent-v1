import Foundation
import SwiftUI

import SwiftUI

struct ExerciseDetailView: View {
    var exercise: Exercise
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(exercise.name)
                    .font(.largeTitle)
                    .padding()
                Text(exercise.description)
                    .padding()
                ForEach(exercise.instructions, id: \.self) { instruction in
                    Text(instruction)
                        .padding(.horizontal)
                }
            }
        }
        .navigationTitle(exercise.name)
    }
}

struct ExerciseDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let exercise = Exercise(id: UUID(), name: "Sample Exercise", description: "This is a sample exercise.", instructions: ["Step 1", "Step 2"], duration: nil, repetitions: nil, sets: nil, difficulty: .medium, category: .strength, imageURL: nil, videoURL: nil)
        ExerciseDetailView(exercise: exercise)
    }
}
