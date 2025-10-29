import SwiftUI
import CoreData

@main
struct FocusOnTheMainApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    @StateObject private var orientationManager = OrientationManager.shared
    @State private var isCheckingServer = true
    @State private var shouldShowThings = false
    @State private var thingsLink = ""
    @State private var hasChecked = false
    
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
        }
    }
    
    private func checkServerOrToken() {
        if StorageService.shared.hasToken() {
            if let savedLink = StorageService.shared.getLink() {
                self.thingsLink = savedLink
                self.shouldShowThings = true
            }
            self.isCheckingServer = false
        } else {
            let timeoutTask = DispatchWorkItem { [self] in
                if self.isCheckingServer {
                    self.isCheckingServer = false
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
                    }
                    self.isCheckingServer = false
                }
            }
        }
    }
}
