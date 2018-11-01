//
//  Config.swift
//  Ai-Tec
//
//  Created by Apple on 10/16/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit

// MARK: - SERVER INFO
let serverIP = "ws://157.7.209.73:9090"
let urlHostHttp = "http://157.7.209.73/"
let apiSendImage = urlHostHttp + "api/send-image"

// MARK: - FUNCTION TO SERVER
let LOGIN = "login"
let DISCOVERY = "discovery"
let CALL = "call"
let ANSWER = "answer"
let ENDCALL = "endCall"
let DISCONNECT = "disconnect"
let EMERGENCY = "emergency"
let functionSendImageUrl = "sendFile"
let googleMapApiKey =  "AIzaSyBPQJ18bEW0gGU3JANcIF2waD5rigJLdbk"


enum SocketError {
    case success
    case messageEmpty
    case notOpen
    case connectting
    case regIdNil
}
