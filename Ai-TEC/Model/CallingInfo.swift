//
//  CallingInfo.swift
//  Apprtc
//
//  Created by vmio69 on 2/1/18.
//  Copyright © 2018 Dhilip. All rights reserved.
//

import UIKit
import Starscream
class CallingInfo: UIViewController, WebSocketDelegate {
    func websocketDidConnect(socket: WebSocket) {
        print("")
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print(error)
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
     
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print(data)
    }
    

}
