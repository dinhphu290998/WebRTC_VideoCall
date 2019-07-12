//
//  SplashViewController.swift
//  Ai-Tec
//
//  Created by Apple on 10/16/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit
import CoreLocation
class SplashViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var versionLabel: UILabel!
    var currentLocation: CLLocation?
    var locationManager: CLLocationManager = CLLocationManager()
    let kml = KML.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()

        kml.soap()
        if let infoDict = Bundle.main.infoDictionary,
            let appVer = infoDict["CFBundleShortVersionString"],
            let buildNum = infoDict["CFBundleVersion"] {
            
            versionLabel.text = "Ver.\(appVer).\(buildNum)"
        }
        setNeedsStatusBarAppearanceUpdate()
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            self.performSegue(withIdentifier: "showLoginSegueId", sender: self)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.default
    }

}
