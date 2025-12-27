import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Inicializar Google Mobile Ads SDK (comentado hasta agregar dependencia)
        // GADMobileAds.sharedInstance().start(completionHandler: nil)

        print("🍃 AppDelegate initialized successfully")
        return true
    }
}