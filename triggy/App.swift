//
//  App.swift
//  triggy
//
//  Created by Johan Nordberg on 08/01/17.
//  Copyright © 2017 FFFF00 Agents AB. All rights reserved.
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

import Foundation
import WatchConnectivity
import UIKit
import Reachability
import SystemConfiguration.CaptiveNetwork
import os.log

class App: NSObject, WCSessionDelegate, SSDPBrowserDelegate, CameraDelegate {

    static let id = "com.yellowagents.triggy"

    static let log = OSLog(subsystem: id, category: "App")
    
    static let StateChangeNotification = Notification.Name(rawValue: "stateChange")
    static let IntervalChangeNotification = Notification.Name(rawValue: "intervalChange")
    static let CaptureNotification = Notification.Name(rawValue: "photoCaptured")
    static let CameraStatusNotification = Notification.Name(rawValue: "cameraStatus")
    static let CameraErrorNotification = Notification.Name(rawValue: "cameraError")
    
    var session: WCSession? {
        get {
            if WCSession.isSupported() {
                let rv = WCSession.default()
                rv.delegate = self
                return rv
            }
            return nil
        }
    }
    var state: AppState = AppState.Inactive {
        didSet {
            NotificationCenter.default.post(name: App.StateChangeNotification, object: self)
            guard let session = session else { return }
            if session.isReachable {
                let msg: [String: Any] = [
                    "cmd": "setState",
                    "state": state.rawValue,
                ]
                session.sendMessage(msg, replyHandler: nil, errorHandler: nil)
            }
        }
    }
    
    static let shared: App = {
        return App()
    }()
    
    internal var _reachability: Reachability?
    var reachability: Reachability? {
        get {
            if _reachability == nil {
                setupReachability()
            }
            return _reachability
        }
    }
    internal func setupReachability() {
        guard let reach = Reachability() else {
            os_log("WARNING: Unable to setup reachability", log: App.log, type: .error)
            return
        }
        try? reach.startNotifier()
        _reachability = reach
    }
    
    var networkSSID: String? {
        if reachability?.isReachableViaWiFi ?? false {
            guard let interfaces = CNCopySupportedInterfaces() as? [String] else { return nil }
            guard interfaces.count > 0 else { return nil }
            let interfaceName = interfaces[0]
            let unsafeInterfaceData = CNCopyCurrentNetworkInfo(interfaceName as CFString)
            if unsafeInterfaceData == nil {
                return nil
            }
            let interfaceData = unsafeInterfaceData as! Dictionary <String,AnyObject>
            return interfaceData["SSID"] as? String
        }
        return nil
    }
    
    
    override init() {
        super.init()
        setupReachability()
    }
    
    // MARK: - SSDP Browser
    
    let browser = SSDPBrowser()
    var browserTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    let cameraServiceID = "urn:schemas-canon-com:service:ICPO-SmartPhoneEOSSystemService:1"
    
    func startBrowsing() {
        browser.delegate = self
        do {
            try browser.beginBrowsing(forService: cameraServiceID)
        } catch let error {
            os_log("WARNING: Could not start SSDP browser - %@", log: App.log, type: .error, String(describing: error))
        }
        state = .Browsing
        browserTask = UIApplication.shared.beginBackgroundTask(withName: "ssdpBrowser", expirationHandler: { [weak self] in
            os_log("WARNING: SSDP Browsing task expired", log: App.log, type: .error)
            self?.browserTask = UIBackgroundTaskInvalid
            self?.stopBrowsing()
        })
    }
    
    func stopBrowsing() {
        browser.stopBrowsing()
        if state == .Browsing { state = .Inactive }
        if browserTask != UIBackgroundTaskInvalid {
            UIApplication.shared.endBackgroundTask(browserTask)
            browserTask = UIBackgroundTaskInvalid
        }
    }
    
