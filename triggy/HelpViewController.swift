//
//  HelpViewController.swift
//  triggy
//
//  Created by Johan Nordberg on 13/01/17.
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
import UIKit

class HelpViewController: UIViewController {

    @IBOutlet var webView: UIWebView!
    
    @IBAction func close() {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = Bundle.main.url(forResource: "help", withExtension: "html")
        let html = try! String(contentsOf: url!)
        webView.loadHTMLString(html, baseURL: nil)
    }
    
}
