//
//  User.swift
//  Ai-Tec
//
//  Created by Apple on 10/16/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit

typealias DICT = Dictionary<AnyHashable,Any>

class User {
    var name: String = ""
    var regId: String = ""
    var status: Double = 0
    var peer: RTCPeerConnection?
    var mediaStream: RTCMediaStream?
    init?(dict: DICT) {
        guard let name = dict["name"] as? String else {return}
        guard let regId = dict["regId"] as? String else {return}
        guard let status = dict["status"] as? Double else {return}
        self.name = name
        self.regId = regId
        self.status = status
    }
}


