//
//  EOSEvent.swift
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

enum EOSEventType: UInt32 {
    case Unknown                 = 0x0000
    case RequestGetEvent         = 0xC101
    case ObjectAddedEx           = 0xC181
    case ObjectRemoved           = 0xC182
    case RequestGetObjectInfoEx  = 0xC183
    case StorageStatusChanged    = 0xC184
    case StorageInfoChanged      = 0xC185
    case RequestObjectTransfer   = 0xC186
    case ObjectInfoChangedEx     = 0xC187
    case ObjectContentChanged    = 0xC188
    case PropValueChanged        = 0xC189
    case AvailListChanged        = 0xC18A
    case CameraStatusChanged     = 0xC18B
    case WillSoonShutdown        = 0xC18D
    case ShutdownTimerUpdated    = 0xC18E
    case RequestCancelTransfer   = 0xC18F
    case RequestObjectTransferDT = 0xC190
    case RequestCancelTransferDT = 0xC191
    case StoreAdded              = 0xC192
    case StoreRemoved            = 0xC193
    case BulbExposureTime        = 0xC194
    case RecordingTime           = 0xC195
    case RequestObjectTransferTS = 0xC1A2
    case AfResult                = 0xC1A3
    case CameraReadyStateChanged = 0xC1F6
}

protocol EOSEvent {
    var type: EOSEventType { get }
}

struct EOSEventUnknown: EOSEvent {
    let type = EOSEventType.Unknown
    let code: UInt32
    let payload: Data
}

struct EOSEventGeneric: EOSEvent {
    let type: EOSEventType
}

struct EOSEventObjectAddedEx: EOSEvent {
    let type = EOSEventType.ObjectAddedEx
    let storageId: UInt32
    let objectId: UInt32
    let parentObjectId: UInt32
    let format: UInt16
    let size: UInt32
    let filename: String
}

struct EOSEventPropValueChanged: EOSEvent {
    let type = EOSEventType.PropValueChanged
    let property: EOSProperty
    let value: UInt32
    let rawProp: UInt32
    let extra: Data?
}

struct EOSEventAvailListChanged: EOSEvent {
    let type = EOSEventType.AvailListChanged
    let property: EOSProperty
    let rawProp: UInt32
    let values: [UInt32]
}

struct EOSEventCameraReadyStateChanged: EOSEvent {
    let type = EOSEventType.CameraReadyStateChanged
    let isReady: Bool
}


func EOSParseEvents(_ data: Data) throws -> [EOSEvent] {
    var b = BinaryData(data)
    var rv = [EOSEvent]()
    
    while b.position < b.data.count {
        let startPos = b.position
        let len = try b.read() as UInt32
        let typeVal = try b.read() as UInt32
        
        if typeVal == 0 { break }
        
        let type = EOSEventType(rawValue: typeVal) ?? .Unknown
        let event: EOSEvent
        
        switch type {
        case .ObjectAddedEx:
            let objectId = try b.read() as UInt32
            let storageId = try b.read() as UInt32
            let format = try b.read() as UInt16
            b.position += 10
            let size = try b.read() as UInt32
            let parentId = try b.read() as UInt32
            b.position += 4
            let filename = try b.read(encoding: .utf8).replacingOccurrences(of: "\0", with: "")
            event = EOSEventObjectAddedEx(storageId: storageId, objectId: objectId, parentObjectId: parentId, format: format, size: size, filename: filename)
        case .PropValueChanged:
            let propertyValue: UInt32 = try b.read()
            let property = EOSProperty(rawValue: propertyValue) ?? .Unknown
            let value = try b.read() as UInt32
            var extra: Data? = nil
            if startPos + Int(len) > startPos + b.position {
                extra = data.subdata(in: startPos+b.position..<startPos+Int(len))
            }
            event = EOSEventPropValueChanged(property: property, value: value, rawProp: propertyValue, extra: extra)
        case .AvailListChanged:
            let code: UInt32 = try b.read()
            let valueType: UInt32 = try b.read()
            var values = [UInt32]()
            if valueType == 3 {
                // UInt32 array?
                let count = Int(try b.read() as UInt32)
                while values.count < count {
                    values.append(try b.read())
                }
            }
            let property = EOSProperty(rawValue: code) ?? .Unknown
            event = EOSEventAvailListChanged(property: property, rawProp: code, values: values)
        case .CameraReadyStateChanged:
            let isReady: UInt32 = try b.read()
            event = EOSEventCameraReadyStateChanged(isReady: isReady == 1)
        default:
            event = EOSEventUnknown(code: typeVal, payload: data.subdata(in: startPos+8..<startPos+Int(len)))
            
        }
        rv.append(event)
        b.position = startPos + Int(len)
    }
    assert(b.position == data.count, "Didn't consume all event data")
    return rv
}

