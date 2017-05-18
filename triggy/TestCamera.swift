//
//  TestCamera.swift
//  triggy
//
//  Created by Johan Nordberg on 08/03/2017.
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
import UIKit
import os.log

class TestCamera: Camera {

    var delegate: CameraDelegate?
    var program: ExposureProgram?
    var mode = ExposureMode.Camera

    let name: String = "Test Camera X1240"

    static let log = OSLog(subsystem: App.id, category: "TestCamera")

    func setup(_ callback: @escaping (Error?) -> Void) {
        DispatchQueue.main.async { callback(nil) }
    }
    
    func triggerShutter(_ callback: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            os_log("Fake trigger shutter", log: TestCamera.log, type: .error)
            usleep(1000)
            DispatchQueue.main.async {
                callback(nil)
            }
            if let program = self.program {
                guard let testImage = #imageLiteral(resourceName: "test_pattern.png").cgImage else { fatalError("Can't load test image") }
                let image = CIImage(cgImage: testImage)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: CameraNotifications.thumbnail, object: self, userInfo: ["image": image])
                }
                do {
                    try program.run(withCamera: self, lastCapture: image)
                } catch {
                    os_log("Failed to run program: %{public}@", log: TestCamera.log, type: .error, String(describing: error))
                }
            }

        }
    }

    func captureImage(_ callback: @escaping (CIImage?, Error?) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            guard let testImage = #imageLiteral(resourceName: "test_pattern.png").cgImage else { fatalError("Can't load test image") }
            let image = CIImage(cgImage: testImage)
            DispatchQueue.main.async {
                callback(image, nil)
            }
        }
    }

    private var config = CameraConfig(aperture: 2.3, shutterSpeed: "1/200", isoSpeed: 100)
    private let configOptions = CameraConfigOptions(
        aperture: [1.2, 1.3, 1.5, 5.5, 7.7, 22, 33],
        shutterSpeed: ["1/200", "1/20", "1/2", "1", "2", "22", "30"],
        isoSpeed: [100, 200, 300, 400, 500]
    )

    func setConfig(_ newConfig: CameraConfig) throws {
        config = newConfig
    }
    
    func getConfig() throws -> CameraConfig {
        return config
    }

    func getConfigOptions() throws -> CameraConfigOptions {
        return configOptions
    }

    func disconnect() {
        print("Test camera disconnected")
        delegate?.cameraDisconnected(self, withError: nil)
    }
}


