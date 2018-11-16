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
    
    @IBOutlet weak var remoteView: RTCEAGLVideoView!
    @IBOutlet weak var localView: RTCEAGLVideoView!
    @IBOutlet weak var buttonContainerView: UIView?
    @IBOutlet weak var audioButton: UIButton?
    @IBOutlet weak var videoButton: UIButton?
    @IBOutlet weak var hangupButton: UIButton?
    @IBOutlet weak var nameRemoteLabel: UILabel!
    @IBOutlet weak var avatarRemoteImageView: UIImageView!
    @IBOutlet weak var statusRemoteView: UIView!
    @IBOutlet weak var resolutionCollectionView: UICollectionView!
    
    var client: ARDAppClient?
    var nameRemote = ""
    var roomName: NSString?
    var localVideoTrack: RTCVideoTrack?
    var remoteVideoTrack: RTCVideoTrack?
    var localVideoSize: CGSize?
    var remoteVideoSize: CGSize?
    var isZoom: Bool = false;
    var screenShotImage: UIImage?
    let heightCollectionCell = CGFloat((128 - 16)/3)
    let resolutions = ["320 x 240", "640 x 480", "1280 x 720", "1920 x 1080", "2560 x 1440", "3840 x 2160"]
    
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    var captureSession: AVCaptureSession?
    let stillImageOutput = AVCaptureStillImageOutput()
    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var output: AVCaptureMetadataOutput?
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    let cameraOutPut = AVCapturePhotoOutput()
    var takePhoto = false
    
    var captureController: ARDCaptureController = ARDCaptureController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
      self.isZoom = false
      self.audioButton?.layer.cornerRadius = 22.0
      self.videoButton?.layer.cornerRadius = 22.0
      resolutionCollectionView.allowsMultipleSelection = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        remoteView.delegate = self
        localView.delegate = self
        nameRemoteLabel.text = nameRemote
        
        if client == nil {
            client = ARDAppClient(delegate: self)
        }
        
        let settingsModel = ARDSettingsModel()
        if client?.state == ARDAppClientState.disconnected {
            roomName = SocketGlobal.shared.room as NSString?
            client?.connectToRoom(withId: roomName as String?, settings: settingsModel, isLoopback: false, isAudioOnly: false, shouldMakeAecDump: false, shouldUseLevelControl: false)
        }
        SocketGlobal.shared.socket?.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        remoteView.delegate = nil
        localView.delegate = nil
    }
    
    override func viewDidLayoutSubviews() {
        statusRemoteView.layer.cornerRadius = statusRemoteView.frame.width/2
        statusRemoteView.backgroundColor = UIColor.green
        
        avatarRemoteImageView.clipsToBounds = true
        avatarRemoteImageView.layer.borderColor = UIColor.white.cgColor
        avatarRemoteImageView.layer.borderWidth = 2
        avatarRemoteImageView.layer.cornerRadius = avatarRemoteImageView.frame.width/2
        
        avatarRemoteImageView.image = #imageLiteral(resourceName: "ic_launcher")
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.allButUpsideDown
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        self.disconnect()
    }
    
    func orientationChanged(_ notification: Notification) {
        if let localVideoSize = self.localVideoSize {
            self.videoView(self.localView!, didChangeVideoSize: localVideoSize)
        }
        if let remoteVideoSize = self.remoteVideoSize {
            self.videoView(self.remoteView!, didChangeVideoSize: remoteVideoSize)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    @IBAction func audioButtonPressed (_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        self.client?.toggleAudioMute()
        
    }
    @IBAction func videoButtonPressed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        self.client?.toggleVideoMute()
    }

    @IBAction func hangupButtonPressed(_ sender: UIButton) {
        self.disconnect()
        self.performSegue(withIdentifier: "unwindToContactSegue", sender: self)
        let yourName = UserDefaults.standard.value(forKey: "yourname") ?? ""
        let nameRecieve = UserDefaults.standard.value(forKey: "nameRecieve") ?? ""
        let dictEndCall1 = ["type":ENDCALL,"host":"\(yourName)","receive": "\(nameRecieve)"]
        SocketGlobal.shared.socket?.write(string: convertString(from: dictEndCall1))
    }
    // đổi chiều camera
    
    @available(iOS 11.1, *)
    @IBAction func switchCameraButtonTouched(_ sender: UIButton) {
        captureController.switchCamera()
    }
    
    @objc func zoomRemote() {
        //Toggle Aspect Fill or Fit
        self.isZoom = !self.isZoom
        self.videoView(self.remoteView!, didChangeVideoSize: self.remoteVideoSize!)
    }
    
    @objc func updateUIForRotation() {
        let statusBarOrientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
        let deviceOrientation: UIDeviceOrientation  = UIDevice.current.orientation
        if statusBarOrientation.rawValue == deviceOrientation.rawValue {
            if let  localVideoSize = self.localVideoSize {
                self.videoView(self.localView!, didChangeVideoSize: localVideoSize)
            }
            if let remoteVideoSize = self.remoteVideoSize {
                self.videoView(self.remoteView!, didChangeVideoSize: remoteVideoSize)
            }
        } else {
            print("Unknown orientation Skipped rotation")
        }
    }
    
    @IBAction func captureButtonTouched(_ sender: UIButton) {
        if let videoConnection = stillImageOutput.connection(with: AVMediaType.video) {
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection,
                                                             completionHandler: { (imageDataSampleBuffer, _) in
                                                                if let buffer = imageDataSampleBuffer,
                                                                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer) {
                                                                    self.screenShotImage = UIImage(data: imageData)
                                                                    self.performSegue(withIdentifier: "showEditSegueId", sender: self)
                                                                }
            })
        }
    }
  
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

   @IBAction func unwindToVideoChat(segue: UIStoryboardSegue) { }
   
    @IBAction func showAlbumButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "AlbumViewControllerId")
            as? AlbumViewController {
            vc.nameRemote = self.nameRemote
            
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    // convert string to dictionary
    func convertToDictionary(from text: String) throws -> [String: Any]? {
        guard let data = text.data(using: .utf8) else { return [:] }
        let anyResult: Any = try JSONSerialization.jsonObject(with: data, options: [])
        return anyResult as? [String: Any]
    }
    //convert dictionary to string
    func convertString(from dict:[String:String]) -> String {
        let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.prettyPrinted)
        let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
        return jsonString
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEditSegueId" {
            if let editVc = segue.destination as? EditViewController {
                let date = Date()
                UserDefaults.standard.set(Date(), forKey: "hours")
                editVc.screenShotImage = screenShotImage?.addTimestamp(date)
                editVc.nameRemote = nameRemote
    
            }
        }
    }
    
}


