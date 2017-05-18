//
//  ProgramConfigurationViewController.swift
//  triggy
//
//  Created by Johan Nordberg on 09/03/2017.
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

class ProgramConfigurationViewController: UIViewController {
    
    var program: ExposureProgram! { didSet { title = program.name } }
    var camera: Camera!

    @IBAction func doneButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @IBOutlet weak var scrollView: UIScrollView!
    override func viewWillAppear(_ animated: Bool) {
        let programView = program.configurationView
        var programFrame = programView.frame
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        programFrame.size.width = scrollView.frame.width
        programView.frame = programFrame
        scrollView.autoresizesSubviews = true
        scrollView.addSubview(programView)
        scrollView.contentSize = programView.bounds.size
        program.configurationViewWillAppear(withCamera: camera)
    }

    override func viewDidLoad() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    func viewTapped(sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardShow), name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardHide), name: .UIKeyboardWillHide, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        program.configurationViewWillDisappear()
        NotificationCenter.default.removeObserver(self)
    }

    internal var prevInset: UIEdgeInsets?

    func keyboardShow(note: Notification) {
        guard let userInfo = note.userInfo else { return }
        guard let keyboardFrame = userInfo[UIKeyboardFrameBeginUserInfoKey] as? CGRect else { return }
        var inset = scrollView.contentInset
        inset.bottom = keyboardFrame.height
        prevInset = scrollView.contentInset
        scrollView.contentInset = inset
        scrollView.scrollIndicatorInsets = inset
    }

    func keyboardHide(note: Notification) {
        let inset = prevInset ?? UIEdgeInsets.zero
        scrollView.contentInset = inset
        scrollView.scrollIndicatorInsets = inset
    }

}
