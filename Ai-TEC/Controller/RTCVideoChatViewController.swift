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
    
    var captureSession: AVCaptureSession?
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var output: AVCaptureMetadataOutput?
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    let cameraOutPut = AVCapturePhotoOutput()
    var takePhoto = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.audioButton?.layer.cornerRadius = 22.0
        self.videoButton?.layer.cornerRadius = 22.0
        
        statusRemoteView.layer.cornerRadius = statusRemoteView.frame.width/2
        statusRemoteView.backgroundColor = UIColor.green
        
        avatarRemoteImageView.clipsToBounds = true
        avatarRemoteImageView.layer.borderColor = UIColor.white.cgColor
        avatarRemoteImageView.layer.borderWidth = 2
        avatarRemoteImageView.layer.cornerRadius = avatarRemoteImageView.frame.width/2
        avatarRemoteImageView.image = UIImage(named: "bg_search")
        
        
        remoteView?.delegate = self
        localView?.delegate = self
        
        nameRemoteLabel.text = nameRemote
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        createSession()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cameraPreviewLayer?.frame = localView.bounds
    }

    @IBAction func audioButtonPressed (_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
    }
    @IBAction func videoButtonPressed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
    }
    
    @IBAction func hangupButtonPressed(_ sender: UIButton) {
        self.performSegue(withIdentifier: "unwindToContactSegue", sender: self)
        let yourName = UserDefaults.standard.value(forKey: "yourname") ?? ""
        let nameRecieve = UserDefaults.standard.value(forKey: "nameRecieve") ?? ""
        let dictEndCall1 = ["type":ENDCALL,"host":"\(yourName)","receive": "\(nameRecieve)"]
        SocketGlobal.shared.socket?.write(string: convertString(from: dictEndCall1))
    }
    // đổi chiều camera
    
    @available(iOS 11.1, *)
    @IBAction func switchCameraButtonTouched(_ sender: UIButton) {
        let currentCameraInput: AVCaptureInput = captureSession!.inputs[0]
        captureSession?.removeInput(currentCameraInput)
        var newCamera: AVCaptureDevice?
        newCamera = AVCaptureDevice.default(for: AVMediaType.video)
        if (currentCameraInput as? AVCaptureDeviceInput)?.device.position == .back {
            newCamera = self.cameraWithPosition(position: .front)!
        } else {
            newCamera = self.cameraWithPosition(position: .back)!
        }
        do {
            try self.captureSession?.addInput(AVCaptureDeviceInput(device: newCamera!))
        }
        catch {
            print("error: \(error.localizedDescription)")
        }
    }
    @IBAction func captureButtonTouched(_ sender: UIButton) {
        takePhoto = true
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if takePhoto {
            takePhoto = false
            
            if let image = self.getImageFromSamplebuffer(buffer: sampleBuffer) {
                let photoVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EditViewcontroller") as! EditViewController
                let date = Date()
                photoVC.screenShotImage = image
                photoVC.nameRemote = nameRemote
                photoVC.timestampCapture = date
                print(date)
                DispatchQueue.main.async {
                    self.present(photoVC, animated: true, completion:  {
                        self.stopCaptureSeeion()
                    })
                }
            }
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

extension RTCVideoChatViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    func createSession() {
        captureSession = AVCaptureSession()
        device = AVCaptureDevice.default(for: AVMediaType.video)
        do{
            input = try AVCaptureDeviceInput(device: device!)
        }
        catch{
            print(error)
        }
        if let input = input{
            captureSession?.addInput(input)
        }
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        cameraPreviewLayer?.frame.size = localView.frame.size
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        cameraPreviewLayer?.connection?.videoOrientation = transformOrientation(orientation: UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!)
        
        localView.layer.addSublayer(cameraPreviewLayer!)
        
        
        // chạy vào hàm capture để chụp ảnh
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        if (captureSession?.canAddOutput(dataOutput))! {
            captureSession?.addOutput(dataOutput)
        }
        
        captureSession?.commitConfiguration()
        
        let queue = DispatchQueue(label: "com,brianadvent.captureQueue")
        dataOutput.setSampleBufferDelegate(self, queue: queue)
        captureSession?.startRunning()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) -> Void in
            self.cameraPreviewLayer?.connection?.videoOrientation = self.transformOrientation(orientation: UIInterfaceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!)
            self.cameraPreviewLayer?.frame = self.localView.bounds
        }, completion: { (context) -> Void in
            
        })
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    func transformOrientation(orientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    // đổi camera
    @available(iOS 11.1, *)
    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInTelephotoCamera, .builtInTrueDepthCamera, .builtInWideAngleCamera, ], mediaType: .video, position: position)
        
        if let device = deviceDiscoverySession.devices.first {
            return device
        }
        return nil
    }
    
    func getImageFromSamplebuffer(buffer: CMSampleBuffer) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let ciImage = CIImage(cvImageBuffer: pixelBuffer)
            let context = CIContext()
            
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            
            if let image = context.createCGImage(ciImage, from: imageRect) {
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .right)
            }
        }
        return nil
    }
    
    func stopCaptureSeeion() {
        self.captureSession?.stopRunning()
        
        if let inputs = captureSession?.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                self.captureSession?.removeInput(input)
            }
        }
        
    }
}
