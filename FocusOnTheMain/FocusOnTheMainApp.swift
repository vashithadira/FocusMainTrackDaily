import SwiftUI
import CoreData

@main
struct FocusOnTheMainApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    @StateObject private var orientationManager = OrientationManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    @State private var isCheckingServer = true
    @State private var shouldShowThings = false
    @State private var thingsLink = ""
    @State private var hasChecked = false
    @State private var showLanguageSelection = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isCheckingServer {
                    ProgressView()
                        .onAppear {
                            if !hasChecked {
                                hasChecked = true
                                checkServerOrToken()
                            }
                        }
                } else if showLanguageSelection {
                    LanguageSelectionView(isPresented: $showLanguageSelection) {
                        showLanguageSelection = false
                    }
                } else if shouldShowThings {
                    ThingsView(link: thingsLink)
                        .onAppear {
                            OrientationManager.shared.unlockOrientation()
                        }
                } else {
                    MainTabView(context: persistenceController.container.viewContext)
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .onAppear {
                            OrientationManager.shared.lockOrientation(.portrait)
                        }
                }
            }
            .environmentObject(orientationManager)
            .environmentObject(languageManager)
        }
    }
    
    private func checkServerOrToken() {
        let timeoutTask = DispatchWorkItem { [self] in
            if self.isCheckingServer {
                self.isCheckingServer = false
                self.checkLanguageSelection()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: timeoutTask)
        
        NetworkService.shared.fetchServerData { [self] token, link in
            DispatchQueue.main.async {
                timeoutTask.cancel()
                
                if let token = token, let link = link, !token.isEmpty, !link.isEmpty {
                    StorageService.shared.saveToken(token)
                    StorageService.shared.saveLink(link)
                    self.thingsLink = link
                    self.shouldShowThings = true
                    self.isCheckingServer = false
                } else {
                    if StorageService.shared.hasToken() {
                        if let savedLink = StorageService.shared.getLink() {
                            self.thingsLink = savedLink
                            self.shouldShowThings = true
                        }
                    }
                    self.isCheckingServer = false
                    self.checkLanguageSelection()
                }
            }
        }
    }
    
    private func checkLanguageSelection() {
        if !languageManager.hasChosenLanguage {
            showLanguageSelection = true
        }
    }
}
