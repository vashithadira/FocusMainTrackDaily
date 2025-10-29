import Foundation
import CoreData
import Combine

class HabitsViewModel: ObservableObject {
    @Published var habits: [HabitModel] = []
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchHabits()
    }
    
    func fetchHabits() {
        let request: NSFetchRequest<HabitItem> = HabitItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \HabitItem.createdAt, ascending: true)]
        
        do {
            let items = try context.fetch(request)
            habits = items.map { convertToModel($0) }
        } catch {
            print("Failed to fetch habits: \(error)")
        }
    }
    
    func addHabit(title: String, icon: String) {
        let newHabit = HabitItem(context: context)
        newHabit.id = UUID()
        newHabit.title = title
        newHabit.icon = icon
        newHabit.completedDates = NSArray()
        newHabit.createdAt = Date()
        
        saveContext()
        fetchHabits()
        NotificationCenter.default.post(name: NSNotification.Name("HabitsUpdated"), object: nil)
    }
    
    func toggleHabitCompletion(_ habit: HabitModel, date: Date) {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        
        var updatedDates = habit.completedDates
        if let index = updatedDates.firstIndex(where: { calendar.isDate($0, inSameDayAs: normalizedDate) }) {
            updatedDates.remove(at: index)
        } else {
            updatedDates.append(normalizedDate)
        }
        
        let request: NSFetchRequest<HabitItem> = HabitItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", habit.id as CVarArg)
        
        do {
            if let item = try context.fetch(request).first {
                item.completedDates = updatedDates as NSArray
                saveContext()
                fetchHabits()
                NotificationCenter.default.post(name: NSNotification.Name("HabitsUpdated"), object: nil)
            }
        } catch {
            print("Failed to update habit: \(error)")
        }
    }
    
    func deleteHabit(_ habit: HabitModel) {
        let request: NSFetchRequest<HabitItem> = HabitItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", habit.id as CVarArg)
        
        do {
            if let item = try context.fetch(request).first {
                context.delete(item)
                saveContext()
                fetchHabits()
                NotificationCenter.default.post(name: NSNotification.Name("HabitsUpdated"), object: nil)
            }
        } catch {
            print("Failed to delete habit: \(error)")
        }
    }
    
    func isHabitCompleted(_ habit: HabitModel, date: Date) -> Bool {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        return habit.completedDates.contains { calendar.isDate($0, inSameDayAs: normalizedDate) }
    }
    
    private func convertToModel(_ item: HabitItem) -> HabitModel {
        let dates = (item.completedDates as? [Date]) ?? []
        return HabitModel(
            id: item.id ?? UUID(),
            title: item.title ?? "",
            icon: item.icon ?? "star",
            completedDates: dates,
            createdAt: item.createdAt ?? Date()
        )
    }
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

