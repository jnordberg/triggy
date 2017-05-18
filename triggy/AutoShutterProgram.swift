//
//  AutoShutterProgram.swift
//  triggy
//
//  Created by Johan Nordberg on 07/03/2017.
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
import CoreImage
import NotificationCenter
import UIKit

import os.log

class AutoShutterProgram: NSObject, ExposureProgram {
    
    /*
     
     References:
        
     https://www.eecs.tu-berlin.de/fileadmin/fg144/Courses/10WS/pdci/talks/camera_algorithms.pdf
     http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.143.9945&rep=rep1&type=pdf
     
     */
    
    static let notification = Notification.Name(rawValue: "AutoExposureProgramUpdated")
    
    static let log = OSLog(subsystem: App.id, category: "AutoExposure")
    
    enum Error: Swift.Error {
        case General(message: String)
    }

    let name = "Auto Shutter"

    let ctx = CIContext(options: [
        kCIContextCacheIntermediates: true,
        kCIContextUseSoftwareRenderer: false
    ])
    
    // TODO: custom exposure filter that takes blown highlights into account
    let avgFilter = CIFilter(name: "CIAreaAverage")!
    
    /// Camera aperture ƒ/n, if unset will be determined from camera if possible.
    var aperture: Double? {
        get { return UserDefaults.standard.value(forKey: "AutoShutterProgramAperture") as? Double }
        set { UserDefaults.standard.set(newValue, forKey: "AutoShutterProgramAperture") }
    }
    
    /// Target luminance
    var targetLuminance: Double {
        get { return UserDefaults.standard.value(forKey: "AutoShutterProgramTarget") as? Double ?? 0.46 }
        set { UserDefaults.standard.setValue(newValue, forKey: "AutoShutterProgramTarget") }
    }
    // http://photo.stackexchange.com/questions/1048/what-is-the-18-gray-tone-and-how-do-i-make-a-18-gray-card-in-photoshop

    /// Shutter speed smoothing factor (low-pass ƒ)
    var shutterSpeedSmoothing: Double {
        get { return UserDefaults.standard.value(forKey: "AutoShutterProgramSmoothing") as? Double ?? 0.35 }
        set { UserDefaults.standard.setValue(newValue, forKey: "AutoShutterProgramSmoothing") }
    }

    /// Maximum shutter speed to use
    var maximumShutterSpeed: ShutterSpeed {
        get {
            if let val = UserDefaults.standard.value(forKey: "AutoShutterProgramMaxShutter") as? String {
                return ShutterSpeed(stringLiteral: val)
            }
            return 8
        }
        set { UserDefaults.standard.setValue(newValue.description, forKey: "AutoShutterProgramMaxShutter") }
    }

    internal var lastTargetT: Double?
    
    func configure(withCamera camera: Camera) throws {
        lastTargetT = nil
        var config = try camera.getConfig()

        guard !(config.aperture == nil && aperture == nil) else {
            throw Error.General(message: "Unable to determine camera aperture. Please set manually")
        }
        guard let shutterSpeed = config.shutterSpeed else {
            throw Error.General(message: "Unable to determine current shutter speed")
        }
        if shutterSpeed > maximumShutterSpeed {
            config.shutterSpeed = maximumShutterSpeed
            try camera.setConfig(config)
        }
    }
    
