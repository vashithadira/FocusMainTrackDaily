import Foundation

struct HabitModel: Identifiable {
    let id: UUID
    var title: String
    var icon: String
    var completedDates: [Date]
    var createdAt: Date
    
    init(id: UUID = UUID(), title: String, icon: String, completedDates: [Date] = [], createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.icon = icon
        self.completedDates = completedDates
        self.createdAt = createdAt
    }
}

