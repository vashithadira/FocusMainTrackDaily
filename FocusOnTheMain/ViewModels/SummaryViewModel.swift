import Foundation
import CoreData
import Combine

class SummaryViewModel: ObservableObject {
    @Published var weeklyTasksCompleted: [Int] = []
    @Published var monthlyTasksCompleted: [Int] = []
    @Published var habitsProgress: [(habit: HabitModel, progress: Double)] = []
    @Published var achievements: [AchievementModel] = []
    @Published var activityCalendar: [Date: Int] = [:]
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchStatistics()
        fetchAchievements()
        checkAndUnlockAchievements()
    }
    
    func fetchStatistics() {
        fetchWeeklyTasks()
        fetchMonthlyTasks()
        fetchHabitsProgress()
        fetchActivityCalendar()
        fetchAchievements()
        checkAndUnlockAchievements()
    }
    
    private func fetchWeeklyTasks() {
        let calendar = Calendar.current
        let today = Date()
        var completedCounts: [Int] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                
                let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
                request.predicate = NSPredicate(format: "isCompleted == YES AND completedAt >= %@ AND completedAt < %@", startOfDay as NSDate, endOfDay as NSDate)
                
                do {
                    let count = try context.count(for: request)
                    completedCounts.insert(count, at: 0)
                } catch {
                    completedCounts.insert(0, at: 0)
                }
            }
        }
        
        weeklyTasksCompleted = completedCounts
    }
    
    private func fetchMonthlyTasks() {
        let calendar = Calendar.current
        let today = Date()
        var completedCounts: [Int] = []
        
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                
                let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
                request.predicate = NSPredicate(format: "isCompleted == YES AND completedAt >= %@ AND completedAt < %@", startOfDay as NSDate, endOfDay as NSDate)
                
                do {
                    let count = try context.count(for: request)
                    completedCounts.insert(count, at: 0)
                } catch {
                    completedCounts.insert(0, at: 0)
                }
            }
        }
        
        monthlyTasksCompleted = completedCounts
    }
    
    private func fetchHabitsProgress() {
        let request: NSFetchRequest<HabitItem> = HabitItem.fetchRequest()
        
        do {
            let items = try context.fetch(request)
            let calendar = Calendar.current
            let today = Date()
            
            habitsProgress = items.map { item in
                let habit = convertHabitToModel(item)
                let last7Days = (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
                let completedDays = last7Days.filter { day in
                    habit.completedDates.contains { calendar.isDate($0, inSameDayAs: day) }
                }.count
                let progress = Double(completedDays) / 7.0
                return (habit: habit, progress: progress)
            }
        } catch {
            print("Failed to fetch habits progress: \(error)")
        }
    }
    
    private func fetchActivityCalendar() {
        let calendar = Calendar.current
        let today = Date()
        var activityData: [Date: Int] = [:]
        
        for i in 0..<90 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                
                let taskRequest: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
                taskRequest.predicate = NSPredicate(format: "isCompleted == YES AND completedAt >= %@ AND completedAt < %@", startOfDay as NSDate, endOfDay as NSDate)
                
                let habitRequest: NSFetchRequest<HabitItem> = HabitItem.fetchRequest()
                
                do {
                    let taskCount = try context.count(for: taskRequest)
                    let habits = try context.fetch(habitRequest)
                    var habitCount = 0
                    
                    for habit in habits {
                        let dates = (habit.completedDates as? [Date]) ?? []
                        if dates.contains(where: { calendar.isDate($0, inSameDayAs: startOfDay) }) {
                            habitCount += 1
                        }
                    }
                    
                    activityData[startOfDay] = taskCount + habitCount
                } catch {
                    activityData[startOfDay] = 0
                }
            }
        }
        
        activityCalendar = activityData
    }
    
    private func fetchAchievements() {
        let request: NSFetchRequest<AchievementItem> = AchievementItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AchievementItem.unlockedAt, ascending: false)]
        
        do {
            let items = try context.fetch(request)
            if items.isEmpty {
                createDefaultAchievements()
            } else {
                achievements = items.map { convertAchievementToModel($0) }
            }
        } catch {
            print("Failed to fetch achievements: \(error)")
        }
    }
    
    private func createDefaultAchievements() {
        let defaultAchievements = [
            ("achievement_first_task", "achievement_first_task_desc", "checkmark.circle"),
            ("achievement_task_master", "achievement_task_master_desc", "star.fill"),
            ("achievement_week_warrior", "achievement_week_warrior_desc", "flame.fill"),
            ("achievement_consistent", "achievement_consistent_desc", "calendar"),
            ("achievement_organized", "achievement_organized_desc", "list.bullet")
        ]
        
        for (titleKey, descKey, icon) in defaultAchievements {
            let achievement = AchievementItem(context: context)
            achievement.id = UUID()
            achievement.title = titleKey
            achievement.achievementDescription = descKey
            achievement.icon = icon
            achievement.isUnlocked = false
        }
        
        do {
            try context.save()
            fetchAchievements()
        } catch {
            print("Failed to create default achievements: \(error)")
        }
    }
    
    private func checkAndUnlockAchievements() {
        let tasksRequest: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        tasksRequest.predicate = NSPredicate(format: "isCompleted == YES")
        
        do {
            let completedTasks = try context.fetch(tasksRequest)
            
            if completedTasks.count >= 1 {
                unlockAchievement(withTitle: "achievement_first_task")
            }
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let todayTasks = completedTasks.filter { task in
                if let completedAt = task.completedAt {
                    return calendar.isDate(completedAt, inSameDayAs: today)
                }
                return false
            }
            
            if todayTasks.count >= 5 {
                unlockAchievement(withTitle: "achievement_task_master")
            }
            
            let allTasksRequest: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
            let allTasks = try context.fetch(allTasksRequest)
            if allTasks.count >= 10 {
                unlockAchievement(withTitle: "achievement_organized")
            }
            
        } catch {
            print("Failed to check achievements: \(error)")
        }
    }
    
    private func unlockAchievement(withTitle title: String) {
        let request: NSFetchRequest<AchievementItem> = AchievementItem.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@ AND isUnlocked == NO", title)
        
        do {
            if let achievement = try context.fetch(request).first {
                achievement.isUnlocked = true
                achievement.unlockedAt = Date()
                try context.save()
                fetchAchievements()
            }
        } catch {
            print("Failed to unlock achievement: \(error)")
        }
    }
    
    private func convertHabitToModel(_ item: HabitItem) -> HabitModel {
        let dates = (item.completedDates as? [Date]) ?? []
        return HabitModel(
            id: item.id ?? UUID(),
            title: item.title ?? "",
            icon: item.icon ?? "star",
            completedDates: dates,
            createdAt: item.createdAt ?? Date()
        )
    }
    
    private func convertAchievementToModel(_ item: AchievementItem) -> AchievementModel {
        let titleKey = item.title ?? ""
        let descKey = item.achievementDescription ?? ""
        return AchievementModel(
            id: item.id ?? UUID(),
            title: titleKey.localized,
            achievementDescription: descKey.localized,
            icon: item.icon ?? "star",
            isUnlocked: item.isUnlocked,
            unlockedAt: item.unlockedAt
        )
    }
}

