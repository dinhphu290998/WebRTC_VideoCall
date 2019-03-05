//
//  Config.swift
//  Ai-Tec
//
//  Created by Apple on 10/16/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit

// MARK: - SERVER INFO
let serverIP = "ws://157.7.211.84:9090"
let urlHostHttp = "ws://157.7.211.84:9090"
let urlKurento = "https://aitec-stg.aimap.jp:4443/openvidu"
let apiSendImage = "https://aimap.dock.miosys.vn/api/v1/chat/upload-image"

// MARK: - FUNCTION TO SERVER
let LOGIN = "login"
let DISCOVERY = "discovery"
let CALL = "call"
let ANSWER = "answer"
let ENDCALL = "endCall"
let DISCONNECT = "disconnect"
let EMERGENCY = "emergency"
let functionSendImageUrl = "sendFile"

enum SocketError {
    case success
    case messageEmpty
    case notOpen
    case connectting
    case regIdNil
}
