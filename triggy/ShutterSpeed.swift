//
//  ShutterSpeed.swift
//  triggy
//
//  Created by Johan Nordberg on 10/03/2017.
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


struct ShutterSpeed: CustomStringConvertible, Equatable, Comparable, ExpressibleByIntegerLiteral,
ExpressibleByFloatLiteral, ExpressibleByStringLiteral, Substractable {

    public static func -(lhs: ShutterSpeed, rhs: ShutterSpeed) -> ShutterSpeed {
        return ShutterSpeed(seconds: lhs.seconds - rhs.seconds)
    }

    public static func <(lhs: ShutterSpeed, rhs: ShutterSpeed) -> Bool {
        return lhs.rational < rhs.rational
    }

    public static func ==(lhs: ShutterSpeed, rhs: ShutterSpeed) -> Bool {
        return lhs.rational == rhs.rational
    }

    private let rational: Rational
    private static let commonDenominators = [
        4, 5, 6, 8, 10, 13, 15, 20, 25, 30, 40, 50, 60, 80, 100, 125, 160, 200, 250, 320,
        400, 500, 640, 800, 1000, 1250, 1600, 2000, 2500, 3200, 4000, 5000, 6000, 6400, 8000
    ]

    var isValid: Bool { return rational.numerator != 0 }
    var seconds: Double { return Double(rational) }

    init(rational: Rational) {
        self.rational = rational
    }

    init(seconds: Double) {
        if seconds.isNormal {
            self.rational = Rational(seconds, tolerance: 2e-5, preferredDenominators: ShutterSpeed.commonDenominators)
        } else {
            self.rational = Rational(numerator: 0, denominator: 1)
        }
    }

    init(integerLiteral value: Int) {
        self.init(rational: Rational(integerLiteral: value))
    }

    init(floatLiteral value: Double) {
        self.init(seconds: value)
    }

    init(stringLiteral value: String) {
        if value.contains(["”", "\"", ","]) {
            let seconds = Double(value.replacingOccurrences(of: ["”", "\"", ","], with: ".")) ?? 0
            self.init(floatLiteral: seconds)
        } else if value.contains("/") {
            let parts = value.components(separatedBy: "/")
                .map({ Int($0) })
                .filter({ $0 != nil })
                .map({ $0! })
            guard parts.count == 2 && parts[0] > 0 && parts[1] != 0 else {
                self.init(floatLiteral: 0)
                return
            }
            self.init(rational: Rational(numerator: parts[0], denominator: parts[1]))
        } else {
            self.init(floatLiteral: Double(value) ?? 0)
        }
    }

    init(extendedGraphemeClusterLiteral value: Character) {
        self.init(stringLiteral: String(describing: value))
    }

    init(unicodeScalarLiteral value: UnicodeScalar) {
        self.init(stringLiteral: String(describing: Character(value)))
    }

    var description: String {
        if !isValid { return "Invalid (\(rational.numerator)/\(rational.denominator))" }
        if seconds >= 1.0 {
            return String(format: "%.1f", seconds)
                    .replacingOccurrences(of: ".", with: "”")
                    .replacingOccurrences(of: "”0", with: "”")
        }
        return "\(rational.numerator)/\(rational.denominator)"
    }
    
}
