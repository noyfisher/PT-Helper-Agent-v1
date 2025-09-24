import Foundation
import Combine

class TimerViewModel: ObservableObject {
    @Published var timer: Timer
    private var timerSubscription: AnyCancellable?

    var timeString: String {
        let minutes = timer.timeRemaining / 60
        let seconds = timer.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    init() {
        self.timer = Timer(duration: 300) // 5 minutes
    }

    func start() {
        guard !timer.isRunning else { return }
        timer.isRunning = true
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
    }

    func stop() {
        timer.isRunning = false
        timerSubscription?.cancel()
    }

    func reset() {
        stop()
        timer.timeRemaining = timer.duration
    }

    private func updateTimer() {
        guard timer.isRunning else { return }
        if timer.timeRemaining > 0 {
            timer.timeRemaining -= 1
        } else {
            stop()
        }
    }
}