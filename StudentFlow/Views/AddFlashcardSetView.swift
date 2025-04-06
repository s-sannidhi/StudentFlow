import SwiftUI
import CoreData

struct AddFlashcardSetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var subject = ""
    @State private var description = ""
    @State private var generationText = ""
    @State private var isGenerating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Set Details")) {
                    TextField("Title", text: $title)
                    TextField("Subject", text: $subject)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("AI Generation")) {
                    TextField("Enter text to generate flashcards from...", text: $generationText, axis: .vertical)
                        .lineLimit(5...10)
                    
                    Button(action: generateFlashcards) {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Generate Flashcards")
                        }
                    }
                    .disabled(generationText.isEmpty || isGenerating)
                }
            }
            .navigationTitle("New Flashcard Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createSet()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createSet() {
        withAnimation {
            let set = FlashcardSet(context: viewContext)
            set.title = title
            set.subject = subject
            set.setDescription = description
            set.createdAt = Date()
            
            try? viewContext.save()
            dismiss()
        }
    }
    
    private func generateFlashcards() {
        isGenerating = true
        
        // Simulated AI API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isGenerating = false
            showingError = true
            errorMessage = "AI generation is not yet implemented"
        }
    }
} 