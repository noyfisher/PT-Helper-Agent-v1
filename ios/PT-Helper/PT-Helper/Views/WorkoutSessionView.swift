import Foundation
import SwiftUI

import SwiftUI

struct WorkoutSessionView: View {
    @StateObject private var viewModel = WorkoutViewModel()
    @State private var painLevel: Int = 0
    @State private var duration: TimeInterval = 0
    @State private var isCompleted: Bool = false

    var body: some View {
        VStack {
            Text("Workout Session")
            Slider(value: $painLevel, in: 0...10, step: 1)
            Text("Pain Level: \(painLevel)")
            // Additional UI for duration and completion status
            Button("Save Session") {
                let session = WorkoutSession(id: UUID(), date: Date(), duration: duration, painLevel: painLevel, isCompleted: isCompleted)
                viewModel.addSession(session: session)
            }
        }
        .padding()
    }
}
