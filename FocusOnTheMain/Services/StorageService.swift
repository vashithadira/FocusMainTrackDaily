import Foundation

class StorageService {
    static let shared = StorageService()
    
    private let tokenKey = "saved_token"
    private let linkKey = "saved_link"
    
    private init() {}
    
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    func saveLink(_ link: String) {
        UserDefaults.standard.set(link, forKey: linkKey)
    }
    
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func getLink() -> String? {
        return UserDefaults.standard.string(forKey: linkKey)
    }
    
    func hasToken() -> Bool {
        return getToken() != nil
    }
}

