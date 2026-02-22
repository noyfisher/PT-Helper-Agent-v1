import Foundation

class ExerciseTimer {
    var duration: Int
    var isRunning: Bool
    var timeRemaining: Int

    init(duration: Int) {
        self.duration = duration
        self.isRunning = false
        self.timeRemaining = duration
    }
}
