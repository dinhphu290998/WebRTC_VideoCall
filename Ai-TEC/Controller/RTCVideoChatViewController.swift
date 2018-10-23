//
//  RTCVideoChatViewController.swift
//  Ai-Tec
//
//  Created by Nguyễn Đình Phú on 10/22/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit
import WebRTC
import Starscream
import AVFoundation
import AudioToolbox

class RTCVideoChatViewController: UIViewController {
    
    @IBOutlet weak var remoteView: RTCEAGLVideoView?
    @IBOutlet weak var localView: RTCEAGLVideoView?
    @IBOutlet weak var buttonContainerView: UIView?
    @IBOutlet weak var audioButton: UIButton?
    @IBOutlet weak var videoButton: UIButton?
    @IBOutlet weak var hangupButton: UIButton?
    @IBOutlet weak var nameRemoteLabel: UILabel!
    @IBOutlet weak var avatarRemoteImageView: UIImageView!
    @IBOutlet weak var statusRemoteView: UIView!
    @IBOutlet weak var resolutionCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

   

}
