import Foundation
import Combine

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "appLanguage")
            NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
        }
    }
    
    private init() {
        if let saved = UserDefaults.standard.string(forKey: "appLanguage") {
            currentLanguage = saved
        } else {
            currentLanguage = Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en"
        }
    }
    
    func localizedString(_ key: String) -> String {
        guard let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
    
    var hasChosenLanguage: Bool {
        return UserDefaults.standard.bool(forKey: "hasChosenLanguage")
    }
    
    func setLanguageChosen() {
        UserDefaults.standard.set(true, forKey: "hasChosenLanguage")
    }
    
    var availableLanguages: [(code: String, name: String)] {
        return [
            ("ar", "العربية"),
            ("ca", "Català"),
            ("zh-Hans", "简体中文"),
            ("zh-Hant", "繁體中文"),
            ("hr", "Hrvatski"),
            ("cs", "Čeština"),
            ("da", "Dansk"),
            ("nl", "Nederlands"),
            ("en", "English"),
            ("en-AU", "English (Australia)"),
            ("en-CA", "English (Canada)"),
            ("en-GB", "English (U.K.)"),
            ("fi", "Suomi"),
            ("fr", "Français"),
            ("fr-CA", "Français (Canada)"),
            ("de", "Deutsch"),
            ("el", "Ελληνικά"),
            ("he", "עברית"),
            ("hi", "हिन्दी"),
            ("hu", "Magyar"),
            ("id", "Bahasa Indonesia"),
            ("it", "Italiano"),
            ("ja", "日本語"),
            ("ko", "한국어"),
            ("ms", "Bahasa Melayu"),
            ("no", "Norsk"),
            ("pl", "Polski"),
            ("pt-BR", "Português (Brasil)"),
            ("pt-PT", "Português (Portugal)"),
            ("ro", "Română"),
            ("ru", "Русский"),
            ("sk", "Slovenčina"),
            ("es", "Español"),
            ("es-MX", "Español (México)"),
            ("sv", "Svenska"),
            ("th", "ไทย"),
            ("tr", "Türkçe"),
            ("uk", "Українська"),
            ("vi", "Tiếng Việt")
        ]
    }
}

extension String {
    var localized: String {
        return LanguageManager.shared.localizedString(self)
    }
}

