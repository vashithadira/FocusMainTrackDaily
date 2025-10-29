import SwiftUI
import CoreData

struct SummaryView: View {
    @StateObject private var viewModel: SummaryViewModel
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: SummaryViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    weeklyProgressSection
                    habitsProgressSection
                    achievementsSection
                    activityCalendarSection
                }
                .padding()
            }
            .navigationTitle("Summary")
            .onAppear {
                viewModel.fetchStatistics()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TasksUpdated"))) { _ in
                viewModel.fetchStatistics()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HabitsUpdated"))) { _ in
                viewModel.fetchStatistics()
            }
        }
    }
    
    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Tasks Completed")
                .font(.headline)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(viewModel.weeklyTasksCompleted.enumerated()), id: \.offset) { index, count in
                    VStack {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 30, height: CGFloat(count) * 10 + 20)
                            .cornerRadius(4)
                        
                        Text(dayLabel(for: index))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var habitsProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Habits Progress")
                .font(.headline)
            
            ForEach(viewModel.habitsProgress, id: \.habit.id) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(item.habit.icon)
                        Text(item.habit.title)
                        Spacer()
                        Text("\(Int(item.progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: item.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.achievements) { achievement in
                    VStack(spacing: 8) {
                        Image(systemName: achievement.icon)
                            .font(.system(size: 40))
                            .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
                            .frame(width: 50, height: 50)
                        
                        Text(achievement.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(achievement.achievementDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 160)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 8)
                    .background(achievement.isUnlocked ? Color.blue.opacity(0.15) : Color(.systemGray5))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var activityCalendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Calendar")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(sortedActivityDates, id: \.key) { date, count in
                    Rectangle()
                        .fill(activityColor(for: count))
                        .frame(height: 20)
                        .cornerRadius(2)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var sortedActivityDates: [(key: Date, value: Int)] {
        viewModel.activityCalendar.sorted { $0.key < $1.key }.suffix(49)
    }
    
    private func activityColor(for count: Int) -> Color {
        switch count {
        case 0:
            return Color.gray.opacity(0.1)
        case 1...2:
            return Color.green.opacity(0.3)
        case 3...4:
            return Color.green.opacity(0.6)
        default:
            return Color.green
        }
    }
    
    private func dayLabel(for index: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -6 + index, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).prefix(1).uppercased()
    }
}

