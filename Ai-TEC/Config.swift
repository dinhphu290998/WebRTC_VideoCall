//
//  Config.swift
//  Apprtc
//
//  Created by vmio69 on 12/12/17.
//  Copyright © 2017 Dhilip. All rights reserved.
//

import UIKit

// MARK: - SERVER INFO
let urlHostHttp = "http://157.7.209.73/"
let apiSendImage = urlHostHttp + "api/send-image"
let urlHostRtc = "ws://157.7.209.73:9090"
let port = 9090
let pushExtraLongitude = "1"
let pushExtraLatitude = "2"
let pushBooleanService = "3"

// MARK: - FUNCTION TO SERVER
let functionLogin = "login"
let functionDiscovery = "discovery"
let functionCall = "call"
let functionAnswer = "answer"
let functionEndCall = "endCall"
let functionDisconnect = "disconnect"
let functionSendImageUrl = "sendFile"
let functionSendEmergency = "emergency"
let functionSendEmergencySuccess = "emergencySuccess"
let functionErrorConnect = "errorConnectToServer"
let functionIsViewImage = "view"

// MARK: - SIGNAL SETTING
let oneSignalAppVoipId = "8fc5192f-05f6-4a8d-be7d-175326465cfb"
let oneSignalApiVoipKey = "ZDU5OGRkMWMtOGJhZS00ODdkLWFhMmUtNDYwODc0ZGZiZTli"
let oneSignalAppNotiId = "e286319a-4a99-4c32-b9f7-4abd5dbcadf6"
let oneSignalApiNotiKey = "ZTRiY2Y5MmEtOTkyNS00OGNhLWFjZDktZjIyZTZjZWE1NjBm"
let oneSignalApiAddDevice = "https://onesignal.com/api/v1/players"
let oneSignalApiSendNotification = "https://onesignal.com/api/v1/notifications"

// MARK: - ENUM
enum SocketError {
  case success
  case messageEmpty
  case notOpen
  case connectting
  case regIdNil
}

let googleMapApiKey =  "AIzaSyBPQJ18bEW0gGU3JANcIF2waD5rigJLdbk"
