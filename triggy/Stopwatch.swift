//
//  Stopwatch.swift
//  triggy
//
//  Created by Johan Nordberg on 06/03/2017.
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

struct Stopwatch {
    var startTime: UInt64 = 0
    var stopTime: UInt64 = 0
    let numer: UInt64
    let denom: UInt64
    
    init() {
        var info = mach_timebase_info(numer: 0, denom: 0)
        mach_timebase_info(&info)
        numer = UInt64(info.numer)
        denom = UInt64(info.denom)
    }
    
    mutating func start() {
        startTime = mach_absolute_time()
    }
    
    mutating func stop() {
        stopTime = mach_absolute_time()
    }
    
    var nanoseconds: UInt64 {
        return ((stopTime - startTime) * numer) / denom
    }
    
    var milliseconds: Double {
        return Double(nanoseconds) / 1_000_000.0
    }
    
    var seconds: Double {
        return Double(nanoseconds) / 1_000_000_000.0
    }
}
