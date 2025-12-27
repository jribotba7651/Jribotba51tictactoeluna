import UIKit
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Inicializar Google Mobile Ads SDK
        GADMobileAds.sharedInstance().start(completionHandler: { status in
            print("🎯 Google Mobile Ads SDK initialized successfully")
            print("🎯 AdMob adapters status: \(status)")
        })

        print("🍃 AppDelegate initialized successfully")
        return true
    }
}