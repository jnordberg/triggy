//
//  ViewController.swift
//  triggy
//
//  Created by Johan Nordberg on 2016-12-23.
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

import UIKit
import Reachability


class ZoomInTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        guard let from = transitionContext.viewController(forKey: .from) else { return }
        guard let to = transitionContext.viewController(forKey: .to) else { return }
        
        containerView.addSubview(to.view)
        
        to.view.alpha = 0.0
        to.view.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
        from.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        
        let vc = from as? ViewController

        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, animations: { 
            to.view.alpha = 1.0
            vc?.infoLabel.alpha = 0.0
            to.view.transform = CGAffineTransform.identity
            from.view.transform = CGAffineTransform(scaleX: 5, y: 5)
        }) { _ in
            let cancelled = transitionContext.transitionWasCancelled
            from.view.transform = CGAffineTransform.identity
            transitionContext.completeTransition(!cancelled)
        }
    }
    
    
}



class ZoomOutTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        guard let from = transitionContext.viewController(forKey: .from) else { return }
        guard let to = transitionContext.viewController(forKey: .to) else { return }
        
        containerView.insertSubview(to.view, belowSubview: from.view)
//        containerView.addSubview(to.view)
        
        let vc = to as? ViewController
        
        to.view.alpha = 1.0
        to.view.transform = CGAffineTransform(scaleX: 5.0, y: 5.0)
//        from.view.transform = CGAffineTransform(scaleX: 5.0, y: 5.0)
        
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, animations: {
            from.view.alpha = 0.0
            vc?.infoLabel.alpha = 1.0
            to.view.transform = CGAffineTransform.identity
            from.view.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
        }) { _ in
            let cancelled = transitionContext.transitionWasCancelled
            
            transitionContext.completeTransition(!cancelled)
        }
    }
    
    
}


