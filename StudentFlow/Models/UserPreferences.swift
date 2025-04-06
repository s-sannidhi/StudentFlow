import SwiftUI

enum Theme: String, CaseIterable {
    case system
    case light
    case dark
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AccentColor: String, CaseIterable {
    case blue
    case purple
    case green
    case orange
    case red
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        }
    }
}

enum DashboardLayout: String, CaseIterable {
    case grid
    case list
}

class UserPreferences: ObservableObject {
    private let defaults = UserDefaults.standard
    
    @Published var theme: Theme {
        didSet {
            defaults.set(theme.rawValue, forKey: "theme")
        }
    }
    
    @Published var accentColor: AccentColor {
        didSet {
            defaults.set(accentColor.rawValue, forKey: "accentColor")
        }
    }
    
    @Published var dashboardLayout: DashboardLayout {
        didSet {
            defaults.set(dashboardLayout.rawValue, forKey: "dashboardLayout")
        }
    }
    
    @Published var showCompletedTasks: Bool {
        didSet {
            defaults.set(showCompletedTasks, forKey: "showCompletedTasks")
        }
    }
    
    @Published var defaultPomodoroMinutes: Int {
        didSet {
            defaults.set(defaultPomodoroMinutes, forKey: "defaultPomodoroMinutes")
        }
    }
    
    @Published var shortBreakMinutes: Int {
        didSet {
            defaults.set(shortBreakMinutes, forKey: "shortBreakMinutes")
        }
    }
    
    @Published var longBreakMinutes: Int {
        didSet {
            defaults.set(longBreakMinutes, forKey: "longBreakMinutes")
        }
    }
    
    init() {
        // Load saved preferences or use defaults
        self.theme = Theme(rawValue: defaults.string(forKey: "theme") ?? "") ?? .system
        self.accentColor = AccentColor(rawValue: defaults.string(forKey: "accentColor") ?? "") ?? .blue
        self.dashboardLayout = DashboardLayout(rawValue: defaults.string(forKey: "dashboardLayout") ?? "") ?? .grid
        self.showCompletedTasks = defaults.bool(forKey: "showCompletedTasks")
        self.defaultPomodoroMinutes = defaults.integer(forKey: "defaultPomodoroMinutes") > 0 ? defaults.integer(forKey: "defaultPomodoroMinutes") : 25
        self.shortBreakMinutes = defaults.integer(forKey: "shortBreakMinutes") > 0 ? defaults.integer(forKey: "shortBreakMinutes") : 5
        self.longBreakMinutes = defaults.integer(forKey: "longBreakMinutes") > 0 ? defaults.integer(forKey: "longBreakMinutes") : 15
    }
} 