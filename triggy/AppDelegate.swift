//
//  AppDelegate.swift
//  triggy
//
//  Created by Johan Nordberg on 2016-12-23.
//  Copyright © 2016 FFFF00 Agents AB. All rights reserved.
//
//  Triggy is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Triggy is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Triggy.  If not, see <http://www.gnu.org/licenses/>.
//

import UIKit
import WatchConnectivity
import PTP
import AVFoundation


public extension UIWindow {
    public var visibleViewController: UIViewController? {
        return UIWindow.getVisibleViewControllerFrom(vc: self.rootViewController)
    }
    public static func getVisibleViewControllerFrom(vc: UIViewController?) -> UIViewController? {
        if let nc = vc as? UINavigationController {
            return UIWindow.getVisibleViewControllerFrom(vc: nc.visibleViewController)
        } else if let tc = vc as? UITabBarController {
            return UIWindow.getVisibleViewControllerFrom(vc: tc.selectedViewController)
        } else {
            if let pvc = vc?.presentedViewController {
                return UIWindow.getVisibleViewControllerFrom(vc: pvc)
            } else {
                return vc
            }
        }
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private var lastAlert: WindowAlert?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        UserDefaults.standard.register(defaults: [
            "shutterSound": 3,
            "captureInterval": 10.0,
        ])

        // vem vare som kasta?!
        signal(SIGPIPE, SIG_IGN)
        
        App.shared.session?.activate()
        
        NotificationCenter.default.addObserver(forName: App.CameraErrorNotification, object: nil, queue: OperationQueue.main) { note in
            guard let info = note.userInfo else { assertionFailure("Got error notification with no userInfo!"); return }
            let title = "ERROR"
            var msg = "Unknown error"
            if let info = info["info"] as? String {
                msg = info
            }
            if let error = info["error"] as? Error {
                msg += "\n\n"
                if let error = error as? PTPError {
                    switch error {
                    case .InvalidPacket(let message, let type):
                        if type == PTPPacketType.InitFail  {
                            msg += "Camera is responding but configured with another app, create a new configuration on the camera to connect."
                        } else {
                            msg += message
                        }
                    case .General(let message):
                        msg += message
                    default:
                        msg += "\(error)"
                    }
                } else {
                    msg += "\(error)"
                }
            }

            if let last = self.lastAlert {
                if last.visible { var _ = last.hide() }
            }
            
            let alert = WindowAlert(title: title, message: msg, preferredStyle: .alert, referenceWindow: self.window!)
            
            alert.add(action: WindowAlertAction(title: "Ok", style: .default, handler: nil))
            let _ = alert.show()
            self.lastAlert = alert
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        if App.shared.state == .Browsing {
            App.shared.stopBrowsing()
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.

    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        if App.shared.state == .Inactive {
            App.shared.startBrowsing()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