@IBDesignable
class PulseView: UIView {
    
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    let numRings = 4
    var rings = [CAShapeLayer]()

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.sublayers = nil
        setupRings()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupRings()
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupRings()
        setup()
    }
    
    let lpgr = UILongPressGestureRecognizer()
    let tgr = UITapGestureRecognizer()
    func setup() {
        lpgr.minimumPressDuration = 4
        lpgr.numberOfTouchesRequired = 2
        lpgr.addTarget(self, action: #selector(longPress))
        addGestureRecognizer(lpgr)
        tgr.addTarget(self, action: #selector(tap))
        addGestureRecognizer(tgr)
    }
    
    var longPressCallback: ((Void) -> Void)?
    func longPress() {
        if lpgr.state == .began {
            longPressCallback?()
        }
    }
    
    var tapCallback: ((Void) -> Void)?
    func tap() {
        if tgr.state == .ended {
            tapCallback?()
        }
    }
    
    func setupRings() {
        let minSize = self.bounds.width * 0.28
        let maxSize = self.bounds.width * 0.2
        
        let l = self.layer as! CAGradientLayer
        l.colors = Colors.background
   
        self.rings = []
        var delay: CFTimeInterval = 0.0
        
        for i in 0..<numRings {
            let layer = CAShapeLayer()
            
            layer.fillColor = Colors.main.cgColor
            layer.opacity = 1 / Float(numRings - 2)
            
            
            //            layer.compositingFilter = Filter
       
            let bigRing = UIBezierPath(ovalIn: self.bounds.insetBy(dx: -maxSize, dy: -maxSize))
            let smallRing = UIBezierPath(ovalIn: self.bounds.insetBy(dx: minSize, dy: minSize))
            
            layer.path = smallRing.cgPath
            
            let v1 = CGFloat(Float(arc4random()) / Float(UINT32_MAX)) * 2
            let v2 = CGFloat(Float(arc4random()) / Float(UINT32_MAX)) * 2
            
            let anim = CABasicAnimation(keyPath: "path")
            anim.fromValue = smallRing.cgPath
            anim.toValue = bigRing.cgPath
            anim.duration = CFTimeInterval(5 + v1)
            anim.beginTime = 0.0
            
            let anim2 = CABasicAnimation(keyPath: "path")
            anim2.fromValue = bigRing.cgPath
            anim2.toValue = smallRing.cgPath
            anim2.duration = CFTimeInterval(2.0 + v2)
            anim2.beginTime = anim.duration
            
            
            let grp = CAAnimationGroup()
            grp.animations = [anim, anim2]
            grp.repeatCount = .greatestFiniteMagnitude
            grp.duration = grp.animations!.reduce(0) { $0 + $1.duration }
            
            grp.beginTime = CACurrentMediaTime() + CFTimeInterval(i) * (6.0 / CFTimeInterval(numRings))
            grp.isRemovedOnCompletion = false
            
            delay += grp.duration
            
            layer.add(grp, forKey: nil)
            
            self.layer.addSublayer(layer)
            self.rings.append(layer)
        }

    }
    
}

class ViewController: UIViewController, UIViewControllerTransitioningDelegate {
    
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var wifiLabel: UILabel!
    @IBOutlet var pulseView: PulseView!
    
    @IBAction func fakeCamera() {
    }

    func configureWifiLabel() {
        if let ssid = App.shared.networkSSID {
            wifiLabel.text = "WiFi network: " + ssid
        } else {
            wifiLabel.text = "Not connected to WiFi"
        }
    }
    
    func configureView(state: AppState) {
        configureWifiLabel()
        switch state {
        case .Connected:
            infoLabel.text = "Connected"
        case .Connecting:
            infoLabel.text = "Found camera! Connecting"
        case .Browsing:
            infoLabel.text = "Looking for camera"
        case .Inactive:
            infoLabel.text = "Tap to reconnect"
        default:
            infoLabel.text = "Invalid app state"
        }
    }

    
    var observerToken: NSObjectProtocol?
    var statusObserverToken: NSObjectProtocol?
    var networkObserverToken: NSObjectProtocol?
    
    override func viewDidAppear(_ animated: Bool) {
        if App.shared.state == .Connected {
            self.performSegue(withIdentifier: "timelapseConfig", sender: self)
        }
        if App.shared.state == .Inactive && wasBrowsing {
            App.shared.startBrowsing()
            wasBrowsing = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        configureView(state: App.shared.state)
        observerToken = NotificationCenter.default.addObserver(forName: App.StateChangeNotification, object: nil, queue: OperationQueue.main) { note in
            let state = App.shared.state
            self.configureView(state: state)
            if state == .Connected {
                self.performSegue(withIdentifier: "timelapseConfig", sender: self)
            }
        }
        statusObserverToken = NotificationCenter.default.addObserver(forName: App.CameraStatusNotification, object: nil, queue: OperationQueue.main) { note in
            if let info = note.userInfo {
                if let msg = info["message"] as? String {
                    self.infoLabel.text = msg
                }
            }
        }
        networkObserverToken = NotificationCenter.default.addObserver(forName: ReachabilityChangedNotification, object: nil, queue: OperationQueue.main) { note in
            self.configureWifiLabel()
        }
    }
    
    var wasBrowsing: Bool = false
    
    override func viewWillDisappear(_ animated: Bool) {
        if App.shared.state == .Browsing {
            App.shared.stopBrowsing()
            wasBrowsing = true
        }
        if let token = observerToken {
            NotificationCenter.default.removeObserver(token)
            observerToken = nil
        }
        if let token = statusObserverToken {
            NotificationCenter.default.removeObserver(token)
            statusObserverToken = nil
        }
        if let token = networkObserverToken {
            NotificationCenter.default.removeObserver(token)
            networkObserverToken = nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let bg = CAGradientLayer()
        bg.frame = view.bounds
        bg.colors = Colors.background.cgColor
        pulseView.longPressCallback = {
            if App.shared.browser.isBrowsing { App.shared.browser.stopBrowsing() }
            App.shared.camera = TestCamera()
        }
        pulseView.tapCallback = {
            if App.shared.state == .Inactive {
                App.shared.startBrowsing()
            }
        }
        view.layer.insertSublayer(bg, below: view.layer.sublayers?.first)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ZoomInTransition()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ZoomOutTransition()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let to = segue.destination as? TimelapseConfigViewController else {
            return
        }
        
        to.transitioningDelegate = self
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
}

