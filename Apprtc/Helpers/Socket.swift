//
//  Socket.swift
//  Apprtc
//
//  Created by vmio69 on 3/1/18.
//  Copyright © 2018 Dhilip. All rights reserved.
//

import UIKit
import SocketRocket

class Socket {
  static var shared: SRWebSocket = {
    let socket = SRWebSocket(url: URL(string: urlHostRtc))
    socket?.open()
    return socket!
  }()
}
