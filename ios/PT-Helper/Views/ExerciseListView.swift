import Foundation
import SwiftUI

import SwiftUI

struct ExerciseListView: View {
    @StateObject private var viewModel = ExerciseViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.exercises.filter { searchText.isEmpty ? true : $0.name.contains(searchText) }) { exercise in
                    NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                        Text(exercise.name)
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Exercises")
            .onAppear { viewModel.loadExercises() }
        }
    }
}

struct ExerciseListView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseListView()
    }
}
