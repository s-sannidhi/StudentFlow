import SwiftUI

enum TaskFilter {
    case all
    case today
    case upcoming
    case completed
}

struct TasksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var userPreferences: UserPreferences
    @State private var selectedFilter: TaskFilter = .all
    @State private var showingAddTask = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    Text("All").tag(TaskFilter.all)
                    Text("Today").tag(TaskFilter.today)
                    Text("Upcoming").tag(TaskFilter.upcoming)
                    Text("Completed").tag(TaskFilter.completed)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Task List
                TaskListView(filter: selectedFilter, searchText: searchText)
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search tasks...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let filter: TaskFilter
    let searchText: String
    
    var fetchRequest: FetchRequest<Task>
    private var tasks: FetchedResults<Task> { fetchRequest.wrappedValue }
    
    init(filter: TaskFilter, searchText: String) {
        self.filter = filter
        self.searchText = searchText
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        var predicates: [NSPredicate] = []
        
        // Filter predicate
        switch filter {
        case .all:
            predicates.append(NSPredicate(value: true))
        case .today:
            predicates.append(NSPredicate(format: "dueDate >= %@ AND dueDate < %@", today as NSDate, tomorrow as NSDate))
        case .upcoming:
            predicates.append(NSPredicate(format: "dueDate >= %@", tomorrow as NSDate))
        case .completed:
            predicates.append(NSPredicate(format: "isComplete == YES"))
        }
        
        // Search predicate
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "title CONTAINS[cd] %@ OR taskDescription CONTAINS[cd] %@", searchText, searchText))
        }
        
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        fetchRequest = FetchRequest<Task>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Task.dueDate, ascending: true),
                NSSortDescriptor(keyPath: \Task.priority, ascending: false)
            ],
            predicate: compoundPredicate,
            animation: .default)
    }
    
    var body: some View {
        List {
            ForEach(tasks) { task in
                TaskRow(task: task)
            }
            .onDelete(perform: deleteTasks)
        }
        .listStyle(PlainListStyle())
    }
    
    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            offsets.map { tasks[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

struct TaskRow: View {
    @ObservedObject var task: Task
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationLink(destination: TaskDetailView(task: task)) {
            HStack {
                // Completion Toggle
                Button(action: toggleComplete) {
                    Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isComplete ? .green : .secondary)
                }
                
                // Task Info
                VStack(alignment: .leading) {
                    Text(task.title ?? "Untitled")
                        .strikethrough(task.isComplete)
                    
                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Priority Indicator
                if task.priority > 0 {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(priorityColor)
                }
            }
        }
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case 2: return .red
        case 1: return .orange
        default: return .secondary
        }
    }
    
    private func toggleComplete() {
        withAnimation {
            task.isComplete.toggle()
            try? viewContext.save()
        }
    }
}

struct AddTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var taskDescription = ""
    @State private var dueDate = Date()
    @State private var priority = 0
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $taskDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Due Date")) {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        Text("Low").tag(0)
                        Text("Medium").tag(1)
                        Text("High").tag(2)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Reminder")) {
                    Toggle("Enable Reminder", isOn: $reminderEnabled)
                    
                    if reminderEnabled {
                        DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func addTask() {
        withAnimation {
            let task = Task(context: viewContext)
            task.title = title
            task.taskDescription = taskDescription
            task.dueDate = dueDate
            task.priority = Int16(priority)
            task.createdAt = Date()
            task.isComplete = false
            task.reminderEnabled = reminderEnabled
            task.reminderTime = reminderEnabled ? reminderTime : nil
            
            try? viewContext.save()
            dismiss()
        }
    }
}

struct TaskDetailView: View {
    @ObservedObject var task: Task
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    
    var body: some View {
        Form {
            Section(header: Text("Task Details")) {
                if isEditing {
                    TextField("Title", text: Binding(
                        get: { task.title ?? "" },
                        set: { task.title = $0 }
                    ))
                    TextField("Description", text: Binding(
                        get: { task.taskDescription ?? "" },
                        set: { task.taskDescription = $0 }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                } else {
                    Text(task.title ?? "Untitled")
                        .font(.headline)
                    Text(task.taskDescription ?? "No description")
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Status")) {
                Toggle("Completed", isOn: Binding(
                    get: { task.isComplete },
                    set: { task.isComplete = $0 }
                ))
            }
            
            Section(header: Text("Due Date")) {
                if isEditing {
                    DatePicker("Due Date", selection: Binding(
                        get: { task.dueDate ?? Date() },
                        set: { task.dueDate = $0 }
                    ), displayedComponents: [.date, .hourAndMinute])
                } else {
                    Text(task.dueDate ?? Date(), style: .date)
                }
            }
            
            Section(header: Text("Priority")) {
                if isEditing {
                    Picker("Priority", selection: Binding(
                        get: { Int(task.priority) },
                        set: { task.priority = Int16($0) }
                    )) {
                        Text("Low").tag(0)
                        Text("Medium").tag(1)
                        Text("High").tag(2)
                    }
                    .pickerStyle(.segmented)
                } else {
                    Text(priorityText)
                }
            }
            
            Section(header: Text("Reminder")) {
                if isEditing {
                    Toggle("Enable Reminder", isOn: Binding(
                        get: { task.reminderEnabled },
                        set: { task.reminderEnabled = $0 }
                    ))
                    
                    if task.reminderEnabled {
                        DatePicker("Reminder Time", selection: Binding(
                            get: { task.reminderTime ?? Date() },
                            set: { task.reminderTime = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    }
                } else if task.reminderEnabled, let reminderTime = task.reminderTime {
                    Text(reminderTime, style: .date)
                } else {
                    Text("No reminder set")
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Task" : "Task Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        try? viewContext.save()
                    }
                    isEditing.toggle()
                }
            }
        }
    }
    
    private var priorityText: String {
        switch task.priority {
        case 2: return "High"
        case 1: return "Medium"
        default: return "Low"
        }
    }
}

#Preview {
    TasksView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(UserPreferences())
} 