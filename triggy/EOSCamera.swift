//
//  EOSCamera.swift
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
import PTP
import CoreImage
import CoreGraphics
import ImageIO
import OrderedDictionary

import os.log

protocol EOSOperationCode {}
extension EOSOperationCode {
    static var EOSCapture: PTPOperationCode { return PTPOperationCode(rawValue: 0x910f)! }
    static var EOSKeepalive: PTPOperationCode { return PTPOperationCode(rawValue: 0x902f)! }
    static var EOSDisconnect: PTPOperationCode { return PTPOperationCode(rawValue: 0x9110)! }
    static var EOSReleaseOn: PTPOperationCode { return PTPOperationCode(rawValue: 0x9128)! }
    static var EOSReleaseOff: PTPOperationCode { return PTPOperationCode(rawValue: 0x9129)! }
    static var EOSGetEvent: PTPOperationCode { return PTPOperationCode(rawValue: 0x9116)! }
    static var EOSSetRemoteMode: PTPOperationCode { return PTPOperationCode(rawValue: 0x9114)! }
    static var EOSSetEventMode: PTPOperationCode { return PTPOperationCode(rawValue: 0x9115)! }
    static var EOSGetThumbEx: PTPOperationCode { return PTPOperationCode(rawValue: 0x910a)! }
    static var EOSSetDevicePropEx: PTPOperationCode { return PTPOperationCode(rawValue: 0x9110)! }

    static var EOSLockUI: PTPOperationCode { return PTPOperationCode(rawValue: 0x9004)! }
    static var EOSUnlockUI: PTPOperationCode { return PTPOperationCode(rawValue: 0x9005)! }

    // args [objectId, 0, 0x80000, 0] arg 2 some sort of size?
    static var EOSDownloadImage: PTPOperationCode { return PTPOperationCode(rawValue: 0x912c)! }

}
extension PTPOperationCode : EOSOperationCode {}

