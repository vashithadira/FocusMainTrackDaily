import Foundation
import CoreData
import Combine

class TasksViewModel: ObservableObject {
    @Published var tasks: [TaskModel] = []
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchTasks()
    }
    
    func fetchTasks() {
        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskItem.createdAt, ascending: false)]
        
        do {
            let items = try context.fetch(request)
            tasks = items.map { convertToModel($0) }
        } catch {
            print("Failed to fetch tasks: \(error)")
        }
    }
    
    func addTask(title: String, deadline: Date? = nil, isImportant: Bool = false) {
        let newTask = TaskItem(context: context)
        newTask.id = UUID()
        newTask.title = title
        newTask.isCompleted = false
        newTask.isImportant = isImportant
        newTask.deadline = deadline
        newTask.createdAt = Date()
        
        saveContext()
        fetchTasks()
        NotificationCenter.default.post(name: NSNotification.Name("TasksUpdated"), object: nil)
    }
    
    func updateTask(_ task: TaskModel) {
        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        
        do {
            if let item = try context.fetch(request).first {
                item.title = task.title
                item.isCompleted = task.isCompleted
                item.isImportant = task.isImportant
                item.deadline = task.deadline
                item.completedAt = task.completedAt
                saveContext()
                fetchTasks()
            }
        } catch {
            print("Failed to update task: \(error)")
        }
    }
    
    func deleteTask(_ task: TaskModel) {
        let request: NSFetchRequest<TaskItem> = TaskItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        
        do {
            if let item = try context.fetch(request).first {
                context.delete(item)
                saveContext()
                fetchTasks()
                NotificationCenter.default.post(name: NSNotification.Name("TasksUpdated"), object: nil)
            }
        } catch {
            print("Failed to delete task: \(error)")
        }
    }
    
    func toggleTaskCompletion(_ task: TaskModel) {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        updatedTask.completedAt = updatedTask.isCompleted ? Date() : nil
        updateTask(updatedTask)
        NotificationCenter.default.post(name: NSNotification.Name("TasksUpdated"), object: nil)
    }
    
    func toggleTaskImportance(_ task: TaskModel) {
        var updatedTask = task
        updatedTask.isImportant.toggle()
        updateTask(updatedTask)
        NotificationCenter.default.post(name: NSNotification.Name("TasksUpdated"), object: nil)
    }
    
    private func convertToModel(_ item: TaskItem) -> TaskModel {
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
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

