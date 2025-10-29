import SwiftUI
import CoreData

struct TasksView: View {
    @StateObject private var viewModel: TasksViewModel
    @EnvironmentObject var languageManager: LanguageManager
    @State private var newTaskTitle = ""
    @State private var showingAddTask = false
    @State private var selectedDeadline: Date?
    @State private var isImportant = false
    @State private var refreshID = UUID()
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: TasksViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("today".localized)) {
                        ForEach(todayTasks) { task in
                            TaskItemView(task: task, viewModel: viewModel)
                        }
                    }
                    
                    Section(header: Text("upcoming".localized)) {
                        ForEach(upcomingTasks) { task in
                            TaskItemView(task: task, viewModel: viewModel)
                        }
                    }
                    
                    if !otherTasks.isEmpty {
                        Section(header: Text("all_tasks".localized)) {
                            ForEach(otherTasks) { task in
                                TaskItemView(task: task, viewModel: viewModel)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("tasks".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(isPresented: $showingAddTask) { title, deadline, important in
                    viewModel.addTask(title: title, deadline: deadline, isImportant: important)
                    NotificationCenter.default.post(name: NSNotification.Name("TasksUpdated"), object: nil)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TasksUpdated"))) { _ in
                viewModel.fetchTasks()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
                refreshID = UUID()
            }
        }
        .id(refreshID)
    }
    
    private var todayTasks: [TaskModel] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return viewModel.tasks.filter { task in
            guard let deadline = task.deadline else { return false }
            return deadline >= today && deadline < tomorrow
        }
    }
    
    private var upcomingTasks: [TaskModel] {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        
        return viewModel.tasks.filter { task in
            guard let deadline = task.deadline else { return false }
            return deadline >= tomorrow
        }
    }
    
    private var otherTasks: [TaskModel] {
        return viewModel.tasks.filter { $0.deadline == nil }
    }
}

struct TaskItemView: View {
    let task: TaskModel
    let viewModel: TasksViewModel
    
    var body: some View {
        HStack {
            Button(action: {
                viewModel.toggleTaskCompletion(task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                
                if let deadline = task.deadline {
                    Text(deadline.localizedString(dateStyle: .medium, timeStyle: .none))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if task.isImportant {
                Button(action: {
                    viewModel.toggleTaskImportance(task)
                }) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            } else {
                Button(action: {
                    viewModel.toggleTaskImportance(task)
                }) {
                    Image(systemName: "star")
                        .foregroundColor(.gray)
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.deleteTask(task)
            } label: {
                Label("delete".localized, systemImage: "trash")
            }
        }
    }
}

struct AddTaskView: View {
    @Binding var isPresented: Bool
    let onAdd: (String, Date?, Bool) -> Void
    @EnvironmentObject var languageManager: LanguageManager
    
    @State private var title = ""
    @State private var hasDeadline = false
    @State private var deadline = Date()
    @State private var isImportant = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("task_details".localized)) {
                    TextField("task_title".localized, text: $title)
                    
                    Toggle("important".localized, isOn: $isImportant)
                    
                    Toggle("set_deadline".localized, isOn: $hasDeadline)
                    
                    if hasDeadline {
                        DatePicker("deadline".localized, selection: $deadline, displayedComponents: [.date, .hourAndMinute])
                            .environment(\.locale, Locale(identifier: languageManager.currentLanguage))
                    }
                }
            }
            .navigationTitle("new_task".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("add".localized) {
                        onAdd(title, hasDeadline ? deadline : nil, isImportant)
                        isPresented = false
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

