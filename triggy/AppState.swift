//
//  AppState.swift
//  triggy
//
//  Created by Johan Nordberg on 07/01/17.
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

// Shared between watch and phone

import Foundation
import UIKit

enum AppState: Int {
    case Inactive
    case Browsing
    case Connecting
    case Connected
    case Capturing
}

struct AppKeys {
    static let captureInterval = "captureInterval"
    static let shutterSound = "shutterSound"
    static let sessionName = "captureSession"
}

func sliderToInterval(_ input: CGFloat) -> TimeInterval {
    if input < 0.25 {
        // first quarter is 1-30s
        let r = TimeInterval(input * 4)
        return 1 + r * 30
    } else if input < 0.5 {
        // second is 30s-2m
        let r = TimeInterval((input - 0.25) * 4)
        return 30 + r * 90
    } else {
        // rest is 2-10m
        let r = TimeInterval((input - 0.5) * 2)
        return 120 + r * 480
    }
}

func intervalToSlider(_ input: TimeInterval) -> CGFloat {
    if input < 30 {
        return CGFloat((input - 1) / 30 / 4)
    } else if input < 120 {
        return 0.25 + CGFloat((input - 31) / 90 / 4)
    } else {
        return 0.5 + CGFloat((input - 121) / 480 / 2)
    }
}

func roundedInterval(_ interval: TimeInterval) -> TimeInterval {
    if interval < 30 {
        return floor(interval * 2) / 2.0
    } else {
        return floor(interval)
    }
}

func formatInterval(_ interval: TimeInterval) -> String {
    if interval < 30 {
        return String(format: "%.1f", floor(interval * 2) / 2)
    } else if interval < 60 {
        return String(format: "%.0f", interval)
    } else {
        let minutes = floor(interval / 60)
        let seconds = floor(interval - minutes * 60)
        return String(format: "%02.0f:%02.0f", minutes, seconds)
    }
}

func formatDuration(_ duration: TimeInterval) -> String {
    if duration < 60 {
        return String(format: "%.1fs", duration)
    } else {
        let minutes = floor(duration / 60)
        let seconds = floor(duration - minutes * 60)
        return String(format: "%.0fm %.0fs", minutes, seconds)
    }
}


extension UIFont {
    
    var monospacedDigitFont: UIFont {
        let oldFontDescriptor = fontDescriptor
        let newFontDescriptor = oldFontDescriptor.monospacedDigitFontDescriptor
        return UIFont(descriptor: newFontDescriptor, size: 0)
    }
    
}


#if (arch(i386) || arch(x86_64)) && (os(iOS) || os(watchOS) || os(tvOS))
    // no idea, works on device...
    let kMonospacedNumbersSelector = 0
    let kNumberSpacingType = 6
    
#endif


private extension UIFontDescriptor {
    
    var monospacedDigitFontDescriptor: UIFontDescriptor {
        let fontDescriptorFeatureSettings = [[UIFontFeatureTypeIdentifierKey: kNumberSpacingType, UIFontFeatureSelectorIdentifierKey: kMonospacedNumbersSelector]]
        let fontDescriptorAttributes = [UIFontDescriptorFeatureSettingsAttribute: fontDescriptorFeatureSettings]
        let fontDescriptor = self.addingAttributes(fontDescriptorAttributes)
        return fontDescriptor
    }
    
}




