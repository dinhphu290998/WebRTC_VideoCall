//
//  KurentoViewController.swift
//  Ai-Tec
//
//  Created by vMio on 12/13/18.
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

class KurentoViewController: UIViewController {
    @IBOutlet weak var collectionViewRemote: UICollectionView!
    @IBOutlet weak var collectionGuset: UICollectionView!
    @IBOutlet weak var localView: RTCEAGLVideoView!
    @IBOutlet weak var audioButton: UIButton?
    @IBOutlet weak var videoButton: UIButton?
    @IBOutlet weak var viewResolution: UIView!
    @IBOutlet weak var tableViewResolution: UITableView!
    @IBOutlet weak var resButton: UIButton!
    var idLocal = ""
    var contacts : [User] = []
    var participantJoineds : [Remote] = []
    var userName = ""
    var uuid: Any?
    var roomID: String?
    let resolutions = ["320 x 240", "640 x 480", "1280 x 720", "1920 x 1080", "2560 x 1440", "3840 x 2160"]
    let callConstraint = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio" : "true", "OfferToReceiveVideo": "true"],
                                                              optionalConstraints: nil)
    let defaultConnectionConstraint = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement": "true"])
    var iceServer: RTCIceServer = RTCIceServer.init(urlStrings: ["stun:stun.l.google.com:19302"])
    var webRTC : NBMWebRTCPeer?
    var peerLocal: RTCPeerConnection?
    var remoteIceCandidates: [RTCIceCandidate] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        SocketGlobal.shared.socket?.delegate = self
        SocketGlobal.shared.socketKurento?.delegate = self
        collectionGuset.register(UINib(nibName: "UserCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "CellUser")
        collectionViewRemote.register(UINib(nibName: "RemoteViewCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "CellRemoteView")
        resButton.backgroundColor = UIColor.clear
        self.startCallForLocal()
    }
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        collectionGuset.reloadData()
        userName = UserDefaults.standard.value(forKey: "yourname") as! String
        uuid = UserDefaults.standard.value(forKey: "uuid")
        roomID = SocketGlobal.shared.room
        let dict = ["type":DISCOVERY,"name":userName]
        SocketGlobal.shared.socket?.write(string: convertString(from: dict))
    }
    func startCallForLocal(){
        let defaultConfig = NBMMediaConfiguration.default()
        self.webRTC = NBMWebRTCPeer.init(delegate: self, configuration: defaultConfig)
        self.webRTC?.setupLocalMedia(withVideoConstraints: self.callConstraint)
        let video = self.webRTC?.localStream.videoTracks.first
        video?.add(self.localView)
        webRTC?.generateOffer("sdpLocal", completion: { (sdp: String!, peer: NBMPeerConnection!) in
            self.peerLocal = peer.peerConnection
            if self.peerLocal != nil{
                self.joinRoomKurento(room: SocketGlobal.shared.room!)
            }
            let sessionDescription = RTCSessionDescription(type: .offer, sdp: sdp)
            self.peerLocal?.setLocalDescription(sessionDescription, completionHandler: { (error) in
                if let error = error {
                    print(error)
                } else {
                    print("Set local Description For Local Succes")
                    let paramJSON = ["frameRate":"5","audioActive":"true","doLoopback":"false","hasAudio":"true","hasVideo":"true","typeOfVideo":"CAMERA","videoActive":"true","resolution":"1280x720","sdpOffer":sessionDescription.sdp]
                    let dict = ["id":2,"params":paramJSON,"jsonrpc":"2.0","method":"publishVideo"] as [String : Any]
                    SocketGlobal.shared.socketKurento?.write(string: self.convertStringSA(from: dict))
                }
            })
        })
    }
    @IBAction func switchCamera(_ sender: UIButton) {
        webRTC?.switchCameraKurento()
    }

    @IBAction func muteAudioButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected == true {
            webRTC?.enableAudio(false)
        }else{
            webRTC?.enableAudio(true)
        }
    }
    @IBAction func MuteVideoButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected == true {
            webRTC?.enableVideo(false)
        }else{
            webRTC?.enableVideo(true)
        }
    }
    @IBAction func endCallButton(_ sender: UIButton) {
        let alert = UIAlertController(title: "確認", message:"通話を終了しても宜しいですか?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "はい", style: UIAlertActionStyle.destructive, handler: { _ in
            self.performSegue(withIdentifier: "unwindToContact", sender: self)
            let dict = ["type":"conference confirm","host":self.userName,"name":self.userName,"confirm":"deny"]
            SocketGlobal.shared.socket?.write(string: self.convertString(from: dict ))
            let leaveRoom = ["method":"leaveRoom"]
            SocketGlobal.shared.socketKurento?.write(string: self.convertString(from: leaveRoom))
            self.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "いいえ", style: UIAlertActionStyle.cancel, handler:nil))
        self.present(alert, animated: true, completion: nil)
    }
    @IBAction func captureButtonTouched(_ sender: UIButton) {
    }
    @IBAction func resolutionButton(_ sender: UIButton) {
        viewResolution.isHidden = false
    }
    // join Room
    func joinRoomKurento(room:String){
        let userName :String = UserDefaults.standard.value(forKey: "yourname") as! String
        let metadataJSON = ["clientData":userName]
        let metadata = convertString(from: metadataJSON)
        let dictKRT = ["id":"\(1)","params":["metadata":metadata,"platform":"AnyPhone","session":"\(room)","dataChannels":"false","secret":"vm69vm69","token":"gr50nzaqe6avt65cg5v06"],"jsonrpc":"2.0","method":"joinRoom"] as [String : Any]
        SocketGlobal.shared.socketKurento?.write(string:convertStringSA(from: dictKRT))
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
}
extension KurentoViewController: NBMWebRTCPeerDelegate{
    func webRTCPeer(_ peer: NBMWebRTCPeer!, didGenerateOffer sdpOffer: RTCSessionDescription!, for connection: NBMPeerConnection!) {
        print("didGenerateOffer sdpOffer")
    }
    func webRTCPeer(_ peer: NBMWebRTCPeer!, didGenerateAnswer sdpAnswer: RTCSessionDescription!, for connection: NBMPeerConnection!) {
        print("didGenerateAnswer sdpAnswer")
    }
    func webRTCPeer(_ peer: NBMWebRTCPeer!, hasICECandidate candidate: RTCIceCandidate!, for connection: NBMPeerConnection!) {
        let onCandidate = ["jsonrpc":"2.0","method":"onIceCandidate","params":["endpointName":"vtest","candidate":candidate.sdp,"sdpMid":"audio","sdpMLineIndex":0],"id":3] as [String : Any]
        SocketGlobal.shared.socketKurento?.write(string: self.convertStringSA(from: onCandidate))
    }
    func webrtcPeer(_ peer: NBMWebRTCPeer!, iceStatusChanged state: RTCIceConnectionState, of connection: NBMPeerConnection!) {
        switch state {
        case .checking:
            print("checking")
        case .closed:
            print("closed")
        case .completed:
            print("completed")
        case .connected:
            print("connected")
        case .count:
            print("count")
        case .disconnected:
            print("disconnected")
        case .failed:
            print("failed")
        default:
            print("new")
        }
    }
    func webRTCPeer(_ peer: NBMWebRTCPeer!, didAdd remoteStream: RTCMediaStream!, of connection: NBMPeerConnection!) {
        for remote in participantJoineds{
            if remote.remotePeer == connection.peerConnection{
                remote.remoteMedia = remoteStream
                remote.check = true
                DispatchQueue.main.async {
                    self.collectionViewRemote.reloadData()
                }
            }
        }
    }
    func webRTCPeer(_ peer: NBMWebRTCPeer!, didRemove remoteStream: RTCMediaStream!, of connection: NBMPeerConnection!) {
        print("didRemove remoteStream")
    }
    func webRTCPeer(_ peer: NBMWebRTCPeer!, didAdd dataChannel: RTCDataChannel!) {
        print("didAdd dataChannel")
    }
}
extension KurentoViewController: WebSocketDelegate{
    //DELEGATE websocket
    func websocketDidConnect(socket: WebSocket) {
        print("")
    }
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print(error ?? "")
    }
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        do {
            if let dictionary = try self.convertToDictionary(from: text){
                print(dictionary)
                if dictionary.keys.contains("type"){
                    guard let data = dictionary["data"] as? [DICT] else {return}
                    var listUser : [User] = []
                    for dataObj in data {
                        if let user = User(dict: dataObj) {
                                listUser.append(user)
                        }
                        for i in 0..<listUser.count {
                            if listUser[i].name == "\(self.userName)" {
                                listUser.remove(at: i)
                            }
                        }
                    }
                    self.contacts = listUser
                    self.collectionGuset.reloadData()
                }
                if dictionary.keys.contains("result"){
                    guard let result = dictionary["result"] as? DICT else {return}
                    //get id Local and receive remote join room
                    if result.keys.contains("metadata") {
                        guard let id = result["id"] as? String else {return}
                        self.idLocal = id
                        print(self.idLocal)
                        if let values = result["value"] as? [DICT] {
                            for value in values {
                                let queue = DispatchQueue(label: "queue_other")
                                queue.async {
                                    do{
                                        print("Người vào trước")
                                        guard let id = value["id"] as? String else {return}
                                        guard let metadata = value["metadata"] as? String else {return}
                                        let meta = try self.convertToDictionary(from: metadata)
                                        guard let clientData = meta!["clientData"] as? String else {return}
                                        self.webRTC?.generateOffer("sdpRemote", completion: { (sdp: String!, peer: NBMPeerConnection!) in
                                            let remote: Remote = Remote(name: clientData, id: id, peer: peer.peerConnection, media: nil, arrIce: [], check: false)!
                                            let sessionDescription = RTCSessionDescription(type: .offer, sdp: sdp)
                                            remote.remotePeer!.setLocalDescription(sessionDescription, completionHandler: { (error) in
                                                if let error = error {
                                                    print(error)
                                                } else {
                                                    print("Set local Description For Remote Succes")
                                                    let receive = ["jsonrpc":"2.0","method":"receiveVideoFrom","params":["sender":"\(id)_webcam","sdpOffer":sessionDescription.sdp],"id":2] as [String : Any]
                                                    SocketGlobal.shared.socketKurento?.write(string: self.convertStringSA(from: receive))
                                                }
                                            })
                                            self.participantJoineds.append(remote)
                                            DispatchQueue.main.async {
                                                self.collectionViewRemote.reloadData()
                                            }
                                        })
                                    }catch{
                                        print(error)
                                    }
                                }
                            }
                        }
                    }
                    //set description sdpAnswer
                    if result.keys.contains("sdpAnswer") {
                        guard let sdpAnswer = result["sdpAnswer"] as? String else {return}
                        let sessionDescription = RTCSessionDescription(type: .answer, sdp: sdpAnswer)
                        if self.peerLocal!.remoteDescription == nil{
                            self.peerLocal!.setRemoteDescription(sessionDescription, completionHandler: { [weak self] (error) in
                                guard let this = self else { return }
                                if let error = error {
                                    print(error)
                                } else {
                                    for iceCandidate in this.remoteIceCandidates {
                                        this.peerLocal!.add(iceCandidate)
                                    }
                                    this.remoteIceCandidates.removeAll()
                                    print("Set Remote Description For Local Succes")
                                }
                            })
                        }else{
                            for remote in participantJoineds {
                                if remote.remotePeer!.remoteDescription == nil {
                                    remote.remotePeer!.setRemoteDescription(sessionDescription, completionHandler: {(error) in
                                        if let error = error {
                                            print(error)
                                        } else {
                                            for iceCandidate in remote.arrIceCandidate! {
                                                remote.remotePeer!.add(iceCandidate)
                                            }
                                            remote.arrIceCandidate!.removeAll()
                                            print("Set Remote Description For Remote Succes")
                                        }
                                    })
                                }
                            }
                        }
                    }
                    
                }
                if dictionary.keys.contains("method"){
                    switch dictionary["method"] as? String {
                    case "participantJoined":
                        print("Người vào sau")
                        guard let params = dictionary["params"] as? DICT else {return}
                        guard let id = params["id"] as? String else {return}
                        guard let metadata = params["metadata"] as? String else {return}
                        let meta = try self.convertToDictionary(from: metadata)
                        guard let clientData = meta!["clientData"] as? String else {return}
                        self.webRTC?.generateOffer("sdpRemote", completion: { (sdp: String!, peer: NBMPeerConnection!) in
                            let remote: Remote = Remote(name: clientData, id: id, peer: peer.peerConnection, media: nil, arrIce: [], check: false)!
                            let sessionDescription = RTCSessionDescription(type: .offer, sdp: sdp)
                            remote.remotePeer!.setLocalDescription(sessionDescription, completionHandler: { (error) in
                                if let error = error {
                                    print(error)
                                } else {
                                    print("Set local Description For Remote Succes")
                                    let receive = ["jsonrpc":"2.0","method":"receiveVideoFrom","params":["sender":"\(id)_webcam","sdpOffer":sessionDescription.sdp],"id":2] as [String : Any]
                                    SocketGlobal.shared.socketKurento?.write(string: self.convertStringSA(from: receive))
                                }
                            })
                            self.participantJoineds.append(remote)
                            DispatchQueue.main.async {
                                self.collectionViewRemote.reloadData()
                            }
                        })
                    case "participantLeft":
                        let leaveRoom = ["method":"leaveRoom"]
                        SocketGlobal.shared.socketKurento?.write(string: self.convertString(from: leaveRoom))
                    case "participantPublished":
                        print("participantPublished")
                    case "iceCandidate":
                        guard let params = dictionary["params"] as? DICT else {return}
                        guard let sdp = params["candidate"] as? String else {return}
                        guard let endpointName = params["endpointName"] as? String else {return}
                        print("endpointName : \(endpointName)")
                        guard let sdpMLineIndex = params["sdpMLineIndex"] as? Int32 else {return}
                        guard let sdpMid = params["sdpMid"] as? String else {return}
                        let iceCandidate = RTCIceCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
                        if endpointName.elementsEqual(self.idLocal) == true {
                            if self.peerLocal!.remoteDescription != nil {
                                self.peerLocal!.add(iceCandidate)
                            } else {
                                self.remoteIceCandidates.append(iceCandidate)
                            }
                        }
                        else{
                            for remote in participantJoineds{
                                if endpointName.elementsEqual(remote.regIdRemote) == true{
                                    if remote.remotePeer!.remoteDescription != nil {
                                        remote.remotePeer!.add(iceCandidate)
                                    } else {
                                        remote.arrIceCandidate?.append(iceCandidate)
                                    }
                                }
                            }
                        }
                    default:
                        return
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print(data)
    }
}
extension KurentoViewController:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableViewResolution.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = resolutions[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 20
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewResolution.isHidden = true
        resButton.titleLabel?.text = resolutions[indexPath.row]
    }
}
extension KurentoViewController: UICollectionViewDelegate,UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == collectionGuset{
            return contacts.count
        }else{
            return participantJoineds.count
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == collectionGuset{
            let cell = collectionGuset.dequeueReusableCell(withReuseIdentifier: "CellUser", for: indexPath) as! UserCollectionViewCell
            cell.nameUser.text = contacts[indexPath.item].name
            if contacts[indexPath.item].status == 1 {
                cell.photoUser.image = UIImage(named: "engineer (5)")
            }else{
                cell.photoUser.image = UIImage(named: "engineer (4)")
            }
            return cell
        }else{
            let cell = collectionViewRemote.dequeueReusableCell(withReuseIdentifier: "CellRemoteView", for: indexPath) as! RemoteViewCollectionViewCell
            cell.nameRemote.text = participantJoineds[indexPath.item].nameRemote
            if participantJoineds.count > 0{
                if let video = participantJoineds[indexPath.item].remoteMedia?.videoTracks.first {
                    video.add(cell.remoteView)
                }
                if participantJoineds[indexPath.item].check == true{
                    cell.connectingLb.isHidden = true
                }
            }
            cell.layer.cornerRadius = 30
            cell.layer.masksToBounds = true
            return cell
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == collectionGuset{
            let receiveName = contacts[indexPath.item].name
            let dict = ["type":"conference invitation","host":"\(userName)","receive":"\(receiveName)", "name":"\(userName)", "room":"\(roomID ?? "")" ]
            SocketGlobal.shared.socket?.write(string: convertString(from: dict ))
        }
    }
}
extension KurentoViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == collectionGuset {
            let widthCollectionCell = CGFloat(integerLiteral: 40)
            let heightCollectionCell = collectionGuset.bounds.height
            return CGSize(width: widthCollectionCell, height: heightCollectionCell)
        }else{
            let heightCollectionCell = collectionViewRemote.bounds.height
            return CGSize(width: heightCollectionCell * 3/4, height: heightCollectionCell)
        }
    }
}



