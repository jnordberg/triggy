//
//  SettingsViewController.swift
//  triggy
//
//  Created by Johan Nordberg on 2016-12-30.
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

class SettingsViewController: UITableViewController {

    override func viewWillDisappear(_ animated: Bool) {
        SoundPlayer.shared.deactivate()
    }
    
    var wasBrowsing: Bool = false
    override func viewWillAppear(_ animated: Bool) {
        let soundIdx = UserDefaults.standard.integer(forKey: "shutterSound")
        do {
            try SoundPlayer.shared.activate(soundIdx)
        } catch let error {
            print("WARNING: Unable to activate sound player when opening settings.", error)
        }
//        let path = IndexPath(row: soundIdx, section: 0)
//        self.tableView.scrollToRow(at: path, at: .middle, animated: false)
    }
    
    @IBAction func closeSettings() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Shutter sound"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SoundPlayer.shared.sounds.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SoundCell", for: indexPath)
        
        let player = SoundPlayer.shared
        let sound = player.sounds[indexPath.row]
        
        cell.textLabel?.text = sound.title
        cell.accessoryType = sound == player.active ? .checkmark : .none

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let player = SoundPlayer.shared
        let sound = player.sounds[indexPath.row]
        var lastIndex: Int?
        if let lastActive = player.active {
            lastIndex = player.sounds.index(of: lastActive)
        }
        do {
            try player.activate(indexPath.row)
            try player.play()
        } catch let error {
            print("WARNING: Unable to play sound", sound, error)
        }
        
        if let idx = lastIndex {
            let lastCell = tableView.cellForRow(at: IndexPath(row: idx, section: 0))
            lastCell?.accessoryType = .none
        }
        
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        UserDefaults.standard.set(indexPath.row, forKey: "shutterSound")
    }
    
    
}
