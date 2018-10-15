//
//  LoginViewController.swift
//  Apprtc
//
//  Created by vmio69 on 12/13/17.
//  Copyright © 2017 Dhilip. All rights reserved.
//

import UIKit
import Material
import RxCocoa
import RxSwift
import SocketRocket
import Toast_Swift
import SVProgressHUD

class LoginViewController: SocketViewController {

  @IBOutlet weak var versionLabel: UILabel!
  @IBOutlet weak var usernameTextField: TextField!
  @IBOutlet weak var passwordTextField: TextField!
  @IBOutlet weak var loginButton: Button!

  // MARK: - LIFE CYCLE
  override func viewDidLoad() {
    super.viewDidLoad()

    usernameTextField.backgroundColor = Color.darkGray
    usernameTextField.textColor = Color.white
    usernameTextField.leftViewMode = .always

    passwordTextField.backgroundColor = Color.darkGray
    passwordTextField.textColor = Color.white
    passwordTextField.leftViewMode = .always

    autoHideKeyboard()

    if let infoDict = Bundle.main.infoDictionary,
      let appVer = infoDict["CFBundleShortVersionString"],
      let buildNum = infoDict["CFBundleVersion"] {

      versionLabel.text = "Ver.\(appVer).\(buildNum)"
    }

    setNeedsStatusBarAppearanceUpdate()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let username: String = UserDefaults.standard.value(forKey: "username") as? String,
      let password: String = UserDefaults.standard.value(forKey: "password") as? String {
      usernameTextField.text = username
      passwordTextField.text = password
    } else {
      usernameTextField.text = ""
      passwordTextField.text = ""
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(true)
    view.hideAllToasts()
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showContactSegueId" {
      let contactVc = segue.destination as? ContactViewController
      //            contactVc?.socket = self.socket
      contactVc?.myName = usernameTextField.text
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func loginButtonTouched(_ sender: Any) {
    view.endEditing(true)
    if  let username = usernameTextField.text,
      let password = passwordTextField.text,
      username.count > 0 && password.count > 0 {
      socket?.login(name: username, password: password) { (socketError, message) in
        if socketError == SocketError.notOpen {
          openSocket()
          DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.5, execute: {
            self.view.makeToast("Try again!")
          })
        } else {
          view.makeToast(message)
        }
      }
    } else {
      self.view.makeToast("Username and Password are required!")
    }
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return UIStatusBarStyle.lightContent
  }
}

extension LoginViewController {
  // MARK: - WEB SOCKET DELEGATE
  override func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
    super.webSocket(webSocket, didReceiveMessage: message)
    if  let messageString: String = message as? String {
      let message: MessageSocket = MessageSocket(message: messageString)
      if message.type == functionLogin {
        DispatchQueue.main.async {
          SVProgressHUD.dismiss()
        }
        if message.isSuccess {
          UserDefaults.standard.set(usernameTextField.text, forKey: "username")
          UserDefaults.standard.set(passwordTextField.text, forKey: "password")

          self.performSegue(withIdentifier: "showContactSegueId", sender: self)
        } else {
          DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.5, execute: {
            SVProgressHUD.showError(withStatus: message.message)
          })
        }
      }
    }
  }
}
