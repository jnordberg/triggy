//
//  Extensions.swift
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

extension Collection where Iterator.Element: FloatingPoint {
    
    var median: Iterator.Element? {
        let values = sorted(by: <)
        let count = values.count
        if count == 0 { return nil }
        if count % 2 == 0 {
            let leftIndex = count / 2 - 1
            let leftValue = values[leftIndex]
            let rightValue = values[leftIndex + 1]
            return (leftValue + rightValue) / 2
        } else {
            return values[count / 2]
        }
    }
    
    var average: Iterator.Element? {
        if count == 0 { return nil }
        let sum = reduce(0) { $0.0 + $0.1 }
        return sum / Iterator.Element(count.toIntMax())
    }
    
    var extent: ClosedRange<Iterator.Element>? {
        if count == 0 { return nil }
        var min: Iterator.Element = first!
        var max: Iterator.Element = first!
        for val in self {
            if val > max { max = val }
            if val < min { min = val }
        }
        return min...max
    }
    
}

extension Collection {

    /// Finds such index N that predicate is true for all elements up to
    /// but not including the index N, and is false for all elements
    /// starting with index N.
    /// Behavior is undefined if there is no such N.
    func binarySearch(predicate: (Iterator.Element) -> Bool) -> Index {
        var low = startIndex
        var high = endIndex
        while low != high {
            let mid = index(low, offsetBy: distance(from: low, to: high)/2)
            if predicate(self[mid]) {
                low = index(after: mid)
            } else {
                high = mid
            }
        }
        return low
    }

}

extension Collection where Iterator.Element: Substractable & Comparable {

    func nearest(to item: Iterator.Element) -> Index {
        let highIdx = binarySearch { $0 < item }
        let lowIdx = index(highIdx, offsetBy: IndexDistance(-1))

        if highIdx == endIndex { return lowIdx }
        if highIdx == startIndex { return highIdx }

        if self[highIdx] - item > item - self[lowIdx] {
            return lowIdx
        }
        return highIdx
    }
    
}

extension String {

    func replacingOccurrences(of items: [String], with value: String) -> String {
        var rv = self
        for item in items {
            rv = rv.replacingOccurrences(of: item, with: value)
        }
        return rv
    }

    func contains(_ other: [String]) -> Bool {
        for item in other {
            if contains(item) { return true }
        }
        return false
    }

}
