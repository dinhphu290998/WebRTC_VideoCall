//
//  Extension.swift
//  Apprtc
//
//  Created by vmio69 on 12/13/17.
//  Copyright © 2017 Dhilip. All rights reserved.
//

import UIKit
import SocketRocket
import Material
import CoreLocation

extension SRWebSocket {

  private func sendMessage(_ params: NSDictionary,
                           completion: (_ socketError: SocketError, _ message: String) -> Void) {
    let message = params.jsonString
    if message == "" {
      print("message is empty")
      completion(.messageEmpty, "message is empty")
      return
    }

    if self.readyState == SRReadyState.OPEN {
      self.send(message)
      completion(.success, "success")
    } else {
      print("socket is not open! can't send.")
      if self.readyState == SRReadyState.CONNECTING {
        completion(.connectting, "socket is not open! can't send")
      } else {
        completion(.notOpen, "socket is not open! can't send")
      }
    }
    return
  }

  func login(name: String, password: String, completion: (_ socketError: SocketError, _ message: String) -> Void) {
    if let uuid: String = UserDefaults.standard.value(forKey: "regId") as? String {
      let params: NSDictionary = ["type": functionLogin, "name": name, "password": password, "regId": uuid]
      sendMessage(params, completion: { (socketError, message) in
        completion(socketError, message)
      })
    } else {
      print("RegId can't nil. Try again")
      completion(.regIdNil, "RegId can't nil. Try again")
    }
    return
  }

  func discovery(completion: (_ socketError: SocketError, _ message: String) -> Void) {
    let params: NSDictionary = ["type": functionDiscovery, "regId": UUID().uuidString.lowercased()]
    sendMessage(params) { (socketError, message) in
      completion(socketError, message)
    }
  }

  func call(host: String, receive: String, name: String,
            completion: (_ socketError: SocketError, _ message: String) -> Void) {
    let params: NSDictionary = ["type": functionCall, "host": host, "receive": receive, "name": name]
    sendMessage(params) { (socketError, message) in
      completion(socketError, message)
    }
  }

  private func answer(host: String, receive: String, result: String, roomId: String?,
                      completion: (_ socketError: SocketError, _ message: String) -> Void) {
    var params: NSDictionary
    if let roomId = roomId {
      params = ["type": functionAnswer, "host": host, "receive": receive, "result": result, "room": roomId]
    } else {
      params = ["type": functionAnswer, "host": host, "receive": receive, "result": result]
    }
    sendMessage(params) { (socketError, message) in
      completion(socketError, message)
    }
  }

  func answerAccept(host: String, receive: String, roomId: String,
                    completion: (_ socketError: SocketError, _ message: String) -> Void) {
    answer(host: host, receive: receive, result: "success", roomId: roomId) { (socketError, message) in
      completion(socketError, message)
    }
  }

  func answerReject(host: String, receive: String,
                    completion: (_ socketError: SocketError, _ message: String) -> Void) {
    answer(host: host, receive: receive, result: "reject", roomId: nil) { (socketError, message) in
      completion(socketError, message)
    }
  }

  func endCall(host: String, receive: String,
               completion: (_ socketError: SocketError, _ message: String) -> Void) {
    let params: NSDictionary = ["type": functionEndCall, "host": host, "receive": receive]
    sendMessage(params) { (socketError, message) in
      completion(socketError, message)
    }
  }

  func logout(completion: (_ socketError: SocketError, _ message: String) -> Void) {
    let params: NSDictionary = ["type": functionDisconnect]
    sendMessage(params) { (socketError, message) in
      completion(socketError, message)
    }
  }

  func emergency(regId: String, name: String, latitude: String, longitude: String,
                 completion: (_ socketError: SocketError, _ message: String) -> Void) {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
    let params: NSDictionary = ["type": functionSendEmergency, "regId": regId, "name": name,
                                "dateTime": formatter.string(from: Date()),
                                "latitude": latitude, "longitude": longitude]
    sendMessage(params) { (socketError, message) in
      completion(socketError, message)
    }
  }

  func sendImage(regId: String, image: String, completion: (_ socketError: SocketError, _ message: String) -> Void) {
    let params: NSDictionary = ["type": functionSendImageUrl, "receive": regId, "url": image]
    sendMessage(params) { (error, message) in
      completion(error, message)
    }
  }
}

extension NSDictionary {
  var jsonString: String {
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: self,
                                                options: JSONSerialization.WritingOptions(rawValue: 0))
      if let str: String = String(data: jsonData, encoding: .utf8) {
        return str
      }
      return ""
    } catch let error {
      print(error)
      return ""
    }
  }
}

extension String {
  var dictionary: [String: Any]? {
    if let data = self.data(using: .utf8) {
      do {
        return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
      } catch let error {
        print(error.localizedDescription)
      }
    }
    return nil
  }

}

extension UIViewController {
  func autoHideKeyboard() {
    let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                             action: #selector(UIViewController.dismissKeyboard))
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)
  }
  @objc func dismissKeyboard() {
    view.endEditing(true)
  }
}

extension TextField {
  //    override open func textRect(forBounds bounds: CGRect) -> CGRect {
  //        return UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake(0, 8, 0, 8))
  //    }
  //
  //    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
  //        return UIEdgeInsetsInsetRect(bounds, UIEdgeInsetsMake(0, 8, 0, 8))
  //    }
}

