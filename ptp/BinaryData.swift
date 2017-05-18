//
//  BinaryData.swift
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


public struct BinaryData {
    
    public enum EndianType {
        case LittleEndian
        case BigEndian
    }
    
    public enum Error: Swift.Error {
        case OutOfBounds
        case InvalidString
    }
    
    public var data: Data
    public var position: Int = 0
    public var endianness: EndianType = .LittleEndian
    
    public init(_ data: Data) {
        self.data = data
    }
    
    public mutating func read<T: EndianRepresentable>() throws -> T {
        let size = MemoryLayout<T>.size
        if position + size > data.count {
            throw Error.OutOfBounds
        }
        let bits = data.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> T in
            ptr.advanced(by: self.position).withMemoryRebound(to: T.self, capacity: size) { $0.pointee }
        }
        position += size
        switch endianness {
        case .BigEndian:
            return T(bigEndian: bits)
        case .LittleEndian:
            return T(littleEndian: bits)
        }
    }
    
    public mutating func read<T: EndianRepresentable>(count: Int) throws -> [T] {
        var rv = [T]()
        for _ in 0..<count {
            rv.append(try read())
        }
        return rv
    }
    
    public mutating func read<T: EndianRepresentable, W: EndianRepresentable & IntegerArithmetic>(prefixedArray: W.Type) throws -> [T] {
        let count:W = try read()
        return try read(count: Int(count.toIntMax()))
    }
    
    public mutating func read<T: EndianRepresentable & Equatable>(untilIncluding target: T) throws -> [T] {
        var rv = [T]()
        var current: T
        while true {
            current = try read()
            rv.append(current)
            if current == target {
                break
            }
        }
        return rv
    }
    
    public mutating func read(encoding: String.Encoding) throws -> String {
        switch encoding {
        case (String.Encoding.utf8), (String.Encoding.ascii):
            let chars: [UInt8] = try read(untilIncluding: 0)
            guard let rv = String(bytes: chars, encoding: encoding) else {
                throw Error.InvalidString
            }
            return rv
        case String.Encoding.utf16:
            let chars: [UInt16] = try read(untilIncluding: 0)
            let data = chars.withUnsafeBufferPointer { Data(buffer: $0) }
            guard let rv = String(data: data, encoding: .utf16LittleEndian) else {
                throw Error.InvalidString
            }
            return rv
        default:
            fatalError("Unsupported encoding")
        }
    }
    
}
