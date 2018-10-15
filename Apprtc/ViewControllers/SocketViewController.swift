//
//  SocketViewController.swift
//  Apprtc
//
//  Created by Hoang Tuan Anh on 12/17/17.
//  Copyright © 2017 Dhilip. All rights reserved.
//

import UIKit
import SocketRocket
import MobileCoreServices
import SVProgressHUD
import MapKit
import Whisper
import UserNotifications

class SocketViewController: UIViewController {

  var callingInfo: CallingInfo?

  var socket: SRWebSocket?

  override func viewDidLoad() {
    super.viewDidLoad()
    socket = Socket.shared
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

//    openSocket()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    openSocket()
  }

  @objc func openSocket() {
    socket?.delegate = self
    if socket?.readyState != SRReadyState.CONNECTING && socket?.readyState != SRReadyState.OPEN {
      socket?.open()
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    socket?.delegate = nil
    DispatchQueue.main.async {
      SVProgressHUD.dismiss()
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  public func addInfoToEXIF(old: NSDictionary, gps: NSDictionary?, dateCapture: Date?) -> NSDictionary {
    if let gps = gps {
      old.setValue(gps, forKey: kCGImagePropertyGPSDictionary as String)
    }

    if let exifData = old.value(forKey: kCGImagePropertyExifDictionary as String) as? NSDictionary,
      let timestampCapture = dateCapture {
      let dfExif = DateFormatter()
      dfExif.locale = Locale(identifier: "en_POSIX_US")
      dfExif.timeZone = TimeZone.current
      dfExif.dateFormat = "yyyy:MM:dd HH:mm:ss"

      exifData.setValue(dfExif.string(from: timestampCapture),
                        forKey: kCGImagePropertyExifDateTimeOriginal as String)
      exifData.setValue(dfExif.string(from: timestampCapture),
                        forKey: kCGImagePropertyExifDateTimeDigitized as String)

      old.setValue(exifData, forKey: kCGImagePropertyExifDictionary as String)
    }

    if let exifData = old.value(forKey: kCGImagePropertyTIFFDictionary as String) as? NSDictionary,
      let timestampCapture = dateCapture {
      let dfExif = DateFormatter()
      dfExif.locale = Locale(identifier: "en_POSIX_US")
      dfExif.timeZone = TimeZone.current
      dfExif.dateFormat = "yyyy:MM:dd HH:mm:ss"

      exifData.setValue(dfExif.string(from: timestampCapture),
                        forKey: kCGImagePropertyTIFFDateTime as String)

      old.setValue(exifData, forKey: kCGImagePropertyTIFFDictionary as String)
    }

    return old
  }

  public func getEXIFFromImage(image: Data) -> NSDictionary {
    if let imageSourceRef = CGImageSourceCreateWithData(image as CFData, nil),
      let currentProperties = CGImageSourceCopyPropertiesAtIndex(imageSourceRef, 0, nil) {
      let mutableDict = NSMutableDictionary(dictionary: currentProperties)
      return mutableDict
    }
    return NSDictionary()
  }

  public func attachEXIFToImage(image: NSData, EXIF: NSDictionary) -> NSData {
    if let imageDataProvider = CGDataProvider(data: image),
      let imageRef = CGImage(jpegDataProviderSource: imageDataProvider,
                             decode: nil, shouldInterpolate: true,
                             intent: CGColorRenderingIntent.defaultIntent),
      let newImageData = CFDataCreateMutable(nil, 0),
      let type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType,
                                                       "image/jpg" as CFString, kUTTypeImage),
      let destination = CGImageDestinationCreateWithData(newImageData,
                                                         type.takeRetainedValue(), 1, nil) {
      CGImageDestinationAddImage(destination, imageRef, EXIF as CFDictionary)
      CGImageDestinationFinalize(destination)
      return newImageData as NSData
    }

    return NSData()
  }

}

extension SocketViewController: SRWebSocketDelegate {
  func webSocketDidOpen(_ webSocket: SRWebSocket!) {
    print("socket did open")
    if let name: String = UserDefaults.standard.value(forKey: "username") as? String,
      let password: String = UserDefaults.standard.value(forKey: "password") as? String {
      //            print(name, password)
      socket?.login(name: name, password: password, completion: { (error, _) in
        if error == SocketError.success {
          socket?.discovery(completion: { (error, _) in
            if error == SocketError.notOpen && socket?.readyState != SRReadyState.CONNECTING {
              openSocket()
            }
          })
        }
        if error == SocketError.notOpen {
          openSocket()
        }
      })
    }
  }

  func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
    //        print("socket message: \(message)")
    if let messageString: String = message as? String {
      print(messageString)
      let message: MessageSocket = MessageSocket(message: messageString)
      if message.type == functionDisconnect {
        if let user: String = UserDefaults.standard.value(forKey: "username") as? String,
          user != message.user {
          return
        }
        UserDefaults.standard.set(nil, forKey: "username")
        UserDefaults.standard.set(nil, forKey: "password")
        //                self.dismiss(animated: true, completion: nil)
        if let keyWindow = UIApplication.shared.keyWindow,
          let navigationController = keyWindow.rootViewController as? UINavigationController {
          navigationController.popViewController(animated: true)
        }
        return
      }
      if message.type == functionSendEmergency {

        var alertBodyDateTime = "n/a"
        var alertBodyLocation = "n/a"
        var alertBody = ""

        if let dateTime = message.dateTimeString {
          alertBodyDateTime = dateTime
        }
        if let latitude = message.location?.coordinate.latitude,
          let longitude = message.location?.coordinate.longitude {
          alertBodyLocation = "\(latitude)、\(longitude)"
        }
        alertBody = "発信日時は\(alertBodyDateTime)、発信場所は \(alertBodyLocation) です。"
        let alert = UIAlertController(title: "\(message.userId ?? "")からの緊急通知を受信しました。",
          message: alertBody,
          preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        let openMap = UIAlertAction(title: "Map", style: .default, handler: { (_) in
          if let coordinate = message.location?.coordinate {
            let regionDistance: CLLocationDistance = 1000
            let regionSpan = MKCoordinateRegionMakeWithDistance(coordinate, regionDistance, regionDistance)
            let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
                           MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)]
            let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.openInMaps(launchOptions: options)
          } else {

          }
        })
        alert.addAction(ok)
        alert.addAction(openMap)
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)

        //                if UIApplication.shared.applicationState == .background
        //                    || UIApplication.shared.applicationState == .active {
        //                    let localNoti = UILocalNotification()
        //                    localNoti.alertTitle = "\(message.userId ?? "")からの緊急通知を受信しました。"
        //                    var alertBodyDateTime = "n/a"
        //                    var alertBodyLocation = "n/a"
        //                    var alertBody = ""
        //
        //                    if let dateTime = message.dateTimeString {
        //                        alertBodyDateTime = dateTime
        //                    }
        //                    if let latitude = message.location?.coordinate.latitude,
        //                        let longitude = message.location?.coordinate.longitude {
        //                        alertBodyLocation = "\(latitude)、\(longitude)"
        //                    }
        //                    alertBody = "発信日時は\(alertBodyDateTime)、発信場所は \(alertBodyLocation) です。"
        //                    localNoti.alertBody = alertBody
        //                    localNoti.soundName = UILocalNotificationDefaultSoundName
        //                    UIApplication.shared.presentLocalNotificationNow(localNoti)
        //                }

      }
      let userData = UserDefaults(suiteName: UserDefaults.standard.string(forKey: "username"))

      if message.type == functionSendImageUrl {
        if let callingInfo = callingInfo {
          let userSender = callingInfo.isHost ? callingInfo.receive.name : callingInfo.host.name
          var photosSender = userData?.stringArray(forKey: userSender)
          if photosSender == nil {
            photosSender = []
          }
          if let photo = message.url {
            let url = "\(urlHostHttp)data/\(photo)"
            photosSender?.append(url)
            userData?.set(photosSender, forKey: userSender)
          }

          let alert = UIAlertController(title: "お知らせ",
                                        message: "画像を受信しました。確認しますか？\n後でギャラリーにて確認する事も出来ます。",
                                        preferredStyle: .alert)
          let openAction = UIAlertAction(title: "開く", style: .default, handler: { (_) in
            //                        self.performSegue(withIdentifier: "showAlbumSegueId", sender: self)
            if self is AlbumViewController {
              if let vc = self as? AlbumViewController {
                vc.albumCollectionView.reloadData()
              }
              return
            }
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "AlbumViewControllerId")
              as? AlbumViewController {
              vc.callingInfo = self.callingInfo
              self.present(vc, animated: true, completion: nil)
            }
          })
          let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
          alert.addAction(openAction)
          alert.addAction(cancelAction)

          present(alert, animated: true, completion: nil)
        }
      }
    }
  }

  func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
    print("socket closed reason: \(reason)")
    openSocket()
  }

  func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
    print("socket did fail with error: \(error.localizedDescription)")
  }
}
