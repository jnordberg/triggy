//
//  TimelapseRunningViewController.swift
//  triggy
//
//  Created by Johan Nordberg on 07/01/17.
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
import UIKit


class TimelapseRunningViewController: UIViewController {
    
    @IBOutlet var nextLabel: UILabel!
    @IBOutlet var takenLabel: UILabel!
    @IBOutlet var runtimeLabel: UILabel!
    //@IBOutlet var errorLabel: UILabel!
    
    var observerToken: NSObjectProtocol?
    var captureObserverToken: NSObjectProtocol?
    var errorObserverToken: NSObjectProtocol?
    
    var refreshTimer: Timer?
    var nextTarget: TimeInterval?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nextLabel.font = nextLabel.font.monospacedDigitFont
        takenLabel.font = takenLabel.font.monospacedDigitFont
        runtimeLabel.font = runtimeLabel.font.monospacedDigitFont
        shutterSpeedLabel.font = shutterSpeedLabel.font.monospacedDigitFont
        apertureLabel.font = apertureLabel.font.monospacedDigitFont
        isoSpeedLabel.font = isoSpeedLabel.font.monospacedDigitFont
        remainingShotsLabel.font = remainingShotsLabel.font.monospacedDigitFont
    }
    
    func configureView() {
        takenLabel.text = String(format: "%d", App.shared.photosTaken)
        self.runtimeLabel.text = formatDuration(Double(App.shared.photosTaken) / 24.0)

    }

    func configureView(withCameraConfig config: CameraConfig) {
        if let shutterSpeed = config.shutterSpeed {
            shutterSpeedLabel.text = shutterSpeed.description
        }
        if let aperture = config.aperture {
            apertureLabel.text = String(format: "ƒ/%.1f", aperture)
        }
        if let isoSpeed = config.isoSpeed {
            if isoSpeed == 0 {
                isoSpeedLabel.text = "Auto"
            } else {
                isoSpeedLabel.text = String(format: "%d", isoSpeed)
            }
        }
    }

    var numErrors = 0
    
    override func viewWillAppear(_ animated: Bool) {
        numErrors = 0
        configureView()
        observerToken = NotificationCenter.default.addObserver(forName: App.StateChangeNotification, object: nil, queue: OperationQueue.main) { note in
            let state = App.shared.state
            if state != .Capturing {
                self.dismiss(animated: true, completion: nil)
            }
        }
        captureObserverToken = NotificationCenter.default.addObserver(forName: App.CaptureNotification, object: nil, queue: OperationQueue.main) { note in
            guard let info = note.userInfo as? [String: Any] else { return }
            self.nextTarget = info["nextCapture"] as? TimeInterval
            self.configureView()
        }
        errorObserverToken = NotificationCenter.default.addObserver(forName: App.CameraErrorNotification, object: nil, queue: OperationQueue.main) { note in
            self.numErrors += 1
            //self.errorLabel.text = String(format: "err %d", self.numErrors)
        }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let target = self?.nextTarget else { return }
            var d = target - Date.timeIntervalSinceReferenceDate
            if d < 0 { d = 0 }
            self?.nextLabel.text = formatDuration(d)
        }

        NotificationCenter.default.addObserver(
            self, selector: #selector(newThumbnail), name: CameraNotifications.thumbnail, object: nil
        )

        NotificationCenter.default.addObserver(
            self, selector: #selector(newConfig), name: CameraNotifications.configChanged, object: nil
        )

        NotificationCenter.default.addObserver(
            self, selector: #selector(remainingShots), name: CameraNotifications.remainingShots, object: nil
        )

        NotificationCenter.default.addObserver(
            self, selector: #selector(programUpdate), name: AutoShutterProgram.notification, object: nil
        )

        if let camera = App.shared.camera, let config = try? camera.getConfig() {
            configureView(withCameraConfig: config)
        }

        prototypeInfoLabel = programInfoStack.arrangedSubviews.first as? UILabel
        programInfoStack.arrangedSubviews.forEach {
            programInfoStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    var prototypeInfoLabel: UILabel!
    @IBOutlet weak var programInfoStack: UIStackView!
    func programUpdate(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any] else { return }

        let info = userInfo
//            .filter { $0.key == "lum" || $0.key.contains("EV") || $0.key.contains("shutter")  }
            .sorted { $0.key > $1.key }

        for (name, _value) in info {
            let value: String
            if let v = _value as? Double {
                value = String(format: "%.2f", v)
            } else {
                value = String(describing: _value)
            }
            let label: UILabel
            if let existing = programInfoStack.arrangedSubviews.first(where: { $0.accessibilityIdentifier == name }) as? UILabel {
                label = existing
            } else {
                label = UILabel()
                label.font = prototypeInfoLabel.font.monospacedDigitFont
                label.accessibilityIdentifier = name
                programInfoStack.addArrangedSubview(label)
            }
            label.text = String(format: "%@\t %@", name, value)
        }


    }

    @IBOutlet weak var remainingShotsLabel: UILabel!
    func remainingShots(notification: Notification) {
        guard let value = notification.userInfo?["value"] as? UInt32 else { return }
        remainingShotsLabel.text = String(format: "~%d", value)
    }

    @IBOutlet weak var shutterSpeedLabel: UILabel!
    @IBOutlet weak var apertureLabel: UILabel!
    @IBOutlet weak var isoSpeedLabel: UILabel!
    func newConfig(notification: Notification) {
        guard let config = notification.userInfo?["config"] as? CameraConfig else { return }
        configureView(withCameraConfig: config)
    }

    @IBOutlet weak var thumbnailView: UIImageView!
    func newThumbnail(notification: Notification) {
        guard
            UIApplication.shared.applicationState == .active,
            let image = notification.userInfo?["image"] as? CIImage
        else {
            return
        }
        thumbnailView.contentMode = .scaleAspectFit
        thumbnailView.image = UIImage(ciImage: image)
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        if let token = observerToken {
            NotificationCenter.default.removeObserver(token)
            observerToken = nil
        }
        if let token = captureObserverToken {
            NotificationCenter.default.removeObserver(token)
            captureObserverToken = nil
        }
    }
    
    @IBAction func stopCapture() {
        App.shared.stopCapture()
    }
}
