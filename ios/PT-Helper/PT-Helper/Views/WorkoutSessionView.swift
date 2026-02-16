import SwiftUI

struct WorkoutSessionView: View {
    @StateObject private var viewModel = WorkoutViewModel()
    @State private var painLevel: Double = 0
    @State private var duration: TimeInterval = 0
    @State private var isCompleted: Bool = false

    var body: some View {
        VStack {
            Text("Workout Session")
            Slider(value: $painLevel, in: 0...10, step: 1)
            Text("Pain Level: \(Int(painLevel))")
            Button("Save Session") {
                let session = WorkoutSession(id: UUID(), date: Date(), duration: duration, painLevel: painLevel, isCompleted: isCompleted)
                viewModel.addSession(session: session)
            }
        }
        .padding()
    }
}
