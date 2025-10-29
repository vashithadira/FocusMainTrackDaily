import SwiftUI
import CoreData

struct MainTabView: View {
    let context: NSManagedObjectContext
    @EnvironmentObject var languageManager: LanguageManager
    @State private var refreshID = UUID()
    
    var body: some View {
        TabView {
            TodayView(context: context)
                .tabItem {
                    Label("today".localized, systemImage: "sun.max.fill")
                }
            
            TasksView(context: context)
                .tabItem {
                    Label("tasks".localized, systemImage: "checkmark.circle.fill")
                }
            
            HabitsView(context: context)
                .tabItem {
                    Label("habits".localized, systemImage: "arrow.clockwise")
                }
            
            SummaryView(context: context)
                .tabItem {
                    Label("summary".localized, systemImage: "chart.bar.fill")
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
            refreshID = UUID()
        }
        .id(refreshID)
    }
}


