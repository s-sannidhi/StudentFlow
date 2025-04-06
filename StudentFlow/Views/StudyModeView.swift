import SwiftUI
import CoreData

struct StudyModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    let flashcardSet: FlashcardSet
    
    @State private var currentIndex = 0
    @State private var isShowingAnswer = false
    @State private var offset = CGSize.zero
    
    private var flashcards: [Flashcard] {
        flashcardSet.flashcardsArray
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if flashcards.isEmpty {
                    Text("No flashcards in this set")
                        .foregroundColor(.secondary)
                } else {
                    // Progress
                    Text("\(currentIndex + 1) of \(flashcards.count)")
                        .font(.headline)
                        .padding()
                    
                    // Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 4)
                        
                        VStack {
                            if isShowingAnswer {
                                Text(flashcards[currentIndex].back ?? "")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    .transition(.opacity)
                            } else {
                                Text(flashcards[currentIndex].front ?? "")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    .transition(.opacity)
                            }
                        }
                    }
                    .frame(width: 300, height: 200)
                    .offset(offset)
                    .rotationEffect(.degrees(Double(offset.width / 40)))
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                offset = gesture.translation
                            }
                            .onEnded { gesture in
                                if abs(gesture.translation.width) > 100 {
                                    // Swipe right (correct)
                                    if gesture.translation.width > 0 {
                                        markAsCorrect()
                                    }
                                    // Swipe left (incorrect)
                                    else {
                                        nextCard()
                                    }
                                }
                                offset = .zero
                            }
                    )
                    
                    // Controls
                    HStack(spacing: 40) {
                        Button(action: { isShowingAnswer.toggle() }) {
                            Text(isShowingAnswer ? "Hide Answer" : "Show Answer")
                                .frame(width: 120)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        if isShowingAnswer {
                            Button(action: markAsCorrect) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.green)
                            }
                            
                            Button(action: nextCard) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Study")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("End") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func markAsCorrect() {
        withAnimation {
            flashcards[currentIndex].isMastered = true
            try? viewContext.save()
            nextCard()
        }
    }
    
    private func nextCard() {
        withAnimation {
            isShowingAnswer = false
            if currentIndex < flashcards.count - 1 {
                currentIndex += 1
            } else {
                dismiss()
            }
        }
    }
} 