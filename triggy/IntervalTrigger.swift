//
//  IntervalTrigger.swift
//  triggy
//
//  Created by Johan Nordberg on 2017-01-01.
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
import Dispatch

class IntervalTrigger {
    
    var action: ((Void) -> Void)?
    
    internal var _interval: TimeInterval = 1.0
    var interval: TimeInterval {
        get { return _interval }
        set {
            if newValue != _interval {
                _interval = newValue
                reschedule()
            }
        }
    }
    
    var isRunning: Bool { return timer != nil }
    
    internal var timer: Timer?
    
    deinit {
        stop()
    }
    
    func start() {
        if isRunning { return }
        timer = makeTimer()
        RunLoop.main.add(timer!, forMode: RunLoopMode.commonModes)
        DispatchQueue.main.async { [unowned self] in
            self.action?()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    internal func makeTimer() -> Timer {
        return Timer(timeInterval: interval, repeats: true) { [unowned self ] _ in
            self.action?()
        }
    }
    
    internal func reschedule() {
        if !isRunning { return }
        timer!.invalidate()
        timer = makeTimer()
        RunLoop.main.add(timer!, forMode: RunLoopMode.commonModes)
    }
    
}
