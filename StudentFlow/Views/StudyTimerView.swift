import SwiftUI

struct StudyTimerView: View {
    @EnvironmentObject private var studyTimerManager: StudyTimerManager
    @EnvironmentObject private var userPreferences: UserPreferences
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Timer Display
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2),
                                lineWidth: 20)
                        .frame(width: 280, height: 280)
                    
                    Circle()
                        .trim(from: 0, to: studyTimerManager.progressPercentage)
                        .stroke(timerColor, style: 
                            StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 8) {
                        Text(studyTimerManager.formattedTime)
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                        
                        Text(studyTimerManager.currentMode.rawValue)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                // Controls
                HStack(spacing: 60) {
                    Button(action: studyTimerManager.reset) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title)
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: studyTimerManager.toggleTimer) {
                        Image(systemName: studyTimerManager.isRunning ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(timerColor)
                    }
                    
                    Button(action: studyTimerManager.skipToNext) {
                        Image(systemName: "forward.fill")
                            .font(.title)
                            .foregroundColor(.primary)
                    }
                }
                
                // Progress
                VStack(spacing: 8) {
                    Text("Completed Pomodoros: \(studyTimerManager.completedPomodoros)/\(studyTimerManager.pomodoroGoal)")
                        .font(.headline)
                    
                    Text("Total Focus Time: \(studyTimerManager.formattedTotalFocusTime)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Study Timer")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: TimerSettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                studyTimerManager.appBecameActive()
            } else if newPhase == .background {
                studyTimerManager.appWentBackground()
            }
        }
    }
    
    private var timerColor: Color {
        switch studyTimerManager.currentMode {
        case .focus:
            return .red
        case .shortBreak:
            return .green
        case .longBreak:
            return .blue
        }
    }
}

struct TimerSettingsView: View {
    @EnvironmentObject private var userPreferences: UserPreferences
    @EnvironmentObject private var studyTimerManager: StudyTimerManager
    
    var body: some View {
        Form {
            Section(header: Text("Timer Duration (Minutes)")) {
                Stepper("Focus Time: \(userPreferences.defaultPomodoroMinutes)", value: $userPreferences.defaultPomodoroMinutes, in: 1...60)
                Stepper("Short Break: \(userPreferences.shortBreakMinutes)", value: $userPreferences.shortBreakMinutes, in: 1...30)
                Stepper("Long Break: \(userPreferences.longBreakMinutes)", value: $userPreferences.longBreakMinutes, in: 1...60)
            }
            
            Section(header: Text("Goals")) {
                Stepper("Daily Pomodoros: \(studyTimerManager.pomodoroGoal)", value: $studyTimerManager.pomodoroGoal, in: 1...12)
            }
            
            Section {
                Button("Reset Statistics") {
                    studyTimerManager.resetStatistics()
                }
            }
        }
        .navigationTitle("Timer Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension TimeInterval {
    var formattedTime: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
}

#Preview {
    StudyTimerView()
        .environmentObject(StudyTimerManager())
        .environmentObject(UserPreferences())
} 