enum EOSProperty: UInt32 {
    case Unknown                 = 0x0000
    case Aperture                = 0xD101
    case ShutterSpeed            = 0xD102
    case ISOSpeed                = 0xD103
    case ExpCompensation         = 0xD104
    case AutoExposureMode        = 0xD105
    case DriveMode               = 0xD106
    case MeteringMode            = 0xD107
    case FocusMode               = 0xD108
    case WhiteBalance            = 0xD109
    case ColorTemperature        = 0xD10A
    case WhiteBalanceAdjustA     = 0xD10B
    case WhiteBalanceAdjustB     = 0xD10C
    case WhiteBalanceXA          = 0xD10D
    case WhiteBalanceXB          = 0xD10E
    case ColorSpace              = 0xD10F
    case PictureStyle            = 0xD110
    case BatteryPower            = 0xD111
    case BatterySelect           = 0xD112
    case CameraTime              = 0xD113
    case Owner                   = 0xD115
    case ModelID                 = 0xD116
    case PTPExtensionVersion     = 0xD119
    case DPOFVersion             = 0xD11A
    case AvailableShots          = 0xD11B
    case CaptureDestination      = 0xD11C
    case BracketMode             = 0xD11D
    case CurrentStorage          = 0xD11E
    case CurrentFolder           = 0xD11F
    case ImageFormat             = 0xD120
    case ImageFormatCF           = 0xD121
    case ImageFormatSD           = 0xD122
    case ImageFormatExtHD        = 0xD123
    case CompressionS            = 0xD130
    case CompressionM1           = 0xD131
    case CompressionM2           = 0xD132
    case CompressionL            = 0xD133
    case PCWhiteBalance1         = 0xD140
    case PCWhiteBalance2         = 0xD141
    case PCWhiteBalance3         = 0xD142
    case PCWhiteBalance4         = 0xD143
    case PCWhiteBalance5         = 0xD144
    case MWhiteBalance           = 0xD145
    case PictureStyleStandard    = 0xD150
    case PictureStylePortrait    = 0xD151
    case PictureStyleLandscape   = 0xD152
    case PictureStyleNeutral     = 0xD153
    case PictureStyleFaithful    = 0xD154
    case PictureStyleMonochrome  = 0xD155
    case PictureStyleUserSet1    = 0xD160
    case PictureStyleUserSet2    = 0xD161
    case PictureStyleUserSet3    = 0xD162
    case PictureStyleParam1      = 0xD170
    case PictureStyleParam2      = 0xD171
    case PictureStyleParam3      = 0xD172
    case FlavorLUTParams         = 0xD17F
    case CustomFunc1             = 0xD180
    case CustomFunc2             = 0xD181
    case CustomFunc3             = 0xD182
    case CustomFunc4             = 0xD183
    case CustomFunc5             = 0xD184
    case CustomFunc6             = 0xD185
    case CustomFunc7             = 0xD186
    case CustomFunc8             = 0xD187
    case CustomFunc9             = 0xD188
    case CustomFunc10            = 0xD189
    case CustomFunc11            = 0xD18A
    case CustomFunc12            = 0xD18B
    case CustomFunc13            = 0xD18C
    case CustomFunc14            = 0xD18D
    case CustomFunc15            = 0xD18E
    case CustomFunc16            = 0xD18F
    case CustomFunc17            = 0xD190
    case CustomFunc18            = 0xD191
    case CustomFunc19            = 0xD192
    case CustomFuncEx            = 0xD1A0
    case MyMenu                  = 0xD1A1
    case MyMenuList              = 0xD1A2
    case WftStatus               = 0xD1A3
    case WftInputTransmission    = 0xD1A4
    case HDDirectoryStructure    = 0xD1A5
    case BatteryInfo             = 0xD1A6
    case AdapterInfo             = 0xD1A7
    case LensStatus              = 0xD1A8
    case QuickReviewTime         = 0xD1A9
    case CardExtension           = 0xD1AA
    case TempStatus              = 0xD1AB
    case ShutterCounter          = 0xD1AC
    case SpecialOption           = 0xD1AD
    case PhotoStudioMode         = 0xD1AE
    case SerialNumber            = 0xD1AF
    case EVFOutputDevice         = 0xD1B0
    case EVFMode                 = 0xD1B1
    case DepthOfFieldPreview     = 0xD1B2
    case EVFSharpness            = 0xD1B3
    case EVFWBMode               = 0xD1B4
    case EVFClickWBCoeffs        = 0xD1B5
    case EVFColorTemp            = 0xD1B6
    case ExposureSimMode         = 0xD1B7
    case EVFRecordStatus         = 0xD1B8
    case LvAfSystem              = 0xD1BA
    case MovSize                 = 0xD1BB
    case LvViewTypeSelect        = 0xD1BC
    case Artist                  = 0xD1D0
    case Copyright               = 0xD1D1
    case BracketValue            = 0xD1D2
    case FocusInfoEx             = 0xD1D3
    case DepthOfField            = 0xD1D4
    case Brightness              = 0xD1D5
    case LensAdjustParams        = 0xD1D6
    case EFComp                  = 0xD1D7
    case LensName                = 0xD1D8
    case AEB                     = 0xD1D9
    case StroboSetting           = 0xD1DA
    case StroboWirelessSetting   = 0xD1DB
    case StroboFiring            = 0xD1DC
    case LensID                  = 0xD1DD
}

extension EOSProperty: PTPArgument {
    var argumentValue: UInt32 { return rawValue }
}

let EOSISOSpeedAuto: UInt32 = 0x00
let EOSShutterSpeedBulb: UInt32 = 0x0c

private let apertureValues: LookupTable<UInt32, Double> = [
    0x0008: 1,
    0x000b: 1.1,
    0x000c: 1.2,
    0x000d: 1.2,
    0x0010: 1.4,
    0x0013: 1.6,
    0x0014: 1.8,
    0x0015: 1.8,
    0x0018: 2,
    0x001b: 2.2,
    0x001c: 2.5,
    0x001d: 2.5,
    0x0020: 2.8,
    0x0023: 3.2,
    0x0024: 3.5,
    0x0025: 3.5,
    0x0028: 4,
    0x002c: 4.5,
    0x002b: 4.5,
    0x002d: 5,
    0x0030: 5.6,
    0x0033: 6.3,
    0x0034: 6.7,
    0x0035: 7.1,
    0x0038: 8,
    0x003b: 9,
    0x003c: 9.5,
    0x003d: 10,
    0x0040: 11,
    0x0043: 13,
    0x0044: 13,
    0x0045: 14,
    0x0048: 16,
    0x004b: 18,
    0x004c: 19,
    0x004d: 20,
    0x0050: 22,
    0x0053: 25,
    0x0054: 27,
    0x0055: 29,
    0x0058: 32,
    0x005b: 36,
    0x005c: 38,
    0x005d: 40,
    0x0060: 45,
    0x0063: 51,
    0x0064: 54,
    0x0065: 57,
    0x0068: 64,
    0x006b: 72,
    0x006c: 76,
    0x006d: 81,
    0x0070: 91
]

private let shutterValues: LookupTable<UInt32, ShutterSpeed> = [
    0x10: "30",
    0x13: "25",
    0x15: "20",
    0x18: "15",
    0x1b: "13",
    0x1d: "10",
    0x20: "8",
    0x23: "6",
    0x25: "5",
    0x28: "4",
    0x2b: "3.2",
    0x2d: "2.5",
    0x30: "2",
    0x33: "1.6",
    0x35: "1.3",
    0x38: "1",
    0x3b: "0.8",
    0x3d: "0.6",
    0x40: "0.5",
    0x43: "0.4",
    0x45: "0.3",
    0x48: "1/4",
    0x4b: "1/5",
    0x4d: "1/6",
    0x50: "1/8",
    0x53: "1/10",
    0x55: "1/13",
    0x58: "1/15",
    0x5b: "1/20",
    0x5d: "1/25",
    0x60: "1/30",
    0x63: "1/40",
    0x65: "1/50",
    0x68: "1/60",
    0x6b: "1/80",
    0x6d: "1/100",
    0x70: "1/125",
    0x73: "1/160",
    0x75: "1/200",
    0x78: "1/250",
    0x7b: "1/320",
    0x7d: "1/400",
    0x80: "1/500",
    0x83: "1/640",
    0x85: "1/800",
    0x88: "1/1000",
    0x8b: "1/1250",
    0x8d: "1/1600",
    0x90: "1/2000",
    0x93: "1/2500",
    0x95: "1/3200",
    0x98: "1/4000",
    0x9b: "1/5000",
    0x9c: "1/6000",
    0x9d: "1/6400",
    0xa0: "1/8000"
]

private let isoValues: LookupTable<UInt32, Int> = [
    0x0028: 6,
    0x0030: 12,
    0x0038: 25,
    0x0040: 50,
    0x0043: 64,
    0x0045: 80,
    0x0048: 100,
    0x004b: 125,
    0x004d: 160,
    0x0050: 200,
    0x0053: 250,
    0x0055: 320,
    0x0058: 400,
    0x005b: 500,
    0x005d: 640,
    0x0060: 800,
    0x0063: 1000,
    0x0065: 1250,
    0x0068: 1600,
    0x006b: 2000,
    0x006d: 2500,
    0x0070: 3200,
    0x0073: 4000,
    0x0075: 5000,
    0x0078: 6400,
    0x007b: 8000,
    0x007d: 10000,
    0x0080: 12800,
    0x0083: 16000,
    0x0085: 20000,
    0x0088: 25600,
    0x008b: 32000,
    0x008d: 40000,
    0x0090: 51200,
    0x0098: 102400
]

enum EOSError: Error {
    case Generic(message: String)
    case ThumbnailError(message: String)
    case EventError(message: String)
}

