//
//
// Created by Ashamaz Shidov on 23/9/24
//
        

import UIKit
import AppNexusSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        XandrAd.sharedInstance().initWithMemberID(10094, preCacheRequestObjects: true ,completionHandler: { (status) in
            print("Started: \(status)")
        })
        return true
    }
}

