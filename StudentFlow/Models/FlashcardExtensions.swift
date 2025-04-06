import Foundation
import CoreData

extension FlashcardSet {
    var flashcardsArray: [Flashcard] {
        let set = flashcards as? Set<Flashcard> ?? []
        return Array(set).sorted { $0.createdAt ?? Date() < $1.createdAt ?? Date() }
    }
    
    var masteredCount: Int {
        flashcardsArray.filter { $0.isMastered }.count
    }
    
    var totalCount: Int {
        flashcardsArray.count
    }
    
    var masteryPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(masteredCount) / Double(totalCount)
    }
} 