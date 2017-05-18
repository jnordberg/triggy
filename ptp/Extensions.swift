//
//  Extensions.swift
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


extension UnicodeScalar {
    
    var hexNibble: UInt8? {
        let value = self.value
        if 48 <= value && value <= 57 {
            return UInt8(value - 48)
        }
        else if 65 <= value && value <= 70 {
            return UInt8(value - 55)
        }
        else if 97 <= value && value <= 102 {
            return UInt8(value - 87)
        }
        return nil
    }
    
}

extension Data {
    
    public init(hexEncoded string: String) {
        let nibbles = string.unicodeScalars
            .map { $0.hexNibble }
            .filter { $0 != nil }
        var bytes = Array<UInt8>(repeating: 0, count: (nibbles.count + 1) >> 1)
        for (index, nibble) in nibbles.enumerated() {
            var n = nibble!
            if index & 1 == 0 {
                n <<= 4
            }
            bytes[index >> 1] |= n
        }
        self = Data(bytes: bytes)
    }
    
    public var asciiValue: String {
        return String(bytes: self, encoding: .ascii)!
    }
    
    public var hexValue: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
    
    public mutating func append(ascii str: String) {
        append(str.data(using: .ascii)!)
    }
    
    public mutating func append(hex str: String) {
        append(Data(hexEncoded: str))
    }
    
    public mutating func append(unicode16 str: String) {
        for c in str.unicodeScalars {
            append(littleEndian: Int16(c.value))
        }
    }
    
}

