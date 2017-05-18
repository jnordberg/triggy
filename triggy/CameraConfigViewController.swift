//
//  CameraConfigViewController.swift
//  triggy
//
//  Created by Johan Nordberg on 13/03/2017.
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
import os.log

class CameraConfigViewController: UIViewController {

    var camera: Camera!

    @IBAction func done(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }

    @IBOutlet weak var snapshotButton: UIBarButtonItem!
    @IBAction func takeSnapshot(_ sender: UIBarButtonItem) {
        Activity.labelUserAction("Take snapshot")
        _takeSnapshot()
    }

    private func _takeSnapshot() {
        snapshotButton.isEnabled = false
        camera.captureImage { (image, error) in
            self.snapshotButton.isEnabled = true
            if let error = error {
                os_log("Unable to capture snapshot: %{public}@", log: App.log, type: .error, String(describing: error))
            }
            guard let image = image else { return }
            self.previewImageView.image = UIImage(ciImage: image)
        }
    }

    override func viewDidLoad() {
        do {
            _setConfigOptions(options: try camera.getConfigOptions())
        } catch {
            os_log("Unable to get config options: %{public}@", log: App.log, type: .error, String(describing: error))
        }
    }

    func _setConfigOptions(options: CameraConfigOptions) {
        apertureSlider.isEnabled = options.aperture.count > 0

        if let min = options.isoSpeed.min() {
            isoSpeedSlider.minimumValue = log(Float(min))
        }
        if let max = options.isoSpeed.max() {
            isoSpeedSlider.maximumValue = log(Float(max))
        }
        if let min = options.shutterSpeed.min() {
            shutterSpeedSlider.minimumValue = Float(log(min.seconds))
        }
        if let max = options.shutterSpeed.max() {
            shutterSpeedSlider.maximumValue = Float(log(max.seconds))
        }
        if let min = options.aperture.min() {
            apertureSlider.minimumValue = Float(log(min))
        }
        if let max = options.aperture.max() {
            apertureSlider.maximumValue = Float(log(max))
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        cameraNameLabel.text = camera.name
        NotificationCenter.default.addObserver(self, selector: #selector(configChanged), name: CameraNotifications.configChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(configOptionsChanged), name: CameraNotifications.configOptionsChanged, object: nil)
        do {
            let config = try camera.getConfig()
            _setConfig(config)
        } catch {
            os_log("Unable to get camera config: %{public}@", log: App.log, type: .error, String(describing: error))
        }

    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }

    func configChanged(notification: Notification) {
        guard let config = notification.userInfo?["config"] as? CameraConfig else { return }
        _setConfig(config)
    }


    func configOptionsChanged(notification: Notification) {
        guard let options = notification.userInfo?["configOptions"] as? CameraConfigOptions else { return }
        _setConfigOptions(options: options)
    }

    var currentConfig: CameraConfig!
    private func _setConfig(_ config: CameraConfig) {
        currentConfig = config
        if let shutterSpeed = config.shutterSpeed {
            shutterSpeedSlider.value = log(Float(shutterSpeed.seconds))
            shutterSpeedLabel.text = shutterSpeed.description
        }
        if let aperture = config.aperture {
            apertureSlider.value = log(Float(aperture))
            apertureLabel.text = String(format: "ƒ/%.1f", aperture)
        }
        if let isoSpeed = config.isoSpeed {
            isoSpeedSlider.value = log(Float(isoSpeed))
            isoSpeedLabel.text = String(format: "%d", isoSpeed)
        }
    }

    private var _writeTimer: Timer?
    private func _writeConfig() {
        _writeTimer?.invalidate()
        _writeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            guard let me = self else { return }
            do { try me.camera.setConfig(me.currentConfig) } catch {
                os_log("Unable to set camera config: %{public}@", log: App.log, type: .error, String(describing: error))
            }
            do {
                let config = try me.camera.getConfig()
                me._setConfig(config)
            } catch {
                os_log("Unable to get camera config: %{public}@", log: App.log, type: .error, String(describing: error))
            }
        }
    }

    @IBOutlet weak var previewImageView: UIImageView!

    @IBOutlet weak var shutterSpeedSlider: UISlider!
    @IBOutlet weak var apertureSlider: UISlider!
    @IBOutlet weak var isoSpeedSlider: UISlider!

    @IBOutlet weak var shutterSpeedLabel: UILabel!
    @IBOutlet weak var apertureLabel: UILabel!
    @IBOutlet weak var isoSpeedLabel: UILabel!
    @IBOutlet weak var cameraNameLabel: UILabel!

    @IBAction func shutterSpeedChanged(_ sender: UISlider) {
        let newSpeed = ShutterSpeed(seconds: Double(exp(sender.value)))
        currentConfig.shutterSpeed = newSpeed
        shutterSpeedLabel.text = newSpeed.description
        _writeConfig()
    }

    @IBAction func apertureChanged(_ sender: UISlider) {
        let aperture = Double(exp(sender.value))
        currentConfig.aperture = aperture
        apertureLabel.text = String(format: "ƒ/%.1f", aperture)
        _writeConfig()
    }

    @IBAction func isoSpeedChanged(_ sender: UISlider) {
        let iso = Int(exp(sender.value))
        currentConfig.isoSpeed = iso
        isoSpeedLabel.text = String(format: "%d", iso)
        _writeConfig()
    }

}
