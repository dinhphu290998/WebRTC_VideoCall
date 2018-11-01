//
//  MessageSocket.swift
//  Apprtc
//
//  Created by vmio69 on 12/14/17.
//  Copyright © 2017 Dhilip. All rights reserved.
//

import UIKit
import SwiftyJSON
import CoreLocation

class MessageSocket: NSObject {

  private(set) var type: String = ""
  private(set) var isSuccess: Bool = false
  private(set) var message: String = ""
  private(set) var data: Any?
  private(set) var hostRegId: String?
  private(set) var receiveRegId: String?
  private(set) var name: String?
  private(set) var resultCallSuccess: Bool = false
  private(set) var roomId: String?
  private(set) var url: String?
  private(set) var user: String?
  private(set) var dateTime: Date?
  private(set) var dateTimeString: String?
  private(set) var location: CLLocation?
  private(set) var userId: String?

  init(message: String) {
    if let data: Dictionary = message.dictionary {
      if let type: String = data["type"] as? String {
        self.type = type
      }
      if let status: String = data["status"] as? String {
        self.isSuccess = status.lowercased() == "success" ? true : false
      }
      if let message: String = data["message"] as? String {
        self.message = message
      }
      if let url: String = data["url"] as? String {
        self.url = url
      }
      if let data: Any = data["data"] {
        self.data = data
      }
      if let hostRegId: String = data["host"] as? String {
        self.hostRegId = hostRegId
      }
      if let receiveRegId: String = data["receive"] as? String {
        self.receiveRegId = receiveRegId
      }
      if let name: String = data["name"] as? String {
        self.name = name
      }
      if let resultCall: String = data["result"] as? String {
        if resultCall == "success" {
          resultCallSuccess = true
        } else {
          resultCallSuccess = false
        }
      }
      if let roomId: String = data["room"] as? String {
        self.roomId = roomId
      }
      if let user: String = data["user"] as? String {
        self.user = user
      }

      if let timestamp: String = data["dateTime"] as? String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        dateTime = dateFormatter.date(from: timestamp)
        dateFormatter.locale = Locale(identifier: "ja_JP")
        if let dateTime = dateTime {
          dateTimeString = dateFormatter.string(from: dateTime)
        }
      }
      if let latitude: String = data["latitude"] as? String,
        let longitude: String = data["longitude"] as? String,
        let lat: Double = Double(latitude),
        let long: Double = Double(longitude) {
        location = CLLocation(latitude: lat, longitude: long)
      }

      if let userId: String = data["userId"] as? String {
        self.userId = userId
      }
    }
  }

}
