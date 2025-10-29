import Foundation

struct AchievementModel: Identifiable {
    let id: UUID
    var title: String
    var achievementDescription: String
    var icon: String
    var isUnlocked: Bool
    var unlockedAt: Date?
    
    init(id: UUID = UUID(), title: String, achievementDescription: String, icon: String, isUnlocked: Bool = false, unlockedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.achievementDescription = achievementDescription
        self.icon = icon
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
    }
}