extension RTCVideoChatViewController: ARDAppClientDelegate {
    func appClient(_ client: ARDAppClient!, didChange state: ARDAppClientState) {
        switch state {
        case .connected:
            print("Client connected.")
        case .connecting:
            print("Client connecting.")
        case .disconnected:
            print("Client disconnected.")
            self.remoteDisconnected()
        }
    }
    
    func appClient(_ client: ARDAppClient!, didChange state: RTCIceConnectionState) {
    }
    
    func appClient(_ client: ARDAppClient!, didCreateLocalCapturer localCapturer: RTCCameraVideoCapturer!) {
        let settingsModel = ARDSettingsModel()
        captureController = ARDCaptureController(capturer: localCapturer, settings: settingsModel)
        captureController.startCapture()
        if #available(iOS 11.0, *) {
            stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecType.jpeg]
        } else {
            // Fallback on earlier versions
        }
        if localCapturer.captureSession.canAddOutput(stillImageOutput) {
            localCapturer.captureSession.addOutput(stillImageOutput)
        }
    }
    
    func appClient(_ client: ARDAppClient!, didReceiveLocalVideoTrack localVideoTrack: RTCVideoTrack!) {
        self.localVideoTrack?.remove(self.localView!)
        self.localView.renderFrame(nil)
        self.localVideoTrack = localVideoTrack
        self.localVideoTrack?.add(self.localView!)
    }
    
    func appClient(_ client: ARDAppClient!, didReceiveRemoteVideoTrack remoteVideoTrack: RTCVideoTrack!) {
        self.remoteVideoTrack = remoteVideoTrack
        self.remoteVideoTrack?.add(self.remoteView!)
    }
    
    func appClient(_ client: ARDAppClient!, didError error: Error!) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
        self.disconnect()
    }
    func appclient(_ client: ARDAppClient!, didRotateWithLocal localVideoTrack: RTCVideoTrack!,
                   remoteVideoTrack: RTCVideoTrack!) {
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                               selector: #selector(RTCVideoChatViewController.updateUIForRotation),
                                               object: nil)
        // Hack for rotation to get the right video size
        self.perform(#selector(RTCVideoChatViewController.updateUIForRotation), with: nil, afterDelay: 0.2)
    }
    
    
    func appClient(_ client: ARDAppClient!, didGetStats stats: [Any]!) {
    }
    func disconnect() {
        if let client = self.client {
            self.localVideoTrack?.remove(self.localView!)
            self.remoteVideoTrack?.remove(self.remoteView!)
            self.localView?.renderFrame(nil)
            self.remoteView?.renderFrame(nil)
            self.localVideoTrack=nil
            self.remoteVideoTrack=nil
            client.disconnect()
        }
    }
    
    func pause() {
        if self.client != nil {
            self.localVideoTrack?.remove(self.localView!)
            self.remoteVideoTrack?.remove(self.remoteView!)
            self.localView?.renderFrame(nil)
            self.remoteView?.renderFrame(nil)
            self.localVideoTrack=nil
            self.remoteVideoTrack=nil
        }
    }
    

    func remoteDisconnected() {
        self.remoteVideoTrack?.remove(self.remoteView!)
        self.remoteView?.renderFrame(nil)
        if self.localVideoSize != nil {
            self.videoView(self.localView!, didChangeVideoSize: self.localVideoSize!)
        }
        performSegue(withIdentifier: "unwindToContactSegue", sender: self)
    }
    
 
}


extension RTCVideoChatViewController: UICollectionViewDataSource ,UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return resolutions.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "resolutionCellId",
                                                         for: indexPath) as? ResolutionCell {
            cell.resolutionLabel.text = resolutions[indexPath.row]
            return cell
        }
        return UICollectionViewCell()
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(resolutions[indexPath.row])
    }
    
}



extension RTCVideoChatViewController: RTCEAGLVideoViewDelegate{
    func videoView(_ videoView: RTCEAGLVideoView, didChangeVideoSize size: CGSize) {
        print("")
    }
}



extension RTCVideoChatViewController: WebSocketDelegate {
    func websocketDidConnect(socket: WebSocket) {
        print("---Message RTCVideoChatViewController----")
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print(error ?? "")
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        if let messageString: String = text {
            print(messageString)
            let userData = UserDefaults(suiteName: UserDefaults.standard.string(forKey: "yourname"))
            let message: MessageSocket = MessageSocket(message: messageString)
            if message.type == functionSendImageUrl {
                var photosSender = userData?.stringArray(forKey: nameRemote)
                if photosSender == nil {
                    photosSender = []
                }
                if let photo = message.url  {
                    let url = "\(urlHostHttp)data/\(photo)"
                    photosSender?.append(url)
                    userData?.set(photosSender, forKey: nameRemote)
                }
                
                let alert = UIAlertController(title: "お知らせ",
                                              message: "画像を受信しました。確認しますか？\n後でギャラリーにて確認する事も出来ます。",
                                              preferredStyle: .alert)
                let openAction = UIAlertAction(title: "開く", style: .default, handler: { (_) in
                    
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let vc = storyboard.instantiateViewController(withIdentifier: "AlbumViewControllerId")
                        as? AlbumViewController {
                        vc.nameRemote = self.nameRemote
                        
                        self.present(vc, animated: true, completion: nil)
                    }
                })
                
                let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
                alert.addAction(openAction)
                alert.addAction(cancelAction)
                
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print(data)
    }
    
    
}


