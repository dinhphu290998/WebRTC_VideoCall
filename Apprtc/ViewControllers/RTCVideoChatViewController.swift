//
//  RTCVideoChatViewController.swift
//  Apprtc
//
//  Created by Mahabali on 9/6/15.
//  Copyright (c) 2015 Mahabali. All rights reserved.
//

import UIKit
import AVFoundation
import WebRTC
import SocketRocket
import Material

class RTCVideoChatViewController: SocketViewController {
  //Views, Labels, and Buttons
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

  var client: ARDAppClient?
  var roomName: NSString?
  var localVideoTrack: RTCVideoTrack?
  var remoteVideoTrack: RTCVideoTrack?
  var localVideoSize: CGSize?
  var remoteVideoSize: CGSize?
  var isZoom: Bool = false; //used for double tap remote view
  var captureController: ARDCaptureController = ARDCaptureController()

  var screenShotImage: UIImage?
  let widthCollectionCell = (min(Screen.width, Screen.height) - 32 - 101)/2
  let heightCollectionCell = CGFloat((128 - 16)/3)
  let stillImageOutput = AVCaptureStillImageOutput()
  let userData = UserDefaults(suiteName: UserDefaults.standard.string(forKey: "username"))
  let resolutions = ["320 x 240", "640 x 480", "1280 x 720", "1920 x 1080", "2560 x 1440", "3840 x 2160"]
  // MARK: - LIFE CYCLE
  override func viewDidLoad() {
    super.viewDidLoad()
    self.isZoom = false
    self.audioButton?.layer.cornerRadius = 22.0
    self.videoButton?.layer.cornerRadius = 22.0
    //        NotificationCenter.default
    //            .addObserver(self,
    //                         selector: #selector(RTCVideoChatViewController.orientationChanged(_:)),
    //                         name: NSNotification.Name(rawValue: "UIDeviceOrientationDidChangeNotification"),
    //                         object: nil)
//    socket?.delegate = self
    resolutionCollectionView.allowsMultipleSelection = false
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationController?.setNavigationBarHidden(true, animated: true)
    remoteView?.delegate = self
    localView?.delegate = self

    if client == nil {
      client = ARDAppClient(delegate: self)
    }
    //self.client?.serverHostUrl="https://apprtc.appspot.com"
    let settingsModel = ARDSettingsModel()
    if client?.state == ARDAppClientState.disconnected {
      client!.connectToRoom(withId: self.roomName! as String!,
                            settings: settingsModel, isLoopback: false, isAudioOnly: false,
                            shouldMakeAecDump: false, shouldUseLevelControl: false)
    }
    if let callingInfo = callingInfo {
      nameRemoteLabel.text = callingInfo.isHost ? callingInfo.host.name : callingInfo.receive.name
    }
  }

  override func  viewWillDisappear(_ animated: Bool) {
    //        NotificationCenter.default.removeObserver(self)
    remoteView?.delegate = nil
    localView?.delegate = nil
  }

  override func viewDidLayoutSubviews() {
    statusRemoteView.layer.cornerRadius = statusRemoteView.frame.width/2
    statusRemoteView.backgroundColor = UIColor.green

    avatarRemoteImageView.clipsToBounds = true
    avatarRemoteImageView.layer.borderColor = UIColor.white.cgColor
    avatarRemoteImageView.layer.borderWidth = 2
    avatarRemoteImageView.layer.cornerRadius = avatarRemoteImageView.frame.width/2
//    avatarRemoteImageView.setRandomDownloadImage(Int(avatarRemoteImageView.frame.width),
//                                                 height: Int(avatarRemoteImageView.frame.height))
    avatarRemoteImageView.image = #imageLiteral(resourceName: "ic_launcher")
  }

