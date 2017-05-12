import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        self.handleLauchOptions(launchOptions: launchOptions)

        application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))
        
        return true
    }

    func handleLauchOptions(launchOptions:  [UIApplicationLaunchOptionsKey : Any]? = nil) {
        guard let launchOptions = launchOptions  else {
            return
        }
        
        if launchOptions[UIApplicationLaunchOptionsKey.location] != nil {
            TrackingService.shared.start()
        }
    }
}

