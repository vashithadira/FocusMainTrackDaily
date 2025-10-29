import SwiftUI
import CoreData

struct MainTabView: View {
    let context: NSManagedObjectContext
    
    var body: some View {
        TabView {
            TodayView(context: context)
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }
            
            TasksView(context: context)
                .tabItem {
                    Label("Tasks", systemImage: "checkmark.circle.fill")
                }
            
            HabitsView(context: context)
                .tabItem {
                    Label("Habits", systemImage: "arrow.clockwise")
                }
            
            SummaryView(context: context)
                .tabItem {
                    Label("Summary", systemImage: "chart.bar.fill")
                }
        }
    }
}

