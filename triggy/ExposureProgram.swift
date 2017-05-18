//
//  ExposureProgram.swift
//  triggy
//
//  Created by Johan Nordberg on 07/03/2017.
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
import CoreImage
import UIKit

/// ExposurePrograms are managed by the Camera and all methods are run on the camera's GCD queue.
protocol ExposureProgram {

    /// Name of program
    var name: String { get }

    /// Configuration view for program
    var configurationView: UIView { get }
    func configurationViewWillAppear(withCamera camera: Camera)
    func configurationViewWillDisappear()

    /// Called before capture session starts.
    func configure(withCamera camera: Camera) throws
    
    /// Called after each successful exposure with the thumbnail of the last capture.
    func run(withCamera camera: Camera, lastCapture image: CIImage) throws
}
