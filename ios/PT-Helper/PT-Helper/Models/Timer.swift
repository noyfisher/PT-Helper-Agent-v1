import Foundation

class Timer {
    var duration: Int
    var isRunning: Bool
    var timeRemaining: Int

    init(duration: Int) {
        self.duration = duration
        self.isRunning = false
        self.timeRemaining = duration
    }
}