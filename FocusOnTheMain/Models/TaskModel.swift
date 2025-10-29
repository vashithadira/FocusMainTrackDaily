import Foundation

struct TaskModel: Identifiable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var isImportant: Bool
    var deadline: Date?
    var createdAt: Date
    var completedAt: Date?
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, isImportant: Bool = false, deadline: Date? = nil, createdAt: Date = Date(), completedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.isImportant = isImportant
        self.deadline = deadline
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

