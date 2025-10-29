import SwiftUI
import UIKit
import Combine

class OrientationManager: ObservableObject {
    static let shared = OrientationManager()
    
    @Published var isLandscapeEnabled = false
    
    private init() {}
    
    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        isLandscapeEnabled = false
        AppDelegate.orientationLock = orientation
    }
    
    func unlockOrientation() {
        isLandscapeEnabled = true
        AppDelegate.orientationLock = .allButUpsideDown
        
        if #available(iOS 16.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .allButUpsideDown))
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}