    var browserRetry: Timer?
    func browser(_ browser: SSDPBrowser, didError error: Error) {
        os_log("WARNING: SSDP browser error - %@", log: App.log, type: .error, String(describing: error))
        if state == .Browsing {
            DispatchQueue.main.async { [unowned self] in
                self.browserRetry?.invalidate()
                self.browserRetry = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                    browser.stopBrowsing()
                    try? browser.beginBrowsing(forService: self.cameraServiceID)
                }
            }
        }
    }
    
    func browser(_ browser: SSDPBrowser, didFindService service: SSDPService) {
        if !browser.isBrowsing { return }

        browser.stopBrowsing() // not calling self.stopBrowsing yet so the backgorund task keeps running until the camera is connected

        let camera = EOSCamera()
        func statusUpdate(msg: String) {
            NotificationCenter.default.post(name: App.CameraStatusNotification, object: nil, userInfo: ["message": msg])
        }
        camera.connect(to: service.host, status: statusUpdate) { [unowned self] error in
            if error != nil {
                os_log("Could not connect to camera! - %@", log: App.log, type: .error, String(describing: error))
                NotificationCenter.default.post(name: App.CameraErrorNotification, object: nil, userInfo: ["error": error!, "info": "Unable to connect to camera!"])
            } else {
                self.camera = camera
            }
            self.stopBrowsing()
        }
    }
    
    // MARK - Capture Session
    
    let trigger = IntervalTrigger()
    internal var intervalDebounce: Timer?
    internal var _captureInterval: TimeInterval = -1
    internal func setInterval(_ newValue: TimeInterval, broadcast: Bool = true) {
        if _captureInterval != newValue {
            _captureInterval = newValue
            NotificationCenter.default.post(name: App.IntervalChangeNotification, object: self)
            UserDefaults.standard.set(_captureInterval, forKey: AppKeys.captureInterval)
            if !broadcast { return }
            intervalDebounce?.invalidate()
            intervalDebounce = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                guard let session = self?.session else { return }
                if session.isReachable {
                    let msg: [String: Any] = [
                        "cmd": "setInterval",
                        "interval": self!._captureInterval,
                        ]
                    session.sendMessage(msg, replyHandler: nil, errorHandler: nil)
                }
            }
        }
    }
    var captureInterval: TimeInterval {
        get {
            if _captureInterval == -1 {
                _captureInterval = UserDefaults.standard.double(forKey: AppKeys.captureInterval)
            }
            return _captureInterval
        }
        set { setInterval(newValue) }
    }
    
    var camera: Camera? {
        willSet {
            camera?.delegate = nil
            camera?.disconnect()
            if camera != nil && newValue != nil {
                assertionFailure("New camera set with another camera already active")
            }
        }
        didSet {
            camera?.delegate = self
            if camera == nil {
                state = .Inactive
            } else {
                // TODO: start camera connection background task
                state = .Connected
            }
        }
    }
    
    func cameraDisconnected(_ camera: Camera, withError error: Error?) {
        var msg: [String: Any] = ["info": "Lost connection to camera!"]
        if let error = error {
            msg["error"] = error
        }
        NotificationCenter.default.post(name: App.CameraErrorNotification, object: nil, userInfo: msg)
        self.camera = nil
        stopCapture()
    }
    
    var captureTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid

    var photosTaken: UInt = 0
    
    func startCapture() {
        assert(camera != nil, "Cannot start capture without camera")
        do {
            try SoundPlayer.shared.activate(UserDefaults.standard.integer(forKey: AppKeys.shutterSound))
        } catch let error {
            os_log("WARNING: Unable to activate sound - %@", log: App.log, type: .error, String(describing: error))
        }
        trigger.interval = roundedInterval(_captureInterval)
        trigger.action = { [weak self] in
            self?.camera?.triggerShutter({ error in
                if error != nil {
                    self?.captureError(error: error!)
                } else {
                    self?.captureSuccess()
                }
            })
            
        }
        captureTask = UIApplication.shared.beginBackgroundTask(withName: AppKeys.sessionName) { [weak self] in
            os_log("WARNING: Background capture task expired", log: App.log, type: .error)
            self?.captureTask = UIBackgroundTaskInvalid
            self?.stopCapture()
        }
        photosTaken = 0
        state = .Capturing
        camera?.setup { (error) in
            if let error = error {
                os_log("Could not setup camera - %@", log: App.log, type: .error, String(describing: error))
                self.captureError(error: error)
                // FIXME: This hack to close viewcontroller after error is presented should not be needed
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { _ in
                    self.stopCapture()
                })
            } else {
                self.trigger.start()
            }
        }
        
    }
    
    func stopCapture() {
        trigger.stop()
        SoundPlayer.shared.deactivate()
        if captureTask != UIBackgroundTaskInvalid {
            UIApplication.shared.endBackgroundTask(captureTask)
            captureTask = UIBackgroundTaskInvalid
        }
        if camera == nil {
            state = .Inactive
        } else {
            state = .Connected
        }
        
    }
    
    func captureError(error: Error) {
        os_log("WARNING: Capture failed - %@", log: App.log, type: .error, String(describing: error))
        var msg: [String: Any] = ["info": "Capture failed"]
        msg["error"] = error
        NotificationCenter.default.post(name: App.CameraErrorNotification, object: nil, userInfo: msg)
    }
    
    func captureSuccess() {
        photosTaken += 1
        do {
            try SoundPlayer.shared.play()
        } catch let error {
            os_log("WARNING: Unable to play sound after trigger - %@", log: App.log, type: .error, String(describing: error))
        }
        guard let timer = trigger.timer else { return }
        let msg: [String: Any] = [
            "photosTaken": photosTaken,
            "nextCapture": timer.fireDate.timeIntervalSinceReferenceDate
        ]
        NotificationCenter.default.post(name: App.CaptureNotification, object: self, userInfo: msg)
        guard let session = session else { return }
        guard session.isReachable else { return }
        session.sendMessage(msg, replyHandler: nil, errorHandler: nil)
    }
    
    // MARK: - WCSession
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            os_log("WARNING: Unable to activate watch session - %@", log: App.log, type: .error, String(describing: error))
        }
    }
    
    // "quick switching", idk..
    public func sessionDidDeactivate(_ session: WCSession) { self.session?.activate() }
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let cmd = message["cmd"] as? String else {
            os_log("WARNING: Got unknown message from watch", log: App.log, type: .error)
            return
        }
        switch cmd {
        case "setInterval":
            if let interval = message["interval"] as? TimeInterval {
                setInterval(interval, broadcast: false)
            }
        default:
            os_log("WARNING: Got unknown command: %@", log: App.log, type: .error, cmd)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        guard let cmd = message["cmd"] as? String else {
            os_log("WARNING: Got unknown message from watch", log: App.log, type: .error)
            replyHandler(["error": "Invalid message"])
            return
        }
        
        switch cmd {
        case "init":
            var msg: [String: Any] = [
                "init": true,
                "state": state.rawValue,
                "interval": captureInterval,
                "photosTaken": photosTaken,
            ]
            if trigger.timer != nil {
                msg["nextCapture"] = trigger.timer!.fireDate.timeIntervalSinceReferenceDate
            }
            replyHandler(msg)
        case "startCapture":
            if state == .Connected && camera != nil {
                if let interval = message["interval"] as? TimeInterval {
                    setInterval(interval)
                }
                self.startCapture()
                replyHandler(["ok": true])
            } else {
                replyHandler(["ok": false])
            }
        case "stopCapture":
            if state == .Capturing && camera != nil {
                self.stopCapture()
                replyHandler(["ok": true])
            } else {
                replyHandler(["ok": false])
            }
        default:
            os_log("WARNING: Got unknown command: %@", log: App.log, type: .error, cmd)
            replyHandler(["error": "Unknown command"])
        }
        
    }
    
    
}
