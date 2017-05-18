//
//  PTPEvent.swift
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

public enum PTPEventType: UInt16 {
    case Reserved                = 0x0000
    case Vendor                  = 0x0001
    case Invalid                 = 0x0002
    case Undefined               = 0x4000
    case CancelTransaction       = 0x4001
    case ObjectAdded             = 0x4002
    case ObjectRemoved           = 0x4003
    case StoreAdded              = 0x4004
    case StoreRemoved            = 0x4005
    case DevicePropChanged       = 0x4006
    case ObjectInfoChanged       = 0x4007
    case DeviceInfoChanged       = 0x4008
    case RequestObjectTransfer   = 0x4009
    case StoreFull               = 0x400A
    case DeviceReset             = 0x400B
    case StorageInfoChanged      = 0x400C
    case CaptureComplete         = 0x400D
    case UnreportedStatus        = 0x400E
}

public struct PTPEvent: CustomStringConvertible {

    public enum Error: Swift.Error {
        case SizeMismatch(message: String)
        case InvalidType(message: String)
    }

    public let type: PTPEventType
    public let code: UInt16
    public let sessionID: UInt32
    public let transactionID: UInt32
    public let parameters: [UInt32]

    init(_ data: Data) throws {
        var b = BinaryData(data)

        let len: UInt32 = try b.read()
        guard Int(len) == data.count else {
            throw Error.SizeMismatch(message: "Got \(data.count) bytes, expected \(len)")
        }

        let ptype = try b.read() as UInt32
        guard ptype == 8 else {
            throw Error.InvalidType(message: "Got invalid packet type: \(ptype)")
        }

        code = try b.read()
        let msn = UInt8(code >> (16 - 4))
        switch msn {
        case 0b0100:
            type = PTPEventType(rawValue: code) ?? . Reserved
        case 0b1100:
            type = .Vendor
        default:
            type = .Invalid
        }

        sessionID = try b.read()
        transactionID = try b.read()

        var params = [UInt32]()
        while b.position < data.count && params.count < 3 {
            params.append(try b.read())
        }
        parameters = params
    }

    public var description: String {
        let typeDesc: String
        switch type {
        case .Vendor:
            typeDesc = String(format: "Vendor (%#04x)", code)
        case .Invalid:
            typeDesc = String(format: "Invalid (%#04x)", code)
        default:
            typeDesc = String(describing: type)
        }
        return "\(typeDesc) - \(parameters)"

    }

}
