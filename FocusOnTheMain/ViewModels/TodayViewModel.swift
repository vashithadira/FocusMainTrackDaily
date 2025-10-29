import Foundation
import CoreData
import Combine

class TodayViewModel: ObservableObject {
    @Published var todayTasks: [TaskModel] = []
    @Published var todayHabits: [HabitModel] = []
    @Published var completionProgress: Double = 0.0
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchTodayData()
    }
    
    func fetchTodayData() {
        fetchTodayTasks()
        fetchTodayHabits()
        calculateProgress()
    }
    
    private func fetchTodayTasks() {
        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicates = [
            NSPredicate(format: "deadline >= %@ AND deadline < %@", startOfDay as NSDate, endOfDay as NSDate),
            NSPredicate(format: "deadline == nil AND isCompleted == NO")
        ]
        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskItem.isImportant, ascending: false),
            NSSortDescriptor(keyPath: \TaskItem.deadline, ascending: true)
        ]
        
        do {
            let items = try context.fetch(request)
            todayTasks = items.map { convertTaskToModel($0) }
        } catch {
            print("Failed to fetch today tasks: \(error)")
        }
    }
    
    private func fetchTodayHabits() {
        let request: NSFetchRequest<HabitItem> = HabitItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \HabitItem.createdAt, ascending: true)]
        
        do {
            let items = try context.fetch(request)
            todayHabits = items.map { convertHabitToModel($0) }
        } catch {
            print("Failed to fetch today habits: \(error)")
        }
    }
    
    private func calculateProgress() {
        let totalItems = todayTasks.count + todayHabits.count
        guard totalItems > 0 else {
            completionProgress = 0.0
            return
        }
        
        let completedTasks = todayTasks.filter { $0.isCompleted }.count
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let completedHabits = todayHabits.filter { habit in
            habit.completedDates.contains { calendar.isDate($0, inSameDayAs: today) }
        }.count
        
        let completedItems = completedTasks + completedHabits
        completionProgress = Double(completedItems) / Double(totalItems)
    }
    
    private func convertTaskToModel(_ item: TaskItem) -> TaskModel {
        return TaskModel(
            id: item.id ?? UUID(),
            title: item.title ?? "",
            isCompleted: item.isCompleted,
            isImportant: item.isImportant,
            deadline: item.deadline,
            createdAt: item.createdAt ?? Date(),
            completedAt: item.completedAt
        )
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
}

