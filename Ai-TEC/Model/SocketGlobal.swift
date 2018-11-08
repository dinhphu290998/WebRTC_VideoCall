//
//  SocketGlobal.swift
//  Ai-Tec
//
//  Created by Apple on 10/17/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit
import Starscream

class SocketGlobal {

    static let shared: SocketGlobal = SocketGlobal()
    var socket : WebSocket?
    var contacts : [User] = []
    var room: String?
}
