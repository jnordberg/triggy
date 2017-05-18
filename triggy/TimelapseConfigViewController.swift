//
//  TimelapseViewController.swift
//  triggy
//
//  Created by Johan Nordberg on 2016-12-28.
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
import UIKit
import PTP

class TimelapseConfigViewController: UIViewController, AKPickerViewDataSource, AKPickerViewDelegate {

    let exposurePrograms = [AutoShutterProgram()]
    var activeProgram: ExposureProgram?
    
    public func numberOfItemsInPickerView(_ pickerView: AKPickerView) -> Int {
        return exposurePrograms.count + 1
    }
    
    func pickerView(_ pickerView: AKPickerView, titleForItem item: Int) -> String {
        return item == 0 ? "None" : exposurePrograms[item - 1].name
    }
    
    func pickerView(_ pickerView: AKPickerView, didSelectItem item: Int) {
        activeProgram = item == 0 ? nil : exposurePrograms[item - 1]
        if var camera = App.shared.camera {
            camera.program = activeProgram
        }
        configureLabel.isHidden = activeProgram == nil
    }
    
    @IBOutlet var configureLabel: UILabel!
    @IBOutlet var toggleButton: UIButton!
    @IBOutlet var intervalSlider: CircularSlider!
    @IBOutlet var intervalLabel: UILabel!
    @IBOutlet var programPicker: AKPickerView!
    
    func configureView(state: AppState) {
        assert(state == .Connected, "Config view configured with invalid state")
        configureLabel.isHidden = activeProgram == nil
        intervalLabel.text = formatInterval(App.shared.captureInterval)
        intervalSlider.endPointValue = intervalToSlider(App.shared.captureInterval)
    }
    
    func configureProgram(sender: UITapGestureRecognizer) {
        if sender.state == .ended && activeProgram != nil {
            performSegue(withIdentifier: "programConfig", sender: self)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let programTapGesture = UITapGestureRecognizer(target: self, action: #selector(configureProgram))
        programTapGesture.cancelsTouchesInView = false
        
        programPicker.dataSource = self
        programPicker.delegate = self
        programPicker.pickerViewStyle = .flat
        programPicker.selectItem(0)
        
        programPicker.addGestureRecognizer(programTapGesture)
        programPicker.font = UIFont.systemFont(ofSize: 30)
        programPicker.highlightedFont = UIFont.systemFont(ofSize: 30)
        intervalLabel.font = intervalLabel.font.monospacedDigitFont
    }
    
    var observerToken: NSObjectProtocol?
    var observerTokenInterval: NSObjectProtocol?
    
    override func viewWillAppear(_ animated: Bool) {
        if App.shared.state == .Connected {
            configureView(state: App.shared.state)
        } else {
            dismiss(animated: animated, completion: nil)
        }
        observerToken = NotificationCenter.default.addObserver(forName: App.StateChangeNotification, object: nil, queue: OperationQueue.main) { note in
            let state = App.shared.state
            if state == .Capturing {
                self.performSegue(withIdentifier: "timelapseRun", sender: self)
            } else if state == .Connected {
                self.configureView(state: state)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
        observerTokenInterval = NotificationCenter.default.addObserver(forName: App.IntervalChangeNotification, object: nil, queue: OperationQueue.main) { note in
            self.intervalLabel.text = formatInterval(App.shared.captureInterval)
            self.intervalSlider.endPointValue = intervalToSlider(App.shared.captureInterval)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let token = observerToken {
            NotificationCenter.default.removeObserver(token)
            observerToken = nil
        }
        if let token = observerTokenInterval {
            NotificationCenter.default.removeObserver(token)
            observerTokenInterval = nil
        }
    }
    
    @IBAction func disconnect() {
        App.shared.camera = nil
    }
    
    @IBAction func startTimelapse() {
        Activity.labelUserAction("Start timelapse")
        App.shared.startCapture()
    }

    @IBAction func changeInterval(sender: CircularSlider) {
        App.shared.captureInterval = sliderToInterval(sender.endPointValue)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let to = segue.destination as? TimelapseRunningViewController {
            to.transitioningDelegate = transitioningDelegate
        }
        if segue.identifier == "programConfig" {
            guard let to = (segue.destination as! UINavigationController).topViewController as? ProgramConfigurationViewController else {
                return
            }
            to.program = activeProgram
            to.camera = App.shared.camera
        }
        if segue.identifier == "cameraConfig" {
            guard let to = (segue.destination as! UINavigationController).topViewController as? CameraConfigViewController else {
                return
            }
            to.camera = App.shared.camera
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
}
