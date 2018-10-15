//
//  SplashViewController.swift
//  Apprtc
//
//  Created by vmio69 on 12/13/17.
//  Copyright © 2017 Dhilip. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {

  @IBOutlet weak var versionLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()

    if let infoDict = Bundle.main.infoDictionary,
      let appVer = infoDict["CFBundleShortVersionString"],
      let buildNum = infoDict["CFBundleVersion"] {

      versionLabel.text = "Ver.\(appVer).\(buildNum)"
    }
    setNeedsStatusBarAppearanceUpdate()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
      self.performSegue(withIdentifier: "showLoginSegueId", sender: self)
    }
    //        FileManager.default.clearTmpDirectory()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return UIStatusBarStyle.default
  }
}
