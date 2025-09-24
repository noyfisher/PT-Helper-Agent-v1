import Foundation

class WorkoutViewModel: ObservableObject {
    @Published var sessions: [WorkoutSession] = []

    func addSession(session: WorkoutSession) {
        sessions.append(session)
    }
}
