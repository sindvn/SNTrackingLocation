import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var locationManager = TrackingLocationManager()
    var backgroundLocationManager = BackgroundLocationManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        if launchOptions?[UIApplicationLaunchOptionsKey.location] != nil {
            BackgroundDebug().write(string: "UIApplicationLaunchOptionsLocationKey")
            
            if let vc = self.window?.rootViewController as? ViewController {
                vc.startBackgroundTracking()
            }
            /*
            backgroundLocationManager.startBackground() { result in
                if case let .Success(location) = result {
                    LocationLogger().writeLocationToFile(location: location)
                }
            }*/
        }

        application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))
        
        return true
    }

}

