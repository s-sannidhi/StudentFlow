import SwiftUI
import CoreData

struct FlashcardsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedSet: FlashcardSet?
    @State private var showingAddSet = false
    @State private var showingStudyMode = false
    
    // Only used when viewing all sets
    @FetchRequest(
        entity: FlashcardSet.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FlashcardSet.createdAt, ascending: false)],
        animation: .default
    )
    private var flashcardSets: FetchedResults<FlashcardSet>
    
    // Initialize with an optional selected set
    init(selectedSet: FlashcardSet? = nil) {
        _selectedSet = State(initialValue: selectedSet)
    }
    
    var body: some View {
        Group {
            if let set = selectedSet {
                // Show single set view
                FlashcardSetDetailView(flashcardSet: set)
            } else {
                // Show all sets
                flashcardSetsListView
            }
        }
        .navigationTitle(selectedSet?.title ?? "Flashcards")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddSet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSet) {
            AddFlashcardSetView()
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private var flashcardSetsListView: some View {
        List {
            ForEach(flashcardSets) { set in
                NavigationLink(destination: FlashcardSetDetailView(flashcardSet: set)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(set.title ?? "Untitled Set")
                            .font(.headline)
                        
                        HStack {
                            Text(set.subject ?? "No Subject")
                                .font(.caption)
                                .padding(4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                            
                            Spacer()
                            
                            Text("\(set.masteredCount)/\(set.totalCount) mastered")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .onDelete(perform: deleteFlashcardSets)
        }
    }
    
    private func deleteFlashcardSets(offsets: IndexSet) {
        withAnimation {
            offsets.map { flashcardSets[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

struct FlashcardSetDetailView: View {
    let flashcardSet: FlashcardSet
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddCard = false
    @State private var showingStudyMode = false
    
    var body: some View {
        List {
            Section {
                if let description = flashcardSet.setDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Button(action: { showingStudyMode = true }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Study Session")
                    }
                }
            }
            
            Section("Flashcards") {
                ForEach(flashcardSet.flashcardsArray) { card in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(card.front ?? "")
                            .font(.headline)
                        
                        Text(card.back ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if card.isMastered {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Mastered")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddCard = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddCard) {
            AddFlashcardView(flashcardSet: flashcardSet)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingStudyMode) {
            StudyModeView(flashcardSet: flashcardSet)
                .environment(\.managedObjectContext, viewContext)
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    return NavigationView {
        FlashcardsView()
            .environment(\.managedObjectContext, context)
    }
} 