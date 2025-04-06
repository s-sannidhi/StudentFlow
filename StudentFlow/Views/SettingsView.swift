import SwiftUI
import SafariServices
import CoreData

struct SettingsView: View {
    @EnvironmentObject private var userPreferences: UserPreferences
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Theme", selection: $userPreferences.theme) {
                        Text("System").tag(Theme.system)
                        Text("Light").tag(Theme.light)
                        Text("Dark").tag(Theme.dark)
                    }
                    
                    Picker("Accent Color", selection: $userPreferences.accentColor) {
                        ForEach(AccentColor.allCases, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 20, height: 20)
                                Text(color.rawValue.capitalized)
                            }
                            .tag(color)
                        }
                    }
                } header: {
                    Text("Appearance")
                }
                
                Section {
                    Picker("Layout", selection: $userPreferences.dashboardLayout) {
                        Text("Grid").tag(DashboardLayout.grid)
                        Text("List").tag(DashboardLayout.list)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Dashboard")
                }
                
                Section {
                    Toggle("Show Completed Tasks", isOn: $userPreferences.showCompletedTasks)
                } header: {
                    Text("Tasks")
                }
                
                Section {
                    NavigationLink(destination: TimerSettingsView()) {
                        Text("Timer Settings")
                    }
                } header: {
                    Text("Study Timer")
                }
                
                Section {
                    Button(role: .destructive, action: clearAllData) {
                        Text("Clear All Data")
                    }
                } header: {
                    Text("Data Management")
                }
                
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink("Privacy Policy") {
                        SafariView(url: URL(string: "https://example.com/privacy")!)
                    }
                    
                    NavigationLink("Terms of Service") {
                        SafariView(url: URL(string: "https://example.com/terms")!)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func clearAllData() {
        // Clear Tasks
        let taskFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Task")
        if let tasks = try? viewContext.fetch(taskFetch) as? [Task] {
            for task in tasks {
                viewContext.delete(task)
            }
        }
        
        // Clear Links
        let linkFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Link")
        if let links = try? viewContext.fetch(linkFetch) as? [Link] {
            for link in links {
                viewContext.delete(link)
            }
        }
        
        // Clear FlashcardSets (this will also delete associated Flashcards due to cascade deletion)
        let setFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "FlashcardSet")
        if let sets = try? viewContext.fetch(setFetch) as? [FlashcardSet] {
            for set in sets {
                viewContext.delete(set)
            }
        }
        
        // Clear StudySessions
        let sessionFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "StudySession")
        if let sessions = try? viewContext.fetch(sessionFetch) as? [StudySession] {
            for session in sessions {
                viewContext.delete(session)
            }
        }
        
        // Save context
        do {
            try viewContext.save()
        } catch {
            print("Error saving context after deletion: \(error)")
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    return SettingsView()
        .environment(\.managedObjectContext, context)
        .environmentObject(UserPreferences())
} 