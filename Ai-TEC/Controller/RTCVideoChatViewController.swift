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
import CoreLocation
import SVProgressHUD
import CoreMotion
import MapViewPlus
@available(iOS 10.0, *)
class RTCVideoChatViewController: UIViewController {
    
    @IBOutlet weak var sensorView: UIView!
    @IBOutlet weak var sensorButton: UIButton!
    @IBOutlet weak var northLabel: UILabel!
    @IBOutlet weak var southLabel: UILabel!
    @IBOutlet weak var westLabel: UILabel!
    @IBOutlet weak var eastLabel: UILabel!
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
    @IBOutlet weak var captureImageButton: UIButton!
    @IBOutlet weak var compassButton: UIButton!
    @IBOutlet weak var switchCameraButton: UIButton!
    
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longtitude: UILabel!
    @IBOutlet weak var infoCompass: UILabel!
    
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
    var arrWidht:[Int] = [320,640,1280,1920,2560,3840]
    var arrHeight:[Int] = [240,480,720,1080,1440,2160]
    var captureSession: AVCaptureSession?
    let stillImageOutput = AVCaptureStillImageOutput()
    var captureController: ARDCaptureController = ARDCaptureController()

    var drawLines: Double?
    let canvasView = CompassView()
    let needleView = NeedleView()
    let kml = KML.shared
    
    var currentLocation: CLLocation?
    var locationManager: CLLocationManager = CLLocationManager()
    
    var alpha = 0
    var navi = ""
    let manager = CMMotionManager()
    let locationDelegate = LocationDelegate()
    var latestLocation: CLLocation? = nil
    var yourLocationBearing: CGFloat { return latestLocation?.bearingToLocationRadian(self.yourLocation) ?? 0 }
    var yourLocation: CLLocation {
        get { return UserDefaults.standard.setCurrentLocation }
        set { UserDefaults.standard.setCurrentLocation = newValue }
    }
    let locationManagerer: CLLocationManager = {
        $0.requestWhenInUseAuthorization()
        $0.desiredAccuracy = kCLLocationAccuracyBest
        $0.startUpdatingLocation()
        $0.startUpdatingHeading()
        return $0
    }(CLLocationManager())
    
    private func orientationAdjustment() -> CGFloat {
        let isFaceDown: Bool = {
            switch UIDevice.current.orientation {
            case .faceDown: return true
            default: return false
            }
        }()
        
        let adjAngle: CGFloat = {
            switch UIApplication.shared.statusBarOrientation {
            case .landscapeLeft:  return 90
            case .landscapeRight: return -90
            case .portrait, .unknown: return 0
            case .portraitUpsideDown: return isFaceDown ? 180 : -180
            }
        }()
        return adjAngle
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        configView()
        roundMoreView()
        
        CheckImage.shared.check = false
        sensorButton.isHidden = true
        compassButton.isHidden = true
        switchCameraButton.isHidden = true
        captureImageButton.isHidden = true
        audioButton?.isHidden = true
        videoButton?.isHidden = true
        if CheckImage.shared.checkKml == true {
    
            kml.startCall()
        }
    }
    
    @IBAction func someAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected == true {
            sensorButton.isHidden = false
            compassButton.isHidden = false
            switchCameraButton.isHidden = false
            captureImageButton.isHidden = false
            audioButton?.isHidden = false
            videoButton?.isHidden = false
            sensorView.isHidden = false
            CheckImage.shared.check = true
            
            self.localVideoTrack?.add(self.remoteView!)
            self.localVideoTrack?.remove(self.localView!)
            self.localView.renderFrame(nil)
            self.remoteVideoTrack?.add(self.localView!)
            self.remoteVideoTrack?.remove(self.remoteView)
            self.localVideoTrack?.remove(self.localView!)
            self.localView.renderFrame(nil)
            self.remoteVideoTrack?.remove(self.remoteView)
            
        } else {

            self.localVideoTrack?.remove(self.remoteView!)
            self.localVideoTrack?.remove(self.localView!)
            self.remoteVideoTrack?.add(self.remoteView!)
            self.remoteVideoTrack?.remove(self.localView!)
            self.localVideoTrack?.add(self.localView!)
            
            sensorButton.isHidden = true
            compassButton.isHidden = true
            switchCameraButton.isHidden = true
            captureImageButton.isHidden = true
            sensorView.isHidden = true
            audioButton?.isHidden = true
            videoButton?.isHidden = true
            CheckImage.shared.check = false
            
        }
    }
    
    func roundMoreView(){
        locationManagerer.delegate = locationDelegate
        locationDelegate.locationCallback = { location in
            self.latestLocation = location
        }
        
        locationDelegate.headingCallback = { newHeading in
            
            func computeNewAngle(with newAngle: CGFloat) -> CGFloat {
                let heading: CGFloat = {
                    let originalHeading = self.yourLocationBearing - newAngle.degreesToRadians
                    switch UIDevice.current.orientation {
                    case .faceDown: return -originalHeading
                    default: return originalHeading
                    }
                }()
                return CGFloat(self.orientationAdjustment().degreesToRadians + heading)
            }
            
            UIView.animate(withDuration: 0.5) {
                let angle = computeNewAngle(with: CGFloat(newHeading))
                self.needleView.transform = CGAffineTransform(rotationAngle: angle)
                self.alpha = Int(((angle / CGFloat.pi) * -180))
                switch (self.alpha){
                case 0...22 :
                    self.navi = "N"
                case 23...67 :
                    self.navi = "EN"
                case 68...111 :
                    self.navi = "E"
                case 112...157 :
                    self.navi = "SE"
                case 157...201 :
                    self.navi = "S"
                case 201...247 :
                    self.navi = "WS"
                case 248...291 :
                    self.navi = "W"
                case 292...336 :
                    self.navi = "WN"
                default:
                    self.navi = "N"
                }
            }
            if self.locationManager.location != nil {
                self.latitudeLabel.text = "Latitude :\(self.locationManager.location!.coordinate.latitude)"
                self.longtitude.text = "longtitude :\(self.locationManager.location!.coordinate.longitude)"
            }
            
            self.infoCompass.text = "Compass :\(self.alpha) º\(self.navi)"
        }
        self.manager.accelerometerUpdateInterval = 0.01
        
        if self.manager.isAccelerometerAvailable {
            self.manager.startAccelerometerUpdates(to: OperationQueue.current!, withHandler: {(data, error) in
                
                let rotation = atan2(data!.acceleration.x,
                                     data!.acceleration.y) - .pi
                self.drawLines = rotation
                self.sensorView.transform =
                    CGAffineTransform(rotationAngle: CGFloat(rotation))
            })
        }
    }
    
    func configView(){
        captureImageButton.layer.cornerRadius = 6
        self.isZoom = false
        self.audioButton?.layer.cornerRadius = 22.0
        self.videoButton?.layer.cornerRadius = 22.0
        resolutionCollectionView.allowsMultipleSelection = false
        canvasView.frame = CGRect(x: 0, y: 16, width: view.bounds.width, height: view.bounds.width)
        canvasView.backgroundColor = .white
        canvasView.layer.cornerRadius = canvasView.frame.width/2
        canvasView.layer.masksToBounds = true
        remoteView.addSubview(canvasView)
        canvasView.isHidden = true
        canvasView.backgroundColor = UIColor.clear
        needleView.frame = CGRect(x: 0, y: 16, width: view.bounds.width, height: view.bounds.width)
        needleView.layer.cornerRadius = canvasView.frame.width/2
        needleView.layer.masksToBounds = true
        needleView.isHidden = true
        remoteView.addSubview(needleView)
        needleView.backgroundColor = UIColor.clear
        
        northLabel.isHidden = true
        southLabel.isHidden = true
        westLabel.isHidden = true
        eastLabel.isHidden = true
        sensorView.isHidden = true
        sensorView.backgroundColor = UIColor.clear
        
        longtitude.backgroundColor = UIColor.clear
        latitudeLabel.backgroundColor = UIColor.clear
        infoCompass.backgroundColor = UIColor.clear
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        remoteView.delegate = self
        localView.delegate = self
        nameRemoteLabel.text = nameRemote
        UserDefaults.standard.set(nameRemoteLabel.text, forKey: "nameRemote")
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
    @IBAction func sensorBt(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected == true {
            sensorView.isHidden = true
            CheckImage.shared.check = false
        } else {
            CheckImage.shared.check = true
            sensorView.isHidden = false
        }
    }
    
    @IBAction func compassButton (_ sender:UIButton){
        sender.isSelected = !sender.isSelected
        if sender.isSelected == true{
            canvasView.isHidden = false
            northLabel.isHidden = false
            southLabel.isHidden = false
            westLabel.isHidden = false
            eastLabel.isHidden = false
            needleView.isHidden = false
            sensorButton.isHidden = true
            longtitude.isHidden = false
            latitudeLabel.isHidden = false
            infoCompass.isHidden = false
        }else{
            canvasView.isHidden = true
            northLabel.isHidden = true
            southLabel.isHidden = true
            westLabel.isHidden = true
            eastLabel.isHidden = true
            needleView.isHidden = true
            sensorButton.isHidden = false
            longtitude.isHidden = true
            latitudeLabel.isHidden = true
            infoCompass.isHidden = true
        }
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
        let alert = UIAlertController(title: "確認", message:"通話を終了しても宜しいですか?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "はい", style: UIAlertActionStyle.destructive, handler: { _ in
            self.currentLocation = self.locationManager.location
            AnotationMapView.shared.annotations.append(AnnotationPlus.init(viewModel: DefaultCalloutViewModel(title: "End Call"), coordinate: CLLocationCoordinate2DMake(self.currentLocation!.coordinate.latitude, self.currentLocation!.coordinate.longitude), stringImage: "1"))
            self.kml.endCall()
            self.disconnect()
            let yourName = UserDefaults.standard.value(forKey: "yourname") ?? ""
            let nameRecieve = UserDefaults.standard.value(forKey: "nameRecieve") ?? ""
            let dictEndCall1 = ["type":ENDCALL,"host":"\(yourName)","receive": "\(nameRecieve)"]
            self.dismiss(animated: true, completion: nil)
            SocketGlobal.shared.socket?.write(string: self.convertString(from: dictEndCall1))
        }))
        alert.addAction(UIAlertAction(title: "いいえ", style: UIAlertActionStyle.cancel, handler:nil))
        self.present(alert, animated: true, completion: nil)
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
        
        SVProgressHUD.show(withStatus: "waiting....")

        kml.sendImage()

        if let videoConnection = stillImageOutput.connection(with: AVMediaType.video) {
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection,
                                                             completionHandler: { (imageDataSampleBuffer, _) in
                                                                if let buffer = imageDataSampleBuffer,
                                                                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer) {
                                                                    self.screenShotImage = UIImage(data: imageData)
                                                                    SVProgressHUD.dismiss()
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
                editVc.screenShotImage = screenShotImage?.addTimestamp(date)
                editVc.nameRemote = nameRemote
                editVc.timestampCapture = date
                editVc.drawLines = drawLines ?? 0
            }
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
}


