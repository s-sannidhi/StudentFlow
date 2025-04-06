import SwiftUI
import CoreData
import Combine

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var userPreferences: UserPreferences
    @StateObject private var studyTimerManager = StudyTimerManager()
    
    @FetchRequest(
        entity: Task.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.dueDate, ascending: true)],
        predicate: NSPredicate(format: "isComplete == NO"),
        animation: .default
    )
    private var upcomingTasks: FetchedResults<Task>
    
    @FetchRequest(
        entity: Link.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Link.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isFavorite == YES"),
        animation: .default
    )
    private var favoriteLinks: FetchedResults<Link>
    
    @FetchRequest(
        entity: FlashcardSet.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FlashcardSet.createdAt, ascending: false)],
        animation: .default
    )
    private var recentFlashcardSets: FetchedResults<FlashcardSet>
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Study Timer Card
                    StudyTimerCard(studyTimerManager: studyTimerManager)
                    
                    // Tasks Section
                    DashboardSection(title: "Upcoming Tasks", showAllDestination: AnyView(TasksView().environment(\.managedObjectContext, viewContext))) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 15) {
                                ForEach(upcomingTasks.prefix(5)) { task in
                                    TaskCard(task: task)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Favorite Links Section
                    DashboardSection(title: "Favorite Links", showAllDestination: AnyView(LinksView().environment(\.managedObjectContext, viewContext))) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 15) {
                                ForEach(favoriteLinks.prefix(5)) { link in
                                    LinkCard(link: link)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Recent Flashcard Sets Section
                    DashboardSection(title: "Recent Flashcard Sets", showAllDestination: AnyView(FlashcardsView().environment(\.managedObjectContext, viewContext))) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 15) {
                                ForEach(recentFlashcardSets.prefix(5)) { set in
                                    NavigationLink(destination: FlashcardsView(selectedSet: set).environment(\.managedObjectContext, viewContext)) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(set.title ?? "Untitled Set")
                                                .font(.headline)
                                                .lineLimit(2)
                                            
                                            if let description = set.setDescription {
                                                Text(description)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(2)
                                            }
                                            
                                            HStack {
                                                Text(set.subject ?? "No Subject")
                                                    .font(.caption2)
                                                    .padding(4)
                                                    .background(Color.blue.opacity(0.2))
                                                    .cornerRadius(4)
                                                
                                                Spacer()
                                                
                                                Text("\(set.masteredCount)/\(set.totalCount)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding()
                                        .frame(width: 200)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(10)
                                        .shadow(radius: 3)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
        }
        .environmentObject(studyTimerManager)
    }
}

// MARK: - Supporting Views

struct DashboardSection<Content: View>: View {
    let title: String
    let showAllDestination: AnyView
    let content: Content
    
    init(title: String, showAllDestination: AnyView, @ViewBuilder content: () -> Content) {
        self.title = title
        self.showAllDestination = showAllDestination
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                NavigationLink {
                    showAllDestination
                } label: {
                    Text("Show All")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal)
            
            content
        }
    }
}

struct StudyTimerCard: View {
    @ObservedObject var studyTimerManager: StudyTimerManager
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text(studyTimerManager.currentMode.rawValue)
                        .font(.headline)
                    Text("\(studyTimerManager.formattedTime)")
                        .font(.system(size: 32, weight: .bold))
                }
                Spacer()
                Circle()
                    .trim(from: 0, to: studyTimerManager.progressPercentage)
                    .stroke(studyTimerManager.currentMode.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 60, height: 60)
            }
            
            HStack(spacing: 20) {
                Button(action: studyTimerManager.toggleTimer) {
                    Image(systemName: studyTimerManager.isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                
                Button(action: studyTimerManager.reset) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

struct TaskCard: View {
    let task: Task
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.title ?? "Untitled Task")
                .font(.headline)
                .lineLimit(1)
            
            if let dueDate = task.dueDate {
                Text("Due: \(dueDate, formatter: itemFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: priorityIcon)
                    .foregroundColor(priorityColor)
                Spacer()
                if task.reminderEnabled {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .frame(width: 200)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 3)
    }
    
    private var priorityIcon: String {
        switch task.priority {
        case 2: return "exclamationmark.3"
        case 1: return "exclamationmark.2"
        default: return "exclamationmark"
        }
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case 2: return .red
        case 1: return .orange
        default: return .blue
        }
    }
}

struct LinkCard: View {
    let link: Link
    
    var body: some View {
        if let urlString = link.url, let url = URL(string: urlString) {
            SwiftUI.Link(destination: url) {
                linkContent
            }
        } else {
            linkContent
        }
    }
    
    private var linkContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(link.title ?? "Untitled Link")
                .font(.headline)
                .lineLimit(2)
            
            if let notes = link.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Image(systemName: "link")
                Spacer()
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
        }
        .padding()
        .frame(width: 200)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    let context = PersistenceController.preview.container.viewContext
    return DashboardView()
        .environment(\.managedObjectContext, context)
        .environmentObject(UserPreferences())
} 