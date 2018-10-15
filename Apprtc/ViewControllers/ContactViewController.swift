//
//  ContactViewController.swift
//  Apprtc
//
//  Created by vmio69 on 12/14/17.
//  Copyright © 2017 Dhilip. All rights reserved.
//

import UIKit
import Material
import SocketRocket
import SwiftyJSON
import RxCocoa
import RxSwift
import CoreLocation
import SVProgressHUD

class ContactViewController: SocketViewController {

  @IBOutlet weak var myAvatarImageView: UIImageView!
  @IBOutlet weak var myStatusView: UIView!
  @IBOutlet weak var myNameLabel: UILabel!
  @IBOutlet weak var searchTextField: TextField!
  @IBOutlet weak var contactTableView: UITableView!
  @IBOutlet weak var logoutButton: Button!
  @IBOutlet weak var callButton: Button!
  @IBOutlet weak var emergencyButton: UIButton!

  var currentLocation: CLLocation?
  var locationManager: CLLocationManager = CLLocationManager()

  var myName: String?
  var myUser: User?
  var indexPathSelected: IndexPath?
  var dataSource = [User]()
  var dataSourceShow = [User]()
  let disposeBag = DisposeBag()
  // MARK: - LIFE CYCLE
  override func viewDidLoad() {
    super.viewDidLoad()

    searchTextField.backgroundColor = .white
    autoHideKeyboard()

    setNeedsStatusBarAppearanceUpdate()
    contactTableView.tableFooterView = UIView()
    myNameLabel.text = myName
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.requestAlwaysAuthorization()
    locationManager.startUpdatingLocation()

    searchTextField.rx.text.throttle(0.5, scheduler: MainScheduler.instance)
      .distinctUntilChanged({ (str1, str2) -> Bool in
        str1 == str2
      })
      .subscribe(
        onNext: { (str) in
          if let str = str {
            self.dataSourceShow = self.dataSource.filter({ (user) -> Bool in
              user.name.hasPrefix(str)
            })
            self.contactTableView.reloadData()
          }
      },
        onError: nil,
        onCompleted: nil,
        onDisposed: nil)
      .disposed(by: disposeBag)

    NotificationCenter.default.addObserver(self, selector: #selector(openSocket),
                                           name: Notification.Name("activeAppNotification"), object: nil)

    let longPress = UILongPressGestureRecognizer(target: self, action: #selector(emergencyLongPress))
    emergencyButton.addGestureRecognizer(longPress)
  }

  @objc func emergencyLongPress() {
    if let regId: String = myUser?.regId,
      let name: String = myUser?.name,
      let currentLocation = currentLocation {
      socket?.emergency(regId: regId, name: name,
                        latitude: String(format: "%.6f", currentLocation.coordinate.latitude),
                        longitude: String(format: "%.6f", currentLocation.coordinate.longitude),
                        completion: { (_, _) in

      })
    } else {
      SVProgressHUD.showError(withStatus: "Can't get your location! Please check GPS")
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    socket?.discovery(completion: { (_, _) in
      
    })
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    myStatusView.layer.cornerRadius = myStatusView.frame.width/2
    myStatusView.backgroundColor = UIColor.green

    myAvatarImageView.clipsToBounds = true
    myAvatarImageView.layer.borderColor = UIColor.white.cgColor
    myAvatarImageView.layer.borderWidth = 2
    myAvatarImageView.layer.cornerRadius = myAvatarImageView.frame.width/2
//    myAvatarImageView.setRandomDownloadImage(Int(myAvatarImageView.frame.width),
//                                             height: Int(myAvatarImageView.frame.height))
    myAvatarImageView.image = #imageLiteral(resourceName: "ic_launcher")

    searchTextField.leftView = UIImageView(image: Icon.search)
    searchTextField.leftViewOffset = -16
  }

  // MARK: - BUTTON EVENTS
  @IBAction func emergencyButtonTouched(_ sender: Any) {
    if let regId: String = myUser?.regId,
      let name: String = myUser?.name,
      let currentLocation = currentLocation {
      socket?.emergency(regId: regId, name: name,
                        latitude: String(format: "%.6f", currentLocation.coordinate.latitude),
                        longitude: String(format: "%.6f", currentLocation.coordinate.longitude),
                        completion: { (_, _) in

      })
    } else {
      SVProgressHUD.showError(withStatus: "Can't get your location! Please check GPS")
    }
  }

  @IBAction func logoutButtonTouched(_ sender: Any) {
    let alertVc = UIAlertController(title: "Logout", message: "Are you sure?", preferredStyle: .alert)
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in

    }
    let confirmAction = UIAlertAction(title: "Logout", style: .destructive) { (_) in
      self.socket?.logout(completion: { (_, _) in

      })
    }
    alertVc.addAction(cancelAction)
    alertVc.addAction(confirmAction)
    present(alertVc, animated: true, completion: nil)
  }

  @IBAction func callButtonTouched(_ sender: Any) {
    if let rowSelected = indexPathSelected?.row,
      let hostUser = myUser {
      let receiveUser = dataSource[rowSelected]
      socket?.call(host: hostUser.regId, receive: receiveUser.regId, name: hostUser.name) { (_, _) in

      }
      OneSignalHelper.sendCallVoip(receiveId: receiveUser.regId, message: "call",
                                   data: ["callerName": hostUser.name, "callerRegId": hostUser.regId],
                                   completion: { (idNoti, errors) in
                                    if errors != nil {
                                      print(errors ?? "")
                                    } else {
                                      print(idNoti ?? "")
                                    }
      })
      if let myUser: User = myUser {
        callingInfo = CallingInfo(host: myUser, receive: receiveUser, isHost: true)
        performSegue(withIdentifier: "showRingingSegueId", sender: self)
      }

    }
  }

  // MARK: - SEGUE
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showRingingSegueId" {
      let callingVc = segue.destination as? RingingViewController
      //            callingVc?.socket = self.socket
      callingVc?.callingInfo = self.callingInfo
    }
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return UIStatusBarStyle.lightContent
  }

  @IBAction func unwindToContact(segue: UIStoryboardSegue) { }

}

