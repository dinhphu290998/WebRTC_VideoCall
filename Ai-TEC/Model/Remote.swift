//
//  Remote.swift
//  Ai-Tec
//
//  Created by Nguyễn Đình Phú on 1/10/19.
//  Copyright © 2019 vMio. All rights reserved.
//

import UIKit

class Remote {
    var nameRemote: String?
    var regIdRemote: String?
    var remotePeer: RTCPeerConnection?
    var remoteMedia: RTCMediaStream?
    var arrIceCandidate: [RTCIceCandidate]?
    init(name:String,id:String,peer:RTCPeerConnection?,media:RTCMediaStream?,arrIce: [RTCIceCandidate]?){
        self.nameRemote = name
        self.regIdRemote = id
        self.remotePeer = peer
        self.remoteMedia = media
        self.arrIceCandidate = arrIce
    }
}

