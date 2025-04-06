import SwiftUI
import Combine

enum TimerMode: String {
    case focus = "Focus"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
    
    var defaultDuration: TimeInterval {
        switch self {
        case .focus: return 25 * 60 // 25 minutes
        case .shortBreak: return 5 * 60 // 5 minutes
        case .longBreak: return 15 * 60 // 15 minutes
        }
    }
    
    var color: Color {
        switch self {
        case .focus: return .red
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }
}

class StudyTimerManager: ObservableObject {
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var currentMode: TimerMode = .focus
    @Published var elapsedTime: TimeInterval = 0
    @Published var remainingTime: TimeInterval
    @Published var completedPomodoros = 0
    @Published var pomodoroGoal = 4
    @Published var totalFocusTime: TimeInterval = 0
    
    private var timer: AnyCancellable?
    private var startTime: Date?
    private var backgroundDate: Date?
    private let notificationManager = NotificationManager.shared
    
    init() {
        self.remainingTime = TimerMode.focus.defaultDuration
    }
    
    var progressPercentage: Double {
        let total = currentMode.defaultDuration
        return (total - remainingTime) / total
    }
    
    var sessionProgress: Double {
        Double(completedPomodoros) / Double(pomodoroGoal)
    }
    
    var formattedTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedTotalFocusTime: String {
        let hours = Int(totalFocusTime) / 3600
        let minutes = Int(totalFocusTime) / 60 % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
    
    func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    func startTimer() {
        if !isRunning {
            isRunning = true
            isPaused = false
            startTime = Date()
            
            timer = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    self?.updateTimer()
                }
        }
    }
    
    func pauseTimer() {
        isRunning = false
        isPaused = true
        timer?.cancel()
    }
    
    func reset() {
        isRunning = false
        isPaused = false
        timer?.cancel()
        remainingTime = currentMode.defaultDuration
        elapsedTime = 0
        startTime = nil
    }
    
    func skipToNext() {
        completeTimer()
    }
    
    private func updateTimer() {
        guard let start = startTime else { return }
        
        let now = Date()
        elapsedTime = now.timeIntervalSince(start)
        remainingTime = max(currentMode.defaultDuration - elapsedTime, 0)
        
        if remainingTime == 0 {
            completeTimer()
        }
    }
    
    private func completeTimer() {
        timer?.cancel()
        isRunning = false
        
        if currentMode == .focus {
            completedPomodoros += 1
            if completedPomodoros % 4 == 0 {
                currentMode = .longBreak
            } else {
                currentMode = .shortBreak
            }
        } else {
            currentMode = .focus
        }
        
        remainingTime = currentMode.defaultDuration
        startTime = nil
        notifyTimerCompletion()
    }
    
    private func notifyTimerCompletion() {
        let title = "Timer Complete"
        let body = currentMode == .focus
            ? "Time for a break!"
            : "Ready to focus?"
        
        notificationManager.scheduleTimerCompletionNotification(title: title, body: body)
    }
    
    func resetStatistics() {
        completedPomodoros = 0
        totalFocusTime = 0
    }
    
    // App State Handling
    func appWentBackground() {
        if isRunning {
            backgroundDate = Date()
        }
    }
    
    func appBecameActive() {
        if let backgroundDate = backgroundDate, isRunning {
            let timeInBackground = Date().timeIntervalSince(backgroundDate)
            remainingTime = max(0, remainingTime - timeInBackground)
            
            if remainingTime == 0 {
                completeTimer()
            }
        }
        
        self.backgroundDate = nil
    }
} 