extension ContactViewController: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    currentLocation = manager.location
  }
}

extension ContactViewController {
  // MARK: - WEB SOCKET DELEGATE
  override func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
    super.webSocket(webSocket, didReceiveMessage: message)
    if let messageString: String = message as? String {
      print(messageString)
      let message: MessageSocket = MessageSocket(message: messageString)
      if message.type == functionDiscovery {
        if let users: [Any] = message.data as? [Any] {
          dataSource.removeAll()
          users.forEach({ (user) in
            if let user = user as? [String: Any] {
              let user = User(data: user)
              if user.name != myName {
                dataSource.append(user)
              } else {
                myUser = user
              }
            }
          })
          dataSourceShow = dataSource
          contactTableView.reloadData()
        }
        return
      }

      if message.type == functionCall {
        if let hostRegId = message.hostRegId,
          let hostName = message.name,
          let myUser = myUser {
          callingInfo = CallingInfo(host: User(name: hostName, regId: hostRegId),
                                    receive: myUser, isHost: false)
        }

        performSegue(withIdentifier: "showRingingSegueId", sender: self)
      }

      if message.type == functionLogin {
        socket?.discovery(completion: { (_, _) in

        })
      }

      if message.type == functionSendEmergencySuccess {
        self.view.makeToast("全ユーザーに緊急通知を送信しました。")
      }
    }
  }

}

extension ContactViewController: UITableViewDataSource {
  // MARK: UITABLEVIEW DATASOURCE
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return dataSourceShow.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "contactCellId", for: indexPath)
      as? ContactTableViewCell else {
        return UITableViewCell()
    }
    cell.updateUser(user: dataSourceShow[indexPath.row])
    cell.selectionStyle = .none
    if indexPath == indexPathSelected {
      cell.backgroundColor = UIColor.lightGray
    } else {
      cell.backgroundColor = UIColor.clear
    }
    return cell
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return Screen.width/5
  }
}

extension ContactViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    indexPathSelected = indexPath
    tableView.reloadData()
    let user = dataSourceShow[indexPath.row]
    print(user.regId)
  }
}
