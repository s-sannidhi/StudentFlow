import SwiftUI

enum LinkCategory: Int16, CaseIterable {
    case school = 0
    case textbooks = 1
    case research = 2
    case other = 3
    
    var name: String {
        switch self {
        case .school: return "School"
        case .textbooks: return "Textbooks"
        case .research: return "Research"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .school: return "building.columns"
        case .textbooks: return "book"
        case .research: return "magnifyingglass"
        case .other: return "folder"
        }
    }
}

struct LinksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedCategory: LinkCategory?
    @State private var showingAddLink = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding()
                
                // Category Grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryButton(title: "All", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        
                        ForEach(LinkCategory.allCases, id: \.rawValue) { category in
                            CategoryButton(
                                title: category.name,
                                icon: category.icon,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Links List
                LinkListView(category: selectedCategory, searchText: searchText)
            }
            .navigationTitle("Links")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddLink = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddLink) {
                AddLinkView()
            }
        }
    }
}

struct CategoryButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
            .foregroundColor(isSelected ? .accentColor : .primary)
            .cornerRadius(12)
        }
    }
}

struct LinkListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let category: LinkCategory?
    let searchText: String
    
    var fetchRequest: FetchRequest<Link>
    private var links: FetchedResults<Link> { fetchRequest.wrappedValue }
    
    init(category: LinkCategory?, searchText: String) {
        self.category = category
        self.searchText = searchText
        
        var predicates: [NSPredicate] = []
        
        if let category = category {
            predicates.append(NSPredicate(format: "category == %d", category.rawValue))
        }
        
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "title CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", searchText, searchText))
        }
        
        let compoundPredicate = predicates.isEmpty
            ? NSPredicate(value: true)
            : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        fetchRequest = FetchRequest<Link>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Link.isFavorite, ascending: false),
                NSSortDescriptor(keyPath: \Link.title, ascending: true)
            ],
            predicate: compoundPredicate,
            animation: .default)
    }
    
    var body: some View {
        List {
            ForEach(links) { link in
                LinkRow(link: link)
            }
            .onDelete(perform: deleteLinks)
        }
        .listStyle(PlainListStyle())
    }
    
    private func deleteLinks(offsets: IndexSet) {
        withAnimation {
            offsets.map { links[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

struct LinkRow: View {
    @ObservedObject var link: Link
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationLink(destination: LinkDetailView(link: link)) {
            HStack {
                Image(systemName: LinkCategory(rawValue: link.category)?.icon ?? "link")
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading) {
                    Text(link.title ?? "Untitled")
                    
                    if let url = link.url {
                        Text(url)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if link.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
        }
    }
}

struct AddLinkView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var url = ""
    @State private var category: LinkCategory = .school
    @State private var notes = ""
    @State private var isFavorite = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Link Details")) {
                    TextField("Title", text: $title)
                    TextField("URL", text: $url)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        ForEach(LinkCategory.allCases, id: \.rawValue) { category in
                            Label(category.name, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }
                
                Section {
                    Toggle("Add to Favorites", isOn: $isFavorite)
                }
            }
            .navigationTitle("New Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addLink()
                    }
                    .disabled(title.isEmpty || url.isEmpty)
                }
            }
        }
    }
    
    private func addLink() {
        withAnimation {
            let link = Link(context: viewContext)
            link.title = title
            link.url = url
            link.notes = notes
            link.category = category.rawValue
            link.isFavorite = isFavorite
            link.createdAt = Date()
            
            try? viewContext.save()
            dismiss()
        }
    }
}

struct LinkDetailView: View {
    @ObservedObject var link: Link
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("Link Details")) {
                if isEditing {
                    TextField("Title", text: Binding(
                        get: { link.title ?? "" },
                        set: { link.title = $0 }
                    ))
                    TextField("URL", text: Binding(
                        get: { link.url ?? "" },
                        set: { link.url = $0 }
                    ))
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    TextField("Notes", text: Binding(
                        get: { link.notes ?? "" },
                        set: { link.notes = $0 }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(link.title ?? "Untitled")
                            .font(.headline)
                        
                        if let url = link.url {
                            Button(action: { openURL(URL(string: url)!) }) {
                                Text(url)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if let notes = link.notes, !notes.isEmpty {
                            Text(notes)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            if isEditing {
                Section(header: Text("Category")) {
                    Picker("Category", selection: Binding(
                        get: { LinkCategory(rawValue: link.category) ?? .other },
                        set: { link.category = $0.rawValue }
                    )) {
                        ForEach(LinkCategory.allCases, id: \.rawValue) { category in
                            Label(category.name, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }
                
                Section {
                    Toggle("Add to Favorites", isOn: Binding(
                        get: { link.isFavorite },
                        set: { link.isFavorite = $0 }
                    ))
                }
                
                Section {
                    Button("Delete Link", role: .destructive) {
                        showingDeleteAlert = true
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Link" : "Link Details")
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
        .alert("Delete Link", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteLink()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this link? This action cannot be undone.")
        }
    }
    
    private func deleteLink() {
        withAnimation {
            viewContext.delete(link)
            try? viewContext.save()
            dismiss()
        }
    }
}

#Preview {
    LinksView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 