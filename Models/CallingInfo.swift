//
//  CallingInfo.swift
//  Apprtc
//
//  Created by vmio69 on 2/1/18.
//  Copyright © 2018 Dhilip. All rights reserved.
//

import UIKit

class CallingInfo: NSObject {
  private(set) var host: User
  private(set) var receive: User
  private(set) var isHost: Bool

  init(host: User, receive: User, isHost: Bool) {
    self.host = host
    self.receive = receive
    self.isHost = isHost
  }
}
