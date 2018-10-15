//
//  CallingViewController.swift
//  Apprtc
//
//  Created by Hoang Tuan Anh on 12/17/17.
//  Copyright © 2017 Dhilip. All rights reserved.
//

import UIKit
import Material
import AVFoundation
import AudioToolbox
import SocketRocket

class RingingViewController: SocketViewController {

  let commingCallSoundId: SystemSoundID = 1151
  let waitingCallSoundId: SystemSoundID = 1074
  //    var socket: SRWebSocket?
  @IBOutlet weak var callerLabel: UILabel!
  @IBOutlet weak var rejectHostButton: Button!
  @IBOutlet weak var rejectLabel: UILabel!
  @IBOutlet weak var rejectReceiveButton: Button!
  @IBOutlet weak var cancelLabel: UILabel!
  @IBOutlet weak var answerButton: Button!
  @IBOutlet weak var answerLabel: UILabel!
  @IBOutlet weak var searchAnimationImageView: UIImageView!

  var roomId: String?
  var timerSoundAlert: Timer?
  var timerAnimation: Timer?
  // MARK: - LIFE CYCLE
  override func viewDidLoad() {
    super.viewDidLoad()

//    socket?.delegate = self

    if let callingInfo = callingInfo {
      setUI(isHost: callingInfo.isHost)
    }
    setNeedsStatusBarAppearanceUpdate()

  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    if timerAnimation == nil {
      animationSearch()
      timerAnimation = Timer.scheduledTimer(timeInterval: 2, target: self,
                                            selector: #selector(animationSearch), userInfo: nil, repeats: true)
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    timerAnimation?.invalidate()
    timerAnimation = nil
    timerSoundAlert?.invalidate()
    timerSoundAlert = nil
  }

  @objc func animationSearch() {
    UIView.animate(withDuration: 1, animations: {
      self.searchAnimationImageView.transform = CGAffineTransform(scaleX: 4, y: 4)
    }) { (_) in
      UIView.animate(withDuration: 1, animations: {
        self.searchAnimationImageView.transform = CGAffineTransform.identity
      }, completion: nil)

    }
  }

  func setUI(isHost: Bool) {
    rejectHostButton.isHidden = !isHost
    cancelLabel.isHidden = !isHost
    answerButton.isHidden = isHost
    answerLabel.isHidden = isHost
    rejectReceiveButton.isHidden = isHost
    rejectLabel.isHidden = isHost

    if isHost {
      if let callingInfo = callingInfo {
        callerLabel.text = "Calling \(callingInfo.receive.name) ..."
      }
    } else {
      if let callingInfo = callingInfo {
        callerLabel.text = "\(callingInfo.host.name) calling ..."
      }
    }

    timerSoundAlert = Timer.scheduledTimer(timeInterval: 3, target: self,
                                           selector: #selector(playSound), userInfo: nil, repeats: true)
  }

  @objc func playSound() {
    if let callingInfo = callingInfo {
      if callingInfo.isHost {
        AudioServicesPlaySystemSound(waitingCallSoundId)
      } else {
        AudioServicesPlaySystemSound(commingCallSoundId)
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
      }
    }

  }

  @IBAction func answerButtonTouched(_ sender: Any) {
    if let callingInfo = callingInfo {
      let hostRegId: String = callingInfo.host.regId
      let receiveRegId: String = callingInfo.receive.regId
      roomId = Date().ticks
      socket?.answerAccept(host: hostRegId, receive: receiveRegId, roomId: roomId!) { (_, _) in

      }
      performSegue(withIdentifier: "showVideoChatSegueId", sender: self)
    }

    timerSoundAlert?.invalidate()
    timerSoundAlert = nil
  }

  @IBAction func rejectHostButtonTouched(_ sender: Any) {
    if let callingInfo = callingInfo {
      let hostRegId: String = callingInfo.host.regId
      let receiveRegId: String = callingInfo.receive.regId
      socket?.answerReject(host: hostRegId, receive: receiveRegId) { (_, _) in

      }
    }
    //        dismiss(animated: true, completion: nil)
    if let keyWindow = UIApplication.shared.keyWindow,
      let navigationController = keyWindow.rootViewController as? UINavigationController {
      navigationController.popViewController(animated: true)
    }
    timerSoundAlert?.invalidate()
    timerSoundAlert = nil
  }

  @IBAction func rejectReceiveButtonTouched(_ sender: Any) {
    if let callingInfo = callingInfo {
      let hostRegId: String = callingInfo.host.regId
      let receiveRegId: String = callingInfo.receive.regId
      socket?.answerReject(host: receiveRegId, receive: hostRegId) { (_, _) in
      }
    }
    //        dismiss(animated: true, completion: nil)
    if let keyWindow = UIApplication.shared.keyWindow,
      let navigationController = keyWindow.rootViewController as? UINavigationController {
      navigationController.popViewController(animated: true)
    }
    timerSoundAlert?.invalidate()
    timerSoundAlert = nil
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showVideoChatSegueId" {
      let videoChatVc = segue.destination as? RTCVideoChatViewController
      if let roomId: NSString = roomId as NSString? {
        videoChatVc?.roomName = roomId
      }
      //            videoChatVc?.socket = self.socket
      videoChatVc?.callingInfo = self.callingInfo
    }
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return UIStatusBarStyle.lightContent
  }
}

extension RingingViewController {
  // MARK: WEB SOCKET DELEGATE
  override func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
    super.webSocket(webSocket, didReceiveMessage: message)
    print(message)
    if let messageString: String = message as? String {
      let messageSocket = MessageSocket(message: messageString)
      if messageSocket.type == functionAnswer {

        timerSoundAlert?.invalidate()
        timerSoundAlert = nil

        if messageSocket.resultCallSuccess {
          roomId = messageSocket.roomId
          performSegue(withIdentifier: "showVideoChatSegueId", sender: self)
        } else {
          //                    dismiss(animated: true, completion: nil)
          if let keyWindow = UIApplication.shared.keyWindow,
            let navigationController = keyWindow.rootViewController as? UINavigationController {
            navigationController.popViewController(animated: true)
          }
        }
      }
    }
  }
}