class EOSCamera: Camera, PTPClientDelegate {

    static let log = OSLog(subsystem: App.id, category: "EOSCamera")
    
    var delegate: CameraDelegate?
    var program: ExposureProgram?
    var mode: ExposureMode = .Camera
    
    let triggerQueue = DispatchQueue(label: "\(App.id).camera-trigger", qos: .userInteractive)
    let programQueue = DispatchQueue(label: "\(App.id).camera-program", qos: .userInitiated)
    let eventQueue = DispatchQueue(label: "\(App.id).camera-event", qos: .userInitiated)
    var eventLockQueue = DispatchQueue(label: "\(App.id).camera-event-lock", qos: .userInitiated)

    let client = PTPClient()
    var host: String?
    
    typealias ConnectCallback = (Error?) -> Void
    typealias StatusCallback = (String) -> Void
    
    internal var callback: ConnectCallback?
    internal var statusCallback: StatusCallback?
    internal var pingTimer: Timer?
    internal var deviceInfo: PTPDeviceInfo?
    
    init() {
        client.delegate = self
    }
    
    deinit {
        pingTimer?.invalidate()
    }
    
    var name: String {
        return deviceInfo?.model ?? "N/A"
    }

    // MARK: - EOS Event handling

    class EventRequest: Equatable {
        public static func ==(lhs: EOSCamera.EventRequest, rhs: EOSCamera.EventRequest) -> Bool {
            return lhs === rhs
        }
        let type: EOSEventType
        let semaphore = DispatchSemaphore(value: 0)
        var event: EOSEvent?
        init(_ type: EOSEventType) { self.type = type }
    }
    var eventSemaphores = [EventRequest]()

    @discardableResult
    func waitForEvent(ofType type: EOSEventType, withTimeout timeout: TimeInterval? = nil) throws -> EOSEvent {

        let request = EventRequest(type)
        eventLockQueue.sync { self.eventSemaphores.append(request) }
        defer {
            eventLockQueue.async {
                guard let idx = self.eventSemaphores.index(of: request) else { return }
                self.eventSemaphores.remove(at: idx)
            }
        }

        if let timeout = timeout {
            let dispatchTimeout = DispatchTime.now() + timeout
            guard request.semaphore.wait(timeout: dispatchTimeout) == .success else {
                throw EOSError.Generic(message: "Timed out waiting for event \(type)")
            }
        } else {
            request.semaphore.wait()
        }

        guard let event = request.event else {
            fatalError("Event missing after semaphore signalled")
        }

        return event
    }