    func run(withCamera camera: Camera, lastCapture image: CIImage) throws {
        
        // TODO: crop away black bars based on aspect ratio, this will fail if image is not the 120xsomething we usually get
        let extent = CIVector(cgRect: image.extent.insetBy(dx: 0, dy: 10))

        os_log("Processing capture thumbnail of %.0fx%.0f (using: %{public}@)", log: AutoShutterProgram.log, type: .info,
               image.extent.width, image.extent.height, String(describing: extent)
        )
        
        avgFilter.setValue(extent, forKey: kCIInputExtentKey)
        avgFilter.setValue(image, forKey: kCIInputImageKey)
        
        guard let outputImage = avgFilter.outputImage else {
            throw Error.General(message: "Unable to get outputImage from filter")
        }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        bitmap.withUnsafeMutableBytes {
            // kCIFormatRGBAf should be available but is not, dunno what gives
            ctx.render(outputImage, toBitmap: $0.baseAddress!, rowBytes: 16, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: kCIFormatRGBA8, colorSpace: nil)
        }
        let lum: Double = 0.2126 * (Double(bitmap[0]) / 255) + 0.7152 * (Double(bitmap[1]) / 255) + 0.0722 * (Double(bitmap[0]) / 255)
        
        // I've seen this happen on OSX with wonky drivers, dunno if it could happen on iOS
        guard !lum.isNaN else {
            throw Error.General(message: "Got NaN when computing luminance from image")
        }
        
        let correction = log2(lum) - log2(targetLuminance)
        
        var config = try camera.getConfig()
        
        guard let F = config.aperture ?? aperture else {
            throw Error.General(message: "Unable to determine aperture")
        }
        
        guard let T = config.shutterSpeed?.seconds else {
            throw Error.General(message: "Unable to determine current shutter speed")
        }
        
        let F² = pow(F, 2)
        let EV = log2(F²/T)
        
        let targetEV = EV + correction
        
        var targetT = F² / pow(2, targetEV)
        
        os_log("EV: %.3f targetEV: %.3f T: %.5f targetT: %.5f lum: %.3f", log: AutoShutterProgram.log, type: .info,
               EV, targetEV, T, targetT, lum)
        
        var userInfo: Dictionary<String, Any> = [
            "L": lum,
            "EV": EV,
            "EVᵗ": targetEV
        ]

        if targetT > maximumShutterSpeed.seconds {
            targetT = maximumShutterSpeed.seconds
        }
        if let lastTargetT = lastTargetT {
            let ƒ: Double = shutterSpeedSmoothing
            targetT = targetT * ƒ + lastTargetT * (1 - ƒ)
        }

        config.shutterSpeed = ShutterSpeed(seconds: targetT)
        userInfo["T"] = config.shutterSpeed!

        lastTargetT = targetT

        try camera.setConfig(config)

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: AutoShutterProgram.notification, object: self, userInfo: userInfo)
        }
    }

    // MARK: - Configuration view

    @IBOutlet weak var targetExposureValue: UILabel!
    @IBOutlet weak var targetExposureSlider: UISlider!
    @IBOutlet weak var smoothingSlider: UISlider!
    @IBOutlet weak var smoothingValue: UILabel!
    @IBOutlet weak var maximumSlider: UISlider!
    @IBOutlet weak var maximumValue: UILabel!
    @IBOutlet weak var apertureInput: UITextField!

    var configurationView: UIView {
        let view = UINib(nibName: "AutoShutterProgramView", bundle: nil).instantiate(withOwner: nil, options: [
            UINibExternalObjects: ["autoShutterProgram": self]
        ]).first as! UIView

        targetExposureValue.text = String(format: "%.0f%%", targetLuminance * 100)
        targetExposureValue.font = targetExposureValue.font.monospacedDigitFont
        targetExposureSlider.value = Float(targetLuminance)

        smoothingValue.text = String(format: "%.2f", shutterSpeedSmoothing)
        smoothingValue.font = smoothingValue.font.monospacedDigitFont
        smoothingSlider.value = Float(shutterSpeedSmoothing)

        maximumSlider.value = Darwin.log(Float(maximumShutterSpeed.seconds))
        maximumValue.text = maximumShutterSpeed.description
        maximumValue.font = maximumValue.font.monospacedDigitFont

        if let aperture = aperture {
            apertureInput.text = String(format: "%.1f", aperture)
        }

        return view
    }

    func configurationViewWillAppear(withCamera camera: Camera) {
        do {
            let options = try camera.getConfigOptions()
            if let max = options.shutterSpeed.max() {
                maximumSlider.maximumValue = Darwin.log(Float(max.seconds))
            }
            if let min = options.shutterSpeed.min() {
                maximumSlider.minimumValue = Darwin.log(Float(min.seconds))
            }
        } catch {
            os_log("Unable to get camera config options: %{public}@", log: AutoShutterProgram.log, type: .error,
                   String(describing: error))
        }
    }

    func configurationViewWillDisappear() {

    }
    
    @IBAction func targetExposureChange(_ sender: UISlider) {
        targetLuminance = Double(sender.value)
        targetExposureValue.text = String(format: "%.0f%%", targetLuminance * 100)
    }

    @IBAction func smoothingChange(_ sender: UISlider) {
        shutterSpeedSmoothing = Double(sender.value)
        smoothingValue.text = String(format: "%.2f", shutterSpeedSmoothing)
    }

    @IBAction func maximumChange(_ sender: UISlider) {
        maximumShutterSpeed = ShutterSpeed(seconds: Double(exp(sender.value)))
        maximumValue.text = maximumShutterSpeed.description
    }

    @IBAction func apertureChange(_ sender: UITextField) {
        if let text = sender.text, let newAperture = Double(text.replacingOccurrences(of: ",", with: ".")) {
            aperture = newAperture
        } else {
            aperture = nil
            sender.text = nil
        }
    }

}