  override var  shouldAutorotate: Bool {
    return true
  }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return UIInterfaceOrientationMask.allButUpsideDown
  }

  func applicationWillResignActive(_ application: UIApplication) {
    self.disconnect()
  }

  @objc func orientationChanged(_ notification: Notification) {
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

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  // MARK: - USER EVENTS
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
    if let callingInfo = callingInfo {
      let hostRegId: String = callingInfo.host.regId
      let receiveRegId: String = callingInfo.receive.regId
      socket?.endCall(host: hostRegId, receive: receiveRegId) { (_, _) in
      }
      socket?.endCall(host: receiveRegId, receive: hostRegId) { (_, _) in
      }
    }
    self.performSegue(withIdentifier: "unwindToContactSegueId", sender: self)

  }
  @IBAction func switchCameraButtonTouched(_ sender: Any) {
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

  @IBAction func handlePinch(_ sender: UIPinchGestureRecognizer) {
    print(sender.scale)
  }

  @IBAction func captureButtonTouched(_ sender: Any) {
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

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showEditSegueId" {
      if let editVc = segue.destination as? EditViewController {
        let date = Date()
        editVc.timestampCapture = date
        editVc.screenShotImage = screenShotImage?.addTimestamp(date)
        editVc.callingInfo = callingInfo
      }
    } else if segue.identifier == "showAlbumSegueId" {
      if let albumVc = segue.destination as? AlbumViewController {
        albumVc.callingInfo = callingInfo
      }
    }
  }
}

extension RTCVideoChatViewController: ARDAppClientDelegate {
  // MARK: - ARD APP CLIENT DELEGATE
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

  public func appClient(_ client: ARDAppClient!, didError error: Error!) {
    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
    let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
    alert.addAction(cancelAction)
    present(alert, animated: true, completion: nil)
    self.disconnect()
  }

  func appClient(_ client: ARDAppClient!, didReceiveLocalVideoTrack localVideoTrack: RTCVideoTrack!) {
    self.localVideoTrack?.remove(self.localView!)
    self.localView?.renderFrame(nil)
    self.localVideoTrack = localVideoTrack
    self.localVideoTrack?.add(self.localView!)
  }

  public func appClient(_ client: ARDAppClient!, didCreateLocalCapturer localCapturer: RTCCameraVideoCapturer!) {
    let settingsModel = ARDSettingsModel()
    captureController = ARDCaptureController(capturer: localCapturer, settings: settingsModel)
    captureController.startCapture()
    stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
    if localCapturer.captureSession.canAddOutput(stillImageOutput) {
      localCapturer.captureSession.addOutput(stillImageOutput)
    }
  }

  func appClient(_ client: ARDAppClient!, didReceiveRemoteVideoTrack remoteVideoTrack: RTCVideoTrack!) {
    self.remoteVideoTrack = remoteVideoTrack
    self.remoteVideoTrack?.add(self.remoteView!)
  }

  func appclient(_ client: ARDAppClient!, didRotateWithLocal localVideoTrack: RTCVideoTrack!,
                 remoteVideoTrack: RTCVideoTrack!) {
    NSObject.cancelPreviousPerformRequests(withTarget: self,
                                           selector: #selector(RTCVideoChatViewController.updateUIForRotation),
                                           object: nil)
    // Hack for rotation to get the right video size
    self.perform(#selector(RTCVideoChatViewController.updateUIForRotation), with: nil, afterDelay: 0.2)
  }

  public func appClient(_ client: ARDAppClient!, didGetStats stats: [Any]!) {
  }

  public func appClient(_ client: ARDAppClient!, didChange state: RTCIceConnectionState) {
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
    performSegue(withIdentifier: "unwindToContactSegueId", sender: self)
  }
}

extension RTCVideoChatViewController: RTCEAGLVideoViewDelegate {
  // MARK: - RTC EGL VIDEO VIEW DELEGATE
  func videoView(_ videoView: RTCEAGLVideoView, didChangeVideoSize size: CGSize) {
    print("video size: \(size)")
  }
}

extension RTCVideoChatViewController {
  // MARK: - SR WEB SOCKET DELEGATE
  override func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
    super.webSocket(webSocket, didReceiveMessage: message)
    print(message)
    if let messageString: String = message as? String {
      let messageSocket = MessageSocket(message: messageString)
      if messageSocket.type == functionEndCall {
        performSegue(withIdentifier: "unwindToContactSegueId", sender: self)
      }
    }
  }
}

extension RTCVideoChatViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}

extension RTCVideoChatViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 6
  }

  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "resolutionCellId",
                                                     for: indexPath) as? ResolutionCell {
      cell.setResolution(resolution: resolutions[indexPath.item])
      return cell
    }
    return UICollectionViewCell()
  }
}

extension RTCVideoChatViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let setting = ARDSettingsModel()
    setting.storeVideoResolutionSetting(resolutions[indexPath.item].trimmed)
  }
}

extension RTCVideoChatViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: widthCollectionCell, height: heightCollectionCell)
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 8
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return 8
  }
}