    /// Fetches queued events, triggered by a vendor PTPEvent sent by camera, run on eventQueue
    func fetchEvents() throws {
        guard let data = try client.blockingSend(code: .EOSGetEvent) else {
            throw EOSError.EventError(message: "Unable to get event data")
        }

        let events = try EOSParseEvents(data)
        for event in events {
            switch event.type {
            case .ObjectAddedEx:
                let event = event as! EOSEventObjectAddedEx
                os_log("Event: Object added - %{public}@", log: EOSCamera.log, type: .debug, event.filename)
            case .PropValueChanged:
                let event = event as! EOSEventPropValueChanged
                let propString = (event.property == .Unknown) ? String(format: "%#08x", event.rawProp) : String(describing: event.property)
                let extra = event.extra?.hexValue ?? ""
                os_log("Event: Prop changed - %{public}@ - value %d %@", log: EOSCamera.log, type: .debug, propString, event.value, extra)
                switch event.property {
                case .Aperture:
                    currentAperture = apertureValues[event.value]
                    cameraConfigChanged()
                case .ShutterSpeed:
                    currentShutter = shutterValues[event.value]
                    cameraConfigChanged()
                case .ISOSpeed:
                    currentISOSpeed = isoValues[event.value]
                    cameraConfigChanged()
                case .AvailableShots:
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: CameraNotifications.remainingShots,
                            object: self,
                            userInfo: ["value": event.value]
                        )
                    }
                default:
                    break
                }
            case .CameraReadyStateChanged:
                let event = event as! EOSEventCameraReadyStateChanged
                isReady = event.isReady
                if event.isReady {
                    os_log("Event: Camera ready", log: EOSCamera.log, type: .debug)
                } else {
                    os_log("Event: Camera busy", log: EOSCamera.log, type: .debug)
                }

            case .AvailListChanged:
                let event = event as! EOSEventAvailListChanged
                os_log("Event: AvailList - %@ %#04x - %{public}@", log: EOSCamera.log, type: .debug, String(describing:event.property), event.rawProp, String(describing: event.values))
                switch event.property {
                case .Aperture:
                    var dict = OrderedDictionary<UInt32, Double>()
                    for value in event.values {
                        guard let doubleValue = apertureValues[value]?.value else {
                            os_log("Invalid aperture value in avail list: %d", log: EOSCamera.log, type: .error, value)
                            continue
                        }
                        dict[value] = doubleValue
                    }
                    apertureTable = LookupTable(dict)
                    cameraConfigOptionsChanged()
                case .ISOSpeed:
                    var dict = OrderedDictionary<UInt32, Int>()
                    for value in event.values {
                        guard let intValue = isoValues[value]?.value else {
                            os_log("Invalid ISO value in avail list: %d", log: EOSCamera.log, type: .error, value)
                            continue
                        }
                        dict[value] = intValue
                    }
                    isoTable = LookupTable(dict)
                    cameraConfigOptionsChanged()
                case .ShutterSpeed:
                    var dict = OrderedDictionary<UInt32, ShutterSpeed>()
                    for value in event.values {
                        guard let shutterValue = shutterValues[value]?.value else {
                            os_log("Invalid shutter speed value in avail list: %d", log: EOSCamera.log, type: .error, value)
                            continue
                        }
                        dict[value] = shutterValue
                    }
                    shutterTable = LookupTable(dict)
                    cameraConfigOptionsChanged()
                default:
                    break
                }
            case .Unknown:
                let event = event as! EOSEventUnknown
                os_log("Unknown event: Code %#04x - Payload %d bytes - %@", log: EOSCamera.log, type: .debug, event.code, event.payload.count, event.payload.hexValue)
            default:
                os_log("Unhandled event: %@", log: EOSCamera.log, type: .debug, String(describing: event.type))
            }
        }

        // handle object added events, could be multiple for each shot if capturing in RAW+JPEG
        let addedEvents = events.filter { $0.type == .ObjectAddedEx } as! [EOSEventObjectAddedEx]
        if let addedEvent = addedEvents.first(where: { $0.filename.contains("CR2") }) ?? addedEvents.first {
            runExposureProgram(withEvent: addedEvent)
        }

        // signal any semaphores waiting for a specific event
        eventLockQueue.async {
            for request in self.eventSemaphores {
                guard let event = events.first(where: { $0.type == request.type }) else { continue }
                request.event = event
                request.semaphore.signal()
            }
        }
        
    }

    // MARK: - Camera ready state
    private var _isReady: Bool = false
    var isReady: Bool {
        get { return eventLockQueue.sync { _isReady } }
        set { eventLockQueue.async { self._isReady = newValue } }
    }

    // MARK: - Camera configuration

    var apertureTable: LookupTable<UInt32, Double> = apertureValues
    var shutterTable: LookupTable<UInt32, ShutterSpeed> = shutterValues
    var isoTable: LookupTable<UInt32, Int> = isoValues

    var currentAperture: (key: UInt32, value: Double)?
    var currentShutter: (key: UInt32, value: ShutterSpeed)?
    var currentISOSpeed: (key: UInt32, value: Int)?
    
    func getConfig() throws -> CameraConfig {
        
        var config = CameraConfig()
        
        if let current = currentShutter {
            config.shutterSpeed = current.value
        }
        
        if let current = currentAperture {
            config.aperture = current.value
        }
        
        if let current = currentISOSpeed {
            config.isoSpeed = current.value
        }
        
        return config
    }

    func getConfigOptions() throws -> CameraConfigOptions {
        return CameraConfigOptions(
            aperture: Array(apertureTable.dict.orderedValues),
            shutterSpeed: Array(shutterTable.dict.orderedValues),
            isoSpeed: Array(isoTable.dict.orderedValues)
        )
    }

    func setConfig(_ newConfig: CameraConfig) throws {
        if let shutterSpeed = newConfig.shutterSpeed {
            let newValue = shutterTable.nearest(toValue: shutterSpeed)
            if currentShutter == nil || currentShutter! != newValue {
                os_log("Writing new shutter value: %#02x (%{public}@)", log: EOSCamera.log, type: .info, newValue.key, newValue.value.description)
                try writeProperty(property: .ShutterSpeed, value: newValue.key)
                currentShutter = newValue
            }
        }
        if let aperture = newConfig.aperture {
            let newValue = apertureTable.nearest(toValue: aperture)
            if currentAperture == nil || currentAperture! != newValue {
                os_log("Writing new aperture value: %#02x (%.2fs)", log: EOSCamera.log, type: .info, newValue.key, newValue.value)
                try writeProperty(property: .Aperture, value: newValue.key)
                currentAperture = newValue
            }
        }
        if let isoSpeed = newConfig.isoSpeed {
            var newValue = isoTable.nearest(toValue: isoSpeed)
            if isoSpeed == 0 { newValue = (EOSISOSpeedAuto, 0) }
            if currentISOSpeed == nil || currentISOSpeed! != newValue {
                os_log("Writing new ISO speed value: %#02x (%d)", log: EOSCamera.log, type: .info, newValue.key, newValue.value)
                try writeProperty(property: .ISOSpeed, value: newValue.key)
                currentISOSpeed = newValue
            }
        }
    }

    // TODO: it would be better to run these 2 on a backgroubd queue and only post the notificaiton on main

    internal var configOptionsChangeTimer: Timer?
    internal func cameraConfigOptionsChanged() {
        DispatchQueue.main.async {
            self.configOptionsChangeTimer?.invalidate()
            self.configOptionsChangeTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { (_) in
                do {
                    let configOptions = try self.getConfigOptions()
                    NotificationCenter.default.post(
                        name: CameraNotifications.configOptionsChanged,
                        object: self,
                        userInfo: ["configOptions": configOptions]
                    )
                } catch {
                    os_log("Unable to get config options after change, error: %{public}@", log: EOSCamera.log, type: .error,
                           String(describing: error))
                }

            }
        }

    }

    internal var configChangeTimer: Timer?
    internal func cameraConfigChanged() {
        DispatchQueue.main.async {
            self.configChangeTimer?.invalidate()
            self.configChangeTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { (_) in
                do {
                    let config = try self.getConfig()
                    NotificationCenter.default.post(
                        name: CameraNotifications.configChanged,
                        object: self,
                        userInfo: ["config": config]
                    )
                } catch {
                    os_log("Unable to get config after change, error: %{public}@", log: EOSCamera.log, type: .error,
                           String(describing: error))
                }

            }
        }
    }

    func writeProperty(property: EOSProperty, value: UInt32) throws {
        var data = Data()
        data.append(littleEndian: UInt32(0x0c))
        data.append(littleEndian: property.rawValue)
        data.append(littleEndian: value)
        try client.blockingSend(code: .EOSSetDevicePropEx, data: data)
    }

    // MARK: - Camera interface

    private func _triggerShutter() throws {
        var scope = Activity("Trigger shutter").enter(); defer { scope.leave() }
        os_log("Triggering shutter", log: EOSCamera.log, type: .debug)
        // TODO: wait for camera ready
//        if !isReady {
//            try waitForEvent(ofType: .CameraReadyStateChanged, withTimeout: timeout)
//        }
        switch mode {
        case .Camera:
            try client.blockingSend(code: .EOSCapture)
        case .Bulb:
//            if currentShutterValue != EOSShutterSpeed.bulb {
//                os_log("Shutter speed wasn't bulb, fixing that...", log: EOSCamera.log, type: .info)
//                try writeProperty(property: .ShutterSpeed, value: EOSShutterSpeed.bulb)
//                var event: EOSEventPropValueChanged
//                repeat {
//                    event = try waitForEvent(ofType: .PropValueChanged, withTimeout: 1.0) as! EOSEventPropValueChanged
//                } while event.property != .ShutterSpeed
//            }
            let exposureTime:useconds_t = 2_000_000 //UInt32(self.exposureTime * 1e6)
            try self.client.blockingSend(code: .EOSReleaseOn, arguments: [UInt32(3), UInt32(0)])
            usleep(exposureTime)
            try self.client.blockingSend(code: .EOSReleaseOff, arguments: [UInt32(3)])
        }
    }

    func triggerShutter(_ callback: @escaping (Error?) -> Void) {
        triggerQueue.async {
            do {
                try self._triggerShutter() // TODO: use capture interval for timeout
                DispatchQueue.main.async { callback(nil) }
            } catch {
                DispatchQueue.main.async { callback(error) }
            }
        }
    }

    func captureImage(_ callback: @escaping (CIImage?, Error?) -> Void) {
        programQueue.async {
            var scope = Activity("Capture image").enter(); defer { scope.leave() }
            do {
                let config = try self.getConfig()
                guard let shutterSpeed = config.shutterSpeed else {
                    throw EOSError.Generic(message: "Unable to determine shutter speed.")
                }
                try self._triggerShutter()
                let event = try self.waitForEvent(ofType: .ObjectAddedEx, withTimeout: shutterSpeed.seconds + 5.0) as! EOSEventObjectAddedEx
                os_log("Captured %{public}@", log: EOSCamera.log, type: .info, event.filename)
                guard let data = try self.client.blockingSend(code: .GetThumb, arguments: [event.objectId]) else {
                    throw EOSError.Generic(message: "Unable to fetch object")
                }
                os_log("Downloaded %d bytes", log: EOSCamera.log, type: .info, data.count)

                guard let image = CIImage(data: data) else {
                    throw EOSError.Generic(message: "Unable to decode image")
                }

                os_log("Decoded image, size: %.0fx%.0f", log: EOSCamera.log, type: .info, image.extent.width, image.extent.height)

                DispatchQueue.main.async {
                    callback(image, nil)
                }

            } catch {
                os_log("Could not capture image, error: %{public}@", log: EOSCamera.log, type: .error, String(describing: error))
                callback(nil, error)
            }
        }
        
    }

    private func _connect() throws {
        client.hostname = "Triggy"
        client.guid = Data(hexEncoded: "54726967677920697320677265617421")
        os_log("Connecting to %{public}@", log: EOSCamera.log, type: .info, host!)
        do {
            try client.blockingConnect(to: host!)
        } catch PTPError.InvalidPacket(let message, let code) {
            if code == .InitFail {
                // Support version 1.0 GUIDs so people don't have to create new configurations for 2.0
                guard let uuid = UIDevice.current.identifierForVendor else {
                    throw EOSError.Generic(message: "Unable to determine device UUID.")
                }
                os_log("Connect failed with triggy constants, retrying with UUID: %{private}@", log: EOSCamera.log, type: .info, uuid.uuidString)
                var guid = Data()
                for item in Mirror(reflecting: uuid.uuid).children {
                    guid.append(item.value as! UInt8)
                }
                client.hostname = UIDevice.current.name
                client.guid = guid
                try client.blockingConnect(to: host!)
            } else {
                throw PTPError.InvalidPacket(message: message, type: code) // TODO: proper rethrow?
            }
        }
        try self.client.blockingSend(code: .EOSSetRemoteMode, arguments: [0x15])
        try self.client.blockingSend(code: .EOSSetEventMode, arguments: [0x02])
        guard let data = try self.client.blockingSend(code: .GetDeviceInfo) else {
            throw EOSError.Generic(message: "Unable to get device info")
        }
        let deviceInfo = try PTPDeviceInfo(data)
        self.deviceInfo = deviceInfo
        os_log("Connected! %{public}@ (serial#%@)", log: EOSCamera.log, type: .info,
               deviceInfo.description, deviceInfo.serialNumber)
    }

    func connect(to: String, status: @escaping StatusCallback, completion: @escaping ConnectCallback) {
        host = to
        statusCallback = status
        triggerQueue.async {
            do {
                try self._connect()
                DispatchQueue.main.async { completion(nil) }
                self.startPing()
            } catch {
                DispatchQueue.main.async { completion(error) }
            }
        }
    }
    
    func disconnect() {
        pingTimer?.invalidate()
        client.disconnect()
    }
    
    func setup(_ callback: @escaping (Error?) -> Void) {
        triggerQueue.async { [unowned self] in
            do {
                if let program = self.program {
                    try program.configure(withCamera: self)
                }
                DispatchQueue.main.async { callback(nil) }
            } catch {
                DispatchQueue.main.async { callback(error) }
            }
            
        }
    }

    func runExposureProgram(withEvent event: EOSEventObjectAddedEx) {
        guard let program = program else { return }

        // TODO: add some sort of isRunning check here, don't want to run program when configuring camera

        programQueue.async {
            var scope = Activity("Run exposure program").enter(); defer { scope.leave() }
            do {
                os_log("Downloading thumbnail for %{public}@", log: EOSCamera.log, type: .info, event.filename)
                guard let imageData = try self.client.blockingSend(code: .GetThumb, arguments: [event.objectId]) else {
                    throw EOSError.ThumbnailError(message: "Unable to fetch thumbnail data")
                }
                
                guard let image = CIImage(data: imageData) else {
                    throw EOSError.ThumbnailError(message: "Got invalid thumbnail data from camera")
                }
                os_log("Thumbnail size: %fx%f", log: EOSCamera.log, type: .info, image.extent.width, image.extent.height)

                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: CameraNotifications.thumbnail,
                        object: self,
                        userInfo: ["image": image]
                    )
                }

                os_log("Running program: %{public}@", log: EOSCamera.log, type: .info, program.name)
                try program.run(withCamera: self, lastCapture: image)

            } catch {
                os_log("Failed to run program, error: %{public}@", log: EOSCamera.log, type: .error,
                       String(describing: error))
            }
        }
    }


    func startPing() {
        // TODO: better keepalive that can not add a delay to bulb shutter commands
        pingTimer = Timer(timeInterval: 10, repeats: true) { [weak self] _ in
            guard let client = self?.client else { return }
            client.send(code: .EOSKeepalive) { (_, error) in
                if let error = error {
                    os_log("WARNING: Keepalive failed - %@", log: EOSCamera.log, type: .error, String(describing: error))
                }
            }
        }
        RunLoop.main.add(pingTimer!, forMode: .commonModes)
    }
    
    // MARK: - PTPClientDelegate
    
    func client(_ client: PTPClient, receivedEvent event: PTPEvent) {
        guard event.type == .Vendor && event.code == 0xc101 else {
            os_log("Unhandled camera event: %{public}@", log: EOSCamera.log, type: .info, event.description)
            return
        }
        eventQueue.async {
            do {
                try self.fetchEvents()
            } catch {
                os_log("Error fetching events: %{public}@", log: EOSCamera.log, type: .error, error.localizedDescription)
            }
        }
    }
    
    func clientWaitingForCamera(_ client: PTPClient) {
        statusCallback?("Waiting for camera")
    }
    
    func clientDisconnected(_ client: PTPClient, withError error: Error?) {
        delegate?.cameraDisconnected(self, withError: error)
        pingTimer?.invalidate()
    }
    
}

