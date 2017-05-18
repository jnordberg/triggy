//
//  Camera.swift
//  triggy
//
//  Created by Johan Nordberg on 2017-01-02.
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
import PTP
import CoreImage

enum ExposureMode {
    case Camera
    case Bulb
}

enum CameraNotifications {

    /// userInfo: ["config": CameraConfig]
    static let configChanged = Notification.Name(rawValue: "CameraConfigChanged")

    /// userInfo: ["configOptions": CameraConfigOptions]
    static let configOptionsChanged = Notification.Name(rawValue: "CameraConfigOptionsChanged")

    /// userInfo: ["value": UInt32]
    static let remainingShots = Notification.Name(rawValue: "CameraRemainingShots")

    /// userInfo: ["image": CIImage]
    static let thumbnail = Notification.Name(rawValue: "CameraThumbnail")
    
}

protocol CameraDelegate {
    func cameraDisconnected(_ camera: Camera, withError error: Error?)
}

struct CameraConfig {
    var aperture: Double?
    var shutterSpeed: ShutterSpeed?
    var isoSpeed: Int?
}

struct CameraConfigOptions {
    let aperture: [Double]
    let shutterSpeed: [ShutterSpeed]
    let isoSpeed: [Int]
}

protocol Camera {
    
    var name: String { get }
    
    var delegate: CameraDelegate? { get set }
    var program: ExposureProgram? { get set }
    var mode: ExposureMode { get set }
    
    func setup(_ callback: @escaping (Error?) -> Void)
    func triggerShutter(_ callback: @escaping (Error?) -> Void)
    func captureImage(_ callback: @escaping (CIImage?, Error?) -> Void)
    func disconnect()
    
    // blocking methods that should be run on a background queue
    func getConfig() throws -> CameraConfig
    func setConfig(_ newConfig: CameraConfig) throws
    func getConfigOptions() throws -> CameraConfigOptions
    
}
