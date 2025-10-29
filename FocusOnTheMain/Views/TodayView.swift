import SwiftUI
import CoreData

struct TodayView: View {
    @StateObject private var viewModel: TodayViewModel
    @StateObject private var tasksViewModel: TasksViewModel
    @StateObject private var habitsViewModel: HabitsViewModel
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: TodayViewModel(context: context))
        _tasksViewModel = StateObject(wrappedValue: TasksViewModel(context: context))
        _habitsViewModel = StateObject(wrappedValue: HabitsViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    progressSection
                    
                    if !viewModel.todayTasks.isEmpty {
                        tasksSection
                    }
                    
                    if !viewModel.todayHabits.isEmpty {
                        habitsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Today")
            .onAppear {
                viewModel.fetchTodayData()
                tasksViewModel.fetchTasks()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TasksUpdated"))) { _ in
                viewModel.fetchTodayData()
            }
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Progress")
                .font(.headline)
            
            ProgressView(value: viewModel.completionProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(height: 8)
            
            Text("\(Int(viewModel.completionProgress * 100))% Complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tasks")
                .font(.headline)
            
            ForEach(viewModel.todayTasks) { task in
                TaskRowView(task: task) {
                    tasksViewModel.toggleTaskCompletion(task)
                    viewModel.fetchTodayData()
                }
            }
        }
    }
    
    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Habits")
                .font(.headline)
            
            ForEach(viewModel.todayHabits) { habit in
                HabitRowView(habit: habit, isCompleted: isHabitCompletedToday(habit)) {
                    habitsViewModel.toggleHabitCompletion(habit, date: Date())
                    viewModel.fetchTodayData()
                }
            }
        }
    }
    
    private func isHabitCompletedToday(_ habit: HabitModel) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return habit.completedDates.contains { calendar.isDate($0, inSameDayAs: today) }
    }
}

struct TaskRowView: View {
    let task: TaskModel
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                if let deadline = task.deadline {
                    Text(deadline, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if task.isImportant {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct HabitRowView: View {
    let habit: HabitModel
    let isCompleted: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .green : .gray)
                    .font(.title3)
            }
            
            HStack {
                Text(habit.icon)
                    .font(.title3)
                Text(habit.title)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

