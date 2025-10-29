import SwiftUI
import CoreData

struct HabitsView: View {
    @StateObject private var viewModel: HabitsViewModel
    @State private var showingAddHabit = false
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: HabitsViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.habits) { habit in
                        HabitCardView(habit: habit, viewModel: viewModel)
                    }
                }
                .padding()
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddHabit = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView(isPresented: $showingAddHabit) { title, icon in
                    viewModel.addHabit(title: title, icon: icon)
                }
            }
        }
    }
}

struct HabitCardView: View {
    let habit: HabitModel
    let viewModel: HabitsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(habit.icon)
                    .font(.title)
                Text(habit.title)
                    .font(.headline)
                Spacer()
                Menu {
                    Button(role: .destructive) {
                        viewModel.deleteHabit(habit)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    let date = Calendar.current.date(byAdding: .day, value: -6 + index, to: Date())!
                    let isCompleted = viewModel.isHabitCompleted(habit, date: date)
                    
                    Button(action: {
                        viewModel.toggleHabitCompletion(habit, date: date)
                    }) {
                        VStack(spacing: 4) {
                            Text(dayLabel(for: date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Circle()
                                .fill(isCompleted ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: isCompleted ? "checkmark" : "")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                )
                        }
                    }
                }
            }
            
            Text("\(streakCount) day streak")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).prefix(1).uppercased()
    }
    
    private var streakCount: Int {
        let calendar = Calendar.current
        var count = 0
        var currentDate = Date()
        
        while viewModel.isHabitCompleted(habit, date: currentDate) {
            count += 1
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDate
        }
        
        return count
    }
}

struct AddHabitView: View {
    @Binding var isPresented: Bool
    let onAdd: (String, String) -> Void
    
    @State private var title = ""
    @State private var selectedIcon = "⭐️"
    
    let availableIcons = ["⭐️", "💪", "📚", "💧", "🏃", "🧘", "🎯", "✍️", "🎵", "🌱"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Habit Details")) {
                    TextField("Habit name", text: $title)
                }
                
                Section(header: Text("Choose Icon")) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                            }) {
                                Text(icon)
                                    .font(.system(size: 40))
                                    .frame(width: 60, height: 60)
                                    .background(selectedIcon == icon ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onAdd(title, selectedIcon)
                        isPresented = false
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

