import SwiftUI
import CoreData

struct AddFlashcardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let flashcardSet: FlashcardSet
    
    @State private var front = ""
    @State private var back = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Front")) {
                    TextField("Question or term", text: $front, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Back")) {
                    TextField("Answer or definition", text: $back, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Flashcard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addCard()
                    }
                    .disabled(front.isEmpty || back.isEmpty)
                }
            }
        }
    }
    
    private func addCard() {
        withAnimation {
            let card = Flashcard(context: viewContext)
            card.front = front
            card.back = back
            card.createdAt = Date()
            card.isMastered = false
            card.set = flashcardSet
            
            try? viewContext.save()
            dismiss()
        }
    }
} 