import SwiftUI
import CoreData

struct HabitsView: View {
    @StateObject private var viewModel: HabitsViewModel
    @EnvironmentObject var languageManager: LanguageManager
    @State private var showingAddHabit = false
    @State private var refreshID = UUID()
    
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
            .navigationTitle("habits".localized)
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
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
                refreshID = UUID()
            }
        }
        .id(refreshID)
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
                        Label("delete".localized, systemImage: "trash")
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
            
            Text("\(streakCount) \("day_streak".localized)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func dayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        switch weekday {
        case 1: return "day_sun".localized
        case 2: return "day_mon".localized
        case 3: return "day_tue".localized
        case 4: return "day_wed".localized
        case 5: return "day_thu".localized
        case 6: return "day_fri".localized
        case 7: return "day_sat".localized
        default: return "?"
        }
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
    @EnvironmentObject var languageManager: LanguageManager
    
    @State private var title = ""
    @State private var selectedIcon = "⭐️"
    
    let availableIcons = ["⭐️", "💪", "📚", "💧", "🏃", "🧘", "🎯", "✍️", "🎵", "🌱"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("habit_details".localized)) {
                    TextField("habit_name".localized, text: $title)
                }
                
                Section(header: Text("choose_icon".localized)) {
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
            .navigationTitle("new_habit".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("add".localized) {
                        onAdd(title, selectedIcon)
                        isPresented = false
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