extension UIImageView {
  func setRandomDownloadImage(_ width: Int, height: Int) {
    if self.image != nil {
      self.alpha = 1
      return
    }
    self.alpha = 0
    let url = URL(string: "http://lorempixel.com/\(width)/\(height)/")!
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 15
    configuration.timeoutIntervalForResource = 15
    configuration.requestCachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData
    let session = URLSession(configuration: configuration)
    let task = session.dataTask(with: url) { (data, response, error) in
      if error != nil {
        return
      }

      if let response = response as? HTTPURLResponse {
        if response.statusCode / 100 != 2 {
          return
        }
        if let data = data, let image = UIImage(data: data) {
          DispatchQueue.main.async(execute: { () -> Void in
            self.image = image
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
              self.alpha = 1
            }, completion: { (_: Bool) -> Void in
            })
          })
        }
      }
    }
    task.resume()
  }

}

extension UIImage {
  func addTimestamp(_ date: Date) -> UIImage {
    let textColor = UIColor.yellow
    let textFont = UIFont(name: "Helvetica Bold", size: 14)!
    let point = CGPoint(x: 10, y: self.size.height-16)
    let scale = UIScreen.main.scale

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
    let timestamp = formatter.string(from: date)

    UIGraphicsBeginImageContextWithOptions(self.size, false, scale)

    let textFontAttributes = [
      NSAttributedStringKey.font: textFont,
      NSAttributedStringKey.foregroundColor: textColor,
      NSAttributedStringKey.backgroundColor: UIColor.gray
      ] as [NSAttributedStringKey: Any]
    self.draw(in: CGRect(origin: CGPoint.zero, size: self.size))

    let rect = CGRect(origin: point, size: self.size)
    timestamp.draw(in: rect, withAttributes: textFontAttributes)

    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage!
  }
}

extension Date {
  var ticks: String {
    return String(Int64(self.timeIntervalSince1970))
  }

  var fileNameFromeDate: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd_HHmmss"
    return formatter.string(from: self)
  }
}

extension UIView {
  func takeScreenShot() -> UIImage {
    UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
    drawHierarchy(in: bounds, afterScreenUpdates: true)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
  }
}

extension FileManager {
  func clearTmpDirectory() {
    do {
      let tmpDirUrl = try FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory())
      try tmpDirUrl.forEach({ (file) in
        let fileUrl = String(format: "%@%@", NSTemporaryDirectory(), file)
        try FileManager.default.removeItem(atPath: fileUrl)
      })
    } catch {
      print(error)
    }
  }
}

extension CLLocation {
  func getGPSDictionary() -> NSDictionary {
    let gps = NSMutableDictionary()

    // GPS tag version
    gps.setObject("2.2.0.0", forKey: kCGImagePropertyGPSVersion as NSString)

    // Time and date must be provided as strings
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSSSSS"
    formatter.timeZone = TimeZone(abbreviation: "UTC")
    gps[kCGImagePropertyGPSTimeStamp as NSString] = formatter.string(from: self.timestamp)
    formatter.dateFormat = "yyyy:MM:dd"
    gps[kCGImagePropertyGPSDateStamp as NSString] = formatter.string(from: self.timestamp)

    // Latitude
    let latitude = self.coordinate.latitude
    gps[kCGImagePropertyGPSLatitudeRef as NSString] = (latitude < 0) ? "S" : "N"
    gps[kCGImagePropertyGPSLatitude as NSString] = fabs(latitude)

    // Longitude
    let longitude = self.coordinate.longitude
    gps[kCGImagePropertyGPSLongitudeRef as NSString] = (longitude < 0) ? "W" : "E"
    gps[kCGImagePropertyGPSLongitude as NSString] = fabs(longitude)

    // Degree of Precision
    gps[kCGImagePropertyGPSDOP as NSString] = self.horizontalAccuracy

    // Altitude
    let altitude = self.altitude
    if !altitude.isNaN {
      gps[kCGImagePropertyGPSAltitudeRef as NSString] = (altitude < 0) ? 1 : 0
      gps[kCGImagePropertyGPSAltitude as NSString] = fabs(altitude)
    }

    // Speed, must be converted from m/s to km/h
    if self.speed >= 0 {
      gps[kCGImagePropertyGPSSpeedRef as NSString] = "K"
      gps[kCGImagePropertyGPSSpeed as NSString] = self.speed * 3.6
    }

    // Heading, Direction of movement
    if self.course >= 0 {
      gps[kCGImagePropertyGPSTrackRef as NSString] = "T"
      gps[kCGImagePropertyGPSTrack as NSString] = self.course
    }

    return gps
  }
}

extension URL {
  var timestampCaptured: String? {
    let fileName = self.deletingPathExtension().lastPathComponent
    let partsOfName = fileName.components(separatedBy: "_")
    if partsOfName.count > 2 {
      var timestampString = "\(partsOfName[1])_\(partsOfName[2])"
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyyMMdd_HHmmss"
      if let date = formatter.date(from: timestampString) {
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        timestampString = formatter.string(from: date)
        return timestampString
      }
    }

    return nil
  }
}
