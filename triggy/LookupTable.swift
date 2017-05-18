//
//  LookupTable.swift
//  triggy
//
//  Created by Johan Nordberg on 14/03/2017.
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
import OrderedDictionary

struct LookupTable<Key: Hashable, Value: Substractable & Comparable>: ExpressibleByDictionaryLiteral {

    let dict: OrderedDictionary<Key, Value>

    init(_ dict: OrderedDictionary<Key, Value>) {
        self.dict = dict.sorted(by: { $0.0.value < $0.1.value })
    }

    init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(OrderedDictionary(elements.map { (key: $0, value: $1) }))
    }

    subscript(key: Key) -> (key: Key, value: Value)? {
        if let idx = dict.index(forKey: key) {
            return dict[idx]
        }
        return nil
    }

    subscript(value: Value) -> (key: Key, value: Value)? {
        if let idx = dict.orderedValues.index(of: value) {
            return dict[idx]
        }
        return nil
    }

    func nearest(toValue value: Value) -> (key: Key, value: Value) {
        let idx = dict.orderedValues.nearest(to: value)
        return dict[idx]
    }

}
