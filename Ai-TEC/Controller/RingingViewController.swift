//
//  RingingViewController.swift
//  Ai-Tec
//
//  Created by apple on 10/20/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit
import Starscream
import AVFoundation
import AudioToolbox
import CoreLocation
@available(iOS 10.0, *)
class RingingViewController: UIViewController ,WebSocketDelegate {
    

    @IBOutlet weak var callerLabel: UILabel!
    @IBOutlet weak var rejectHostButton: UIButton!
    @IBOutlet weak var rejectLabel: UILabel!
    @IBOutlet weak var rejectReceiveButton: UIButton!
    @IBOutlet weak var cancelLabel: UILabel!
    @IBOutlet weak var answerButton: UIButton!
    @IBOutlet weak var answerLabel: UILabel!
    @IBOutlet weak var searchAnimationImageView: UIImageView!
    
    var currentLocation: CLLocation?
    var locationManager: CLLocationManager = CLLocationManager()
    var nameUserCall = ""
    var check = false
    var checkPK = false
    var roomId: String?
    var timerSoundAlert: Timer?
    var timerAnimation: Timer?
    let kml = KML.shared
    let commingCallSoundId: SystemSoundID = 1014
    let waitingCallSoundId: SystemSoundID = 1074
    //1108 chup anh
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SocketGlobal.shared.socket?.delegate = self
        SocketGlobal.shared.socketKurento?.delegate = self
        callerLabel.text = nameUserCall
        
        if check == false {
            rejectReceiveButton.isHidden = true
            cancelLabel.isHidden = true
            answerButton.isHidden = true
            answerLabel.isHidden = true
        }else{
            rejectHostButton.isHidden = true
            rejectLabel.isHidden = true
        }
        
        timerAnimation = Timer.scheduledTimer(timeInterval: 1, target: self,
                                              selector: #selector(animationSearch), userInfo: nil, repeats: true)
        timerSoundAlert = Timer.scheduledTimer(timeInterval: 2, target: self,
                                               selector: #selector(playsSound), userInfo: nil, repeats: true)
     
    }
    
    //animation
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timerAnimation?.invalidate()
        timerAnimation = nil
        timerSoundAlert?.invalidate()
        timerSoundAlert = nil
    }
    @objc func animationSearch() {
        UIView.animate(withDuration: 1, animations: {
            self.searchAnimationImageView.transform = CGAffineTransform(scaleX: 4, y: 4)
        }) { (_) in
            UIView.animate(withDuration: 1, animations: {
                self.searchAnimationImageView.transform = CGAffineTransform.identity
            }, completion: nil)
            
        }
    }
    @objc func playsSound	() {
        if check == false {
            AudioServicesPlaySystemSound(waitingCallSoundId)
        }else{
            AudioServicesPlaySystemSound(commingCallSoundId)
        }
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))

    }
    
    func websocketDidConnect(socket: WebSocket) {
        print("")
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
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print("")
    }

    @IBAction func cancelBt(_ sender: UIButton) {
        let userName :String = UserDefaults.standard.value(forKey: "yourname") as! String
        if checkPK == true{
            let dictReject = ["type":"answer","result":"reject","host":userName,"receive":nameUserCall]
            SocketGlobal.shared.socket?.write(string: convertString(from: dictReject))
            kml.endCall()
        }else{
            let dict = ["type":"conference confirm","host":userName,"name":userName,"confirm":"deny"]
            SocketGlobal.shared.socket?.write(string: self.convertString(from: dict ))
        }
        self.performSegue(withIdentifier: "backContactSegueId", sender: self)
        timerSoundAlert?.invalidate()
        timerSoundAlert = nil
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func answerBt(_ sender: UIButton) {
        let userName :String = UserDefaults.standard.value(forKey: "yourname") as! String
        if checkPK == true{
            let roomId = Date().ticks
            SocketGlobal.shared.room = roomId
            let dictSuccess = ["type":"answer","result":"success" ,"room":"\(roomId)","host":nameUserCall]
            SocketGlobal.shared.socket?.write(string: convertString(from: dictSuccess))
            self.performSegue(withIdentifier: "showVideoChatSegueId", sender: self)
            if CheckImage.shared.checkKml == true {
                CheckImage.shared.checkKml = false
                kml.startCall()
            }
        }else{
            let dict = ["type":"conference confirm","host":userName,"name":userName,"confirm":"accept"]
            SocketGlobal.shared.socket?.write(string: self.convertString(from: dict ))
            self.performSegue(withIdentifier: "KorentoViewControllerStoryBoardId", sender: self)
        }
        timerSoundAlert?.invalidate()
        timerSoundAlert = nil
    }
  
    // MARK: - SEGUE
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showVideoChatSegueId" {
            let ringingVC = segue.destination as? RTCVideoChatViewController
            ringingVC?.nameRemote = nameUserCall
        }
    }
    
    // convert string to dictionary
    func convertToDictionary(from text: String) throws -> [String: Any]? {
        guard let data = text.data(using: .utf8) else { return [:] }
        let anyResult: Any = try JSONSerialization.jsonObject(with: data, options: [])
        return anyResult as? [String: Any]
    }
    //convert dictionarySS to string
    func convertString(from dict:[String:String]) -> String {
        let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.prettyPrinted)
        let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
        return jsonString
    }
    //convert dictionarySA to string
    func convertStringSA(from dict:[String:Any]) -> String {
        let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.prettyPrinted)
        let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
        return jsonString
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