@available(iOS 10.0, *)
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
            let yourName = UserDefaults.standard.value(forKey: "yourname") ?? ""
            let nameRecieve = UserDefaults.standard.value(forKey: "nameRecieve") ?? ""
            let dictEndCall = ["type":ENDCALL,"host":"\(yourName)","receive": "\(nameRecieve)"]
            SocketGlobal.shared.socket?.write(string: convertString(from: dictEndCall))
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
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: { (action) -> Void in
            self.disconnect()
        })
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
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

@available(iOS 10.0, *)
extension RTCVideoChatViewController: UICollectionViewDataSource ,UICollectionViewDelegate {
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
        localVideoTrack?.source.adaptOutputFormat(toWidth: Int32(arrWidht[indexPath.item]), height: Int32(arrHeight[indexPath.item]), fps: 24)
    }
}

@available(iOS 10.0, *)
extension RTCVideoChatViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let widthCollectionCell = (collectionView.bounds.width-10)/2
        let heightCollectionCell = collectionView.bounds.height/3.5
        return CGSize(width: widthCollectionCell, height: heightCollectionCell)
    }
}

@available(iOS 10.0, *)
extension RTCVideoChatViewController: RTCEAGLVideoViewDelegate {
    func videoView(_ videoView: RTCEAGLVideoView, didChangeVideoSize size: CGSize) {
        print("")
    }
}

@available(iOS 10.0, *)
extension RTCVideoChatViewController: WebSocketDelegate {
    func websocketDidConnect(socket: WebSocket) {
        print("---Message RTCVideoChatViewController----")
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print(error ?? "")
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        do {
            if let dictionary = try convertToDictionary(from: text){
                
                if "\(dictionary["result"] ?? "")" == "reject" {
                    self.performSegue(withIdentifier: "backContactSegueId", sender: self)
                }
                if "\(dictionary["result"] ?? "")" == "success"{
                    self.performSegue(withIdentifier: "showVideoChatSegueId", sender: self)
                    SocketGlobal.shared.room = dictionary["room"] as? String
                }
            }
        } catch {
            print(error)
        }
            let userData = UserDefaults(suiteName: UserDefaults.standard.string(forKey: "yourname"))
            let message: MessageSocket = MessageSocket(message: text)
            
            if message.type == functionSendImageUrl {
                var photosSender = userData?.stringArray(forKey: nameRemote)
                if photosSender == nil {
                    photosSender = []
                }
                
                if let photo = message.url  {
                    let url = photo
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
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print(data)
    }
}


