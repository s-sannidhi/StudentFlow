//
//  Persistence.swift
//  StudentFlow
//
//  Created by Srujan Sannidhi on 4/6/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample tasks
        let task1 = Task(context: viewContext)
        task1.title = "Math Homework"
        task1.setValue("Chapter 5 problems 1-20", forKey: "taskDescription")
        task1.priority = 2
        task1.createdAt = Date()
        task1.dueDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())
        
        let task2 = Task(context: viewContext)
        task2.title = "Physics Study"
        task2.setValue("Focus on quantum mechanics", forKey: "taskDescription")
        task2.priority = 1
        task2.createdAt = Date()
        task2.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        
        let task3 = Task(context: viewContext)
        task3.title = "History Reading"
        task3.setValue("Chapters 1-3", forKey: "taskDescription")
        task3.priority = 0
        task3.createdAt = Date()
        task3.dueDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "StudentFlow")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
