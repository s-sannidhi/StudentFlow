//
//  ContentView.swift
//  StudentFlow
//
//  Created by Srujan Sannidhi on 4/6/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var userPreferences = UserPreferences()
    @StateObject private var studyTimerManager = StudyTimerManager()
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }
            
            TasksView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
            
            LinksView()
                .tabItem {
                    Label("Links", systemImage: "link")
                }
            
            StudyTimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }
            
            FlashcardsView()
                .tabItem {
                    Label("Flashcards", systemImage: "rectangle.on.rectangle")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .accentColor(userPreferences.accentColor.color)
        .preferredColorScheme(userPreferences.theme.colorScheme)
        .environmentObject(userPreferences)
        .environmentObject(studyTimerManager)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
