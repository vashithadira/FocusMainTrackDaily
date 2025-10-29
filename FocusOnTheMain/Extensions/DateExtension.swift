import Foundation

extension Date {
    func localizedString(dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .none) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        
        let currentLanguage = LanguageManager.shared.currentLanguage
        formatter.locale = Locale(identifier: currentLanguage)
        
        return formatter.string(from: self)
    }
}

