//
//  PTPDevice.swift
//  triggy
//
//  Created by Johan Nordberg on 2016-12-27.
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

import Foundation


func readPTPString(_ b: inout BinaryData) throws -> String {
    let chars: [UInt16] = try b.read(prefixedArray: UInt8.self)
    let data = chars.withUnsafeBufferPointer { Data(buffer: $0) }
    guard let rv = String(data: data, encoding: .utf16LittleEndian) else {
        throw BinaryData.Error.InvalidString
    }
    return rv
}



public struct PTPDeviceInfo: CustomStringConvertible {
    
    public let standardVersion: UInt16
    public let vendorExtensionID: UInt32
    public let vendorExtensionVersion: UInt16
    public let vendorExtensionDesc: String
    public let functionalMode: UInt16
    public let operationsSupported: [PTPOperationCode]
    public let eventsSupported: [UInt16]
    public let devicePropertiesSupported: [UInt16]
    public let captureFormats: [PTPObjectFormat]
    public let imageFormats: [PTPObjectFormat]
    public let manufacturer: String
    public let model: String
    public let deviceVersion: String
    public let serialNumber: String
    
    public init(_ data: Data) throws {
        var b = BinaryData(data)
        
        standardVersion = try b.read()
        vendorExtensionID = try b.read()
        vendorExtensionVersion = try b.read()
        vendorExtensionDesc = try readPTPString(&b)
        functionalMode = try b.read()
        
        let ops: [UInt16] = try b.read(prefixedArray: UInt32.self)
        operationsSupported = ops.map { PTPOperationCode(integerLiteral: $0) }
        
        eventsSupported = try b.read(prefixedArray: UInt32.self)
        devicePropertiesSupported = try b.read(prefixedArray: UInt32.self)
        
        let cfs: [UInt16] = try b.read(prefixedArray: UInt32.self)
        captureFormats = cfs.map { PTPObjectFormat(rawValue: $0) ?? .Unknown }
        
        let ifs: [UInt16] = try b.read(prefixedArray: UInt32.self)
        imageFormats = ifs.map { PTPObjectFormat(rawValue: $0) ?? .Unknown }
        
        manufacturer = try readPTPString(&b)
        model = try readPTPString(&b)
        deviceVersion = try readPTPString(&b)
        serialNumber = try readPTPString(&b)
    }
    
    public var description: String {
        return "\(manufacturer) \(model) \(deviceVersion)"
    }

    public var info: Dictionary<String, Any> {
        return [
            "version": Int(standardVersion),
            "model": model,
            "manufacturer": manufacturer,
            "device": deviceVersion,
            "vendor_ext": [
                "id": Int(vendorExtensionID),
                "version": Int(vendorExtensionVersion),
                "desc": vendorExtensionDesc
            ],
            "eventsSupported": eventsSupported.map { Int($0) },
            "operationsSupported": operationsSupported.map { Int($0.rawValue) },
            "devicePropertiesSupported": devicePropertiesSupported.map { Int($0) }
        ]
    }
}

public enum PTPDataType: UInt16 {
    case Undefined     = 0x0000
    case Int8          = 0x0001
    case UInt8         = 0x0002
    case Int16         = 0x0003
    case UInt16        = 0x0004
    case Int32         = 0x0005
    case UInt32        = 0x0006
    case Int64         = 0x0007
    case UInt64        = 0x0008
    case Int128        = 0x0009
    case UInt128       = 0x000A
    case Int8Array     = 0x4001
    case UInt8Array    = 0x4002
    case Int16Array    = 0x4003
    case UInt16Array   = 0x4004
    case Int32Array    = 0x4005
    case UInt32Array   = 0x4006
    case Int64Array    = 0x4007
    case UInt64Array   = 0x4008
    case Int128Array   = 0x4009
    case UInt128Array  = 0x400A
    case String        = 0xFFFF
}

public struct PTPDevicePropDesc {
    
    public enum Error: Swift.Error {
        case UnsupportedType(type: PTPDataType)
    }
    
    public enum Form: UInt8 {
        case None  = 0x00
        case Range = 0x01
        case Enum  = 0x02
    }
    
    public let code: PTPDeviceProperty
    public let type: PTPDataType
    public let isWritable: Bool
    
    public let factoryDefault: Any
    public let value: Any
    
    public let formFlag: Form
    public let form: Any?
    
    public init(_ data: Data) throws {
        var b = BinaryData(data)

        code = PTPDeviceProperty(rawValue: try b.read()) ?? .Unknown
        type = PTPDataType(rawValue: try b.read()) ?? .Undefined
        
        let getSet: UInt8 = try b.read()
        isWritable = (getSet == 0x01)
        
        switch type {
        case .UInt8:
            factoryDefault = try b.read() as UInt8
            value = try b.read() as UInt8
        case .UInt16:
            factoryDefault = try b.read() as UInt16
            value = try b.read() as UInt16
        case .UInt32:
            factoryDefault = try b.read() as UInt32
            value = try b.read() as UInt32
        case .UInt16Array:
            let d: [UInt16] = try b.read(prefixedArray: UInt32.self)
            let v: [UInt16] = try b.read(prefixedArray: UInt32.self)
            factoryDefault = d as Any
            value = v as Any
        case .String:
            factoryDefault = try readPTPString(&b)
            value = try readPTPString(&b)
        default:
            throw Error.UnsupportedType(type: type)
        }
        
        let ff: UInt8 = try b.read()
        formFlag = Form(rawValue: ff) ?? .None
        
        switch formFlag {
        case .Enum:
            switch type {
            case .UInt8:
                form = try b.read(prefixedArray: UInt16.self) as [UInt8]
            case .UInt16:
                form = try b.read(prefixedArray: UInt16.self) as [UInt16]
            case .UInt32:
                form = try b.read(prefixedArray: UInt16.self) as [UInt32]
            default:
                throw Error.UnsupportedType(type: type)
            }
        case .Range:
            print("UNSUPPORTED RANGE", type, data.hexValue)
            form = nil
        case .None:
            form = nil
        }
    }
    
}



