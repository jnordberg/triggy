//
//  EndianRepresentable.swift
//  triggy
//
//  Created by Johan Nordberg on 2016-12-25.
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

public protocol EndianRepresentable {
    var littleEndian: Self { get }
    var bigEndian: Self { get }
    init(littleEndian: Self)
    init(bigEndian: Self)
}

extension UInt8: EndianRepresentable {
    public var littleEndian: UInt8 { return self }
    public var bigEndian: UInt8 { return self }
    public init(littleEndian: UInt8) { self = littleEndian }
    public init(bigEndian: UInt8) { self = bigEndian }
}

extension Int8: EndianRepresentable {
    public var littleEndian: Int8 { return self }
    public var bigEndian: Int8 { return self }
    public init(littleEndian: Int8) { self = littleEndian }
    public init(bigEndian: Int8) { self = bigEndian }
}

extension UInt16: EndianRepresentable {}
extension Int16: EndianRepresentable {}
extension UInt32: EndianRepresentable {}
extension Int32: EndianRepresentable {}
extension UInt64: EndianRepresentable {}
extension Int64: EndianRepresentable {}
extension UInt: EndianRepresentable {}
extension Int: EndianRepresentable {}

extension Data {
    public func getLittleEndian<T: EndianRepresentable>(start: Int) -> T {
        let bits = withUnsafeBytes({(bytePointer: UnsafePointer<UInt8>) -> T in
            bytePointer.advanced(by: start).withMemoryRebound(to: T.self, capacity: MemoryLayout<T>.size) { pointer in
                return pointer.pointee
            }
        })
        return T(littleEndian: bits)
    }
    
    public mutating func append<T: EndianRepresentable>(littleEndian value: T) {
        var v = value.littleEndian
        append(UnsafeBufferPointer(start: &v, count: 1))
    }
}


