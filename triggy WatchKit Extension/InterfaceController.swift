//
//  InterfaceController.swift
//  triggy WatchKit Extension
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

import WatchKit
import Foundation
import WatchConnectivity


class App: NSObject, WCSessionDelegate {
    
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
    
    var appState: AppState = .Inactive {
        didSet {
            if oldValue == appState { return }
            switch appState {
            case .Inactive:
                WKInterfaceController.reloadRootControllers(withNames: ["inactive"], contexts: nil)
            case .Browsing:
                WKInterfaceController.reloadRootControllers(withNames: ["search"], contexts: nil)
            case .Connected:
                WKInterfaceController.reloadRootControllers(withNames: ["config"], contexts: nil)
            case .Capturing:
                WKInterfaceController.reloadRootControllers(withNames: ["capturing"], contexts: nil)
            default: break
            }
        }
    }
    
    var _captureInterval: TimeInterval = 10.0
    var captureInterval: TimeInterval {
        get { return _captureInterval }
        set {
            if newValue != _captureInterval {
                _captureInterval = newValue
                guard let session = session else { return }
                session.sendMessage(["cmd": "setInterval", "interval": _captureInterval], replyHandler: nil, errorHandler: nil)
            }
        }
    }
    
    static let shared: App = {
        return App()
    }()
    
    func handleMessage(_ msg: [String: Any]) {
        if let rawState = msg["state"] as? Int {
            if let state = AppState(rawValue: rawState) {
                appState = state
            } else {
                fatalError("Got invalid state: \(rawState)")
            }
        }
        if let interval = msg["interval"] as? TimeInterval {
            _captureInterval = interval
            if let ctrl = activeController as? ConfigController {
                ctrl.rotation = intervalToSlider(interval)
            }
        }
        if let nextCapture = msg["nextCapture"] as? TimeInterval {
            if WKExtension.shared().applicationState == .active && msg["init"] == nil {
                WKInterfaceDevice.current().play(WKHapticType.click)
            }
            if let ctrl = activeController as? CapturingController {
                let numTaken = msg["photosTaken"] as? UInt ?? 0
                DispatchQueue.main.async {
                    ctrl.nextCapture = nextCapture
                    ctrl.numTaken = numTaken
                }
            }
        }
    }
    
    func fetchRemoteState() {
        guard let session = session else { return }
        session.sendMessage(["cmd": "init"], replyHandler: { (response) in
            self.handleMessage(response)
        }) { error in
            print("ERROR: Could not send init command", error)
            self.appState = .Inactive
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if error != nil {
            print("ERROR: Could not activate session", error!)
        }
        fetchRemoteState()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleMessage(message)
    }
    
}

var activeController: WKInterfaceController?

class ConfigController: WKInterfaceController, WKCrownDelegate {
    
    @IBOutlet var label: WKInterfaceLabel!
    @IBOutlet var button: WKInterfaceButton!

    var setTimer: Timer?
    
    var rotation: CGFloat = 0.5 {
        didSet {
            let txt = NSAttributedString(string: formatInterval(sliderToInterval(rotation)), attributes: [NSFontAttributeName: font])
            label.setAttributedText(txt)
        }
    }
    
    let font = UIFont.systemFont(ofSize: 40).monospacedDigitFont
    
    override func willActivate() {
        activeController = self
        rotation = intervalToSlider(App.shared.captureInterval)
        button.setEnabled(true)
        
        crownSequencer.delegate = self
        crownSequencer.focus()
    }
    
    @IBAction func startCapture() {
        guard let session = App.shared.session else { return }
        button.setEnabled(false)
        setTimer?.invalidate()
        App.shared._captureInterval = sliderToInterval(self.rotation)
        session.sendMessage(["cmd": "startCapture", "interval": App.shared._captureInterval], replyHandler: { response in
            let ok = response["ok"] as? Bool ?? false
            if ok {
                WKInterfaceDevice.current().play(WKHapticType.success)
            } else {
                WKInterfaceDevice.current().play(WKHapticType.failure)
                self.button.setEnabled(true)
            }
        }) { error in
            WKInterfaceDevice.current().play(WKHapticType.failure)
            print("WARNING: Unable to start capture", error)
            self.button.setEnabled(true)
        }
    }
    
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
        rotation += CGFloat(rotationalDelta / 5)
        if rotation > 1.0 {
            WKInterfaceDevice.current().play(WKHapticType.directionUp)
            rotation = 1.0
        }
        if rotation < 0.0 {
            WKInterfaceDevice.current().play(WKHapticType.directionDown)
            rotation = 0.0
        }
        setTimer?.invalidate()
        setTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [unowned self] _ in
            App.shared.captureInterval = sliderToInterval(self.rotation)
        }
    }

}

class InterfaceController: WKInterfaceController {
    
    override func willActivate() {
        activeController = self
    }

}


class CapturingController: WKInterfaceController {
    
    
    @IBOutlet var nextLabel: WKInterfaceLabel?
    @IBOutlet var takenLabel: WKInterfaceLabel?

    
    var nextTimer: Timer?
    var nextCapture: TimeInterval?
    
    static let font = UIFont.systemFont(ofSize: 40).monospacedDigitFont
    
    var numTaken: UInt = 0 {
        didSet {
            let txt = NSAttributedString(string: String(numTaken), attributes: [NSFontAttributeName: CapturingController.font])
            takenLabel?.setAttributedText(txt)
        }
    }
    
    override func willActivate() {
        activeController = self
        nextTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let cap = self?.nextCapture else { return }
            var d = cap - Date.timeIntervalSinceReferenceDate
            if d < 0 { d = 0 }
            let txt = NSAttributedString(string: formatDuration(d), attributes: [NSFontAttributeName: CapturingController.font])
            self?.nextLabel?.setAttributedText(txt)
        }
    }
    
    override func willDisappear() {
        nextTimer?.invalidate()
    }
    
    @IBAction func stopCapture() {
        guard let session = App.shared.session else { return }
        session.sendMessage(["cmd": "stopCapture"], replyHandler: { response in
            let ok = response["ok"] as? Bool ?? false
            if ok {
                WKInterfaceDevice.current().play(WKHapticType.success)
            } else {
                WKInterfaceDevice.current().play(WKHapticType.failure)
            }
        }) { error in
            WKInterfaceDevice.current().play(WKHapticType.failure)
            print("WARNING: Unable to stop capture", error)
        }
    }
    
    
}

