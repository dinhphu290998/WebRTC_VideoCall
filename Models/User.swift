//
//  User.swift
//  Apprtc
//
//  Created by vmio69 on 12/14/17.
//  Copyright © 2017 Dhilip. All rights reserved.
//

import UIKit

class User: NSObject {
  private(set) var name: String = ""
  private(set) var regId: String = ""
  private(set) var status: String = ""

  init(data: [String: Any]) {
    if let name: String = data["name"] as? String {
      self.name = name
    }
    if let regId: String = data["regId"] as? String {
      self.regId = regId
    }
    self.status = String(describing: data["status"] ?? "")
  }

  init(name: String, regId: String, status: String = "") {
    self.name = name
    self.regId = regId
    self.status = status
  }
}
