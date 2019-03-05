                //
                //  KurentoViewController.swift
                //  Ai-Tec
                //
                //  Created by vMio on 12/13/18.
                //  Copyright © 2018 vMio. All rights reserved.
                //

                import UIKit
                import Starscream
                import AVFoundation
                import SVProgressHUD
                class KurentoViewController: UIViewController {
                    
                    @IBOutlet weak var collectionGuset: UICollectionView!
                    @IBOutlet weak var remoteCollectionView: UICollectionView!
                    @IBOutlet weak var localView: RTCEAGLVideoView!
                    @IBOutlet weak var audioButton: UIButton?
                    @IBOutlet weak var videoButton: UIButton?
                    @IBOutlet weak var viewResolution: UIView!
                    @IBOutlet weak var tableViewResolution: UITableView!
                    @IBOutlet weak var resButton: UIButton!
                    
                    var arrId = [String]()
                    var idLocal: String?
                    var numberID = 1
                    var contacts : [User] = []
                    var participantJoineds : [Remote] = []
                    var userName = ""
                    var uuid: Any?
                    var roomID: String?
                    let resolutions = ["320 x 240", "640 x 480", "1280 x 720", "1920 x 1080", "2560 x 1440", "3840 x 2160"]
                    var arrWidht:[Int] = [320,640,1280,1920,2560,3840]
                    var arrHeight:[Int] = [240,480,720,1080,1440,2160]
                    var defaultConfig: NBMMediaConfiguration?
                    var webRTCPeer: NBMWebRTCPeer?
                    let mediaContrain = RTCMediaConstraints.init(mandatoryConstraints: ["offerToReceiveAudio":"true"], optionalConstraints: ["offerToReceiveAudio":"true"])
                    var peerLocal: RTCPeerConnection?
                    var iceCandidates = [RTCIceCandidate]()
                    
                    override func viewDidLoad() {
                        super.viewDidLoad()
                        SocketGlobal.shared.socket?.delegate = self
                        SocketGlobal.shared.socketKurento?.delegate = self
                        collectionGuset.register(UINib(nibName: "UserCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "CellUser")
                        remoteCollectionView.register(UINib(nibName: "RemoteViewCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "CellRemoteView")
                        resButton.backgroundColor = UIColor.clear
                        
                        // join Room
                        self.joinRoomKurento(room: SocketGlobal.shared.room!)
                        DispatchQueue.global().async {
                            //start Call For Local Peer
                            self.startCallForLocalPeer()
                        }
                    }
                    
                    override func viewWillAppear(_ animated: Bool) {
                        self.navigationController?.setNavigationBarHidden(true, animated: true)
                        collectionGuset.reloadData()
                        remoteCollectionView.reloadData()
                        userName = UserDefaults.standard.value(forKey: "yourname") as! String
                        uuid = UserDefaults.standard.value(forKey: "uuid")
                        roomID = SocketGlobal.shared.room
                        let dict = ["type":DISCOVERY,"name":userName]
                        SocketGlobal.shared.socket?.write(string: convertString(from: dict))
                    }
                    
                    @IBAction func switchCamera(_ sender: UIButton) {
                        webRTCPeer?.switchCameraKurento()
                    }
                    
                    @IBAction func muteAudioButton(_ sender: UIButton) {
                        sender.isSelected = !sender.isSelected
                        if sender.isSelected == true {
                            webRTCPeer?.enableAudio(false)
                        }else{
                            webRTCPeer?.enableAudio(true)
                        }
                    }
                    
                    @IBAction func MuteVideoButton(_ sender: UIButton) {
                        sender.isSelected = !sender.isSelected
                        if sender.isSelected == true {
                            webRTCPeer?.enableVideo(false)
                        }else{
                            webRTCPeer?.enableVideo(true)
                        }
                    }
                    
                    @IBAction func endCallButton(_ sender: UIButton) {
                        let alert = UIAlertController(title: "確認", message:"通話を終了しても宜しいですか?", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "はい", style: UIAlertActionStyle.destructive, handler: { _ in
                            self.performSegue(withIdentifier: "unwindToContact", sender: self)
                            let dict = ["type":"conference confirm","host":self.userName,"name":self.userName,"confirm":"deny"]
                            SocketGlobal.shared.socket?.write(string: self.convertString(from: dict ))
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
                        let dictKRT = ["id":"\(numberID)","params":["metadata":metadata,"platform":"AnyPhone","session":"\(room)","dataChannels":"false","secret":"vm69vm69","token":"gr50nzaqe6avt65cg5v06"],"jsonrpc":"2.0","method":"joinRoom"] as [String : Any]
                        SocketGlobal.shared.socketKurento?.write(string:convertStringSA(from: dictKRT))
                    }
                    //start Call For Local Peer
                    func startCallForLocalPeer(){
                        if self.peerLocal == nil {
                            self.defaultConfig = NBMMediaConfiguration.default()
                            self.webRTCPeer = NBMWebRTCPeer.init(delegate: self, configuration: defaultConfig)
                            self.webRTCPeer?.setupLocalMedia(withVideoConstraints: self.mediaContrain)
                            let video = self.webRTCPeer?.localStream.videoTracks.first
                            video?.add(self.localView)
                            webRTCPeer?.generateOffer("SdpOfferLocal")
                        }
                    }
                    //did Receive Answer SDP and set Remote Description
                    func didReceiveAnswer(sdp:String){
                        let desc = RTCSessionDescription(type: .answer, sdp: sdp)
                        self.peerLocal?.setRemoteDescription(desc, completionHandler: { (error) in
                            if error == nil {
                                print("Set Remote Description For Local Succes")
                                for ice in self.iceCandidates{
                                    self.peerLocal?.add(ice)
                                }
                                self.iceCandidates.removeAll()
                            }else{
                                print(error!)
                            }
                        })
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
                    
                    func webRTCPeer(_ peer: NBMWebRTCPeer!, didGenerateOffer sdpOffer: RTCSessionDescription!, for connection: NBMPeerConnection!) {
                        if let peer = connection {
                            self.peerLocal = peer.peerConnection
                            self.peerLocal?.offer(for: self.mediaContrain, completionHandler: { (sessionDesc, error) in
                                if let sessDesc = sessionDesc {
                                    self.peerLocal?.setLocalDescription(sessDesc, completionHandler: { (err) in
                                        if err == nil{
                                            print("Set local Description For Local Succes")
                                            let paramJSON = ["frameRate":"5","audioActive":"true","doLoopback":"false","hasAudio":"true","hasVideo":"true","typeOfVideo":"CAMERA","videoActive":"true","resolution":"1280x720","sdpOffer":sdpOffer!.sdp]
                                            let dict = ["id":2,"params":paramJSON,"jsonrpc":"2.0","method":"publishVideo"] as [String : Any]
                                            SocketGlobal.shared.socketKurento?.write(string: self.convertStringSA(from: dict))
                                        }else{
                                            print(err!)
                                        }
                                    })
                                }
                            })
                        }
                    }
                    
                    func webRTCPeer(_ peer: NBMWebRTCPeer!, didGenerateAnswer sdpAnswer: RTCSessionDescription!, for connection: NBMPeerConnection!) {
                        print("")
                    }
                    
                    func webRTCPeer(_ peer: NBMWebRTCPeer!, hasICECandidate candidate: RTCIceCandidate!, for connection: NBMPeerConnection!) {
                        let onCandidate = ["jsonrpc":"2.0","method":"onIceCandidate","params":
                        ["endpointName":userName,"candidate":
                            candidate!.sdp,
                            "sdpMid":"audio",
                            "sdpMLineIndex":0
                            ],"id":3] as [String : Any]
                        SocketGlobal.shared.socketKurento?.write(string: convertStringSA(from: onCandidate))
                    }
                    
                    func webRTCPeer(_ peer: NBMWebRTCPeer!, didAdd remoteStream: RTCMediaStream!, of connection: NBMPeerConnection!) {
                        print("add remoteStream")
                    }
                    
                    func webRTCPeer(_ peer: NBMWebRTCPeer!, didRemove remoteStream: RTCMediaStream!, of connection: NBMPeerConnection!) {
                        print("remove remoteStream")
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
                            if let dictionary = try convertToDictionary(from: text){
                                if "\(dictionary["type"] ?? "")" == "discovery"{
                                    guard let data = dictionary["data"] as? [DICT] else {return}
                                    var listUser : [User] = []
                                    for dataObj in data {
                                        if let user = User(dict: dataObj) {
                                            listUser.append(user)
                                        }
                                        for i in 0..<listUser.count {
                                            if listUser[i].name == "\(userName)" {
                                                listUser.remove(at: i)
                                            }
                                        }
                                    }
                                    contacts = listUser
                                    collectionGuset.reloadData()
                                }
                                if "\(dictionary["method"] ?? "")" == "participantJoined"{
                                    print("participantJoined")
                                    guard let params = dictionary["params"] as? DICT else {return}
                                    guard let id = params["id"] as? String else {return}
                                    guard let metadata = params["metadata"] as? String else {return}
                                    let meta = try convertToDictionary(from: metadata)
                                    guard let clientData = meta!["clientData"] as? String else {return}
                                    
                                    let config = RTCConfiguration.init()
                                    config.iceServers.append(RTCIceServer.init(urlStrings: ["stun:stun.l.google.com:19302"], username: "vmio", credential: "vm69vm69"))
                                    config.keyType = RTCEncryptionKeyType.ECDSA
                                    config.iceTransportPolicy = RTCIceTransportPolicy.all
                                    config.bundlePolicy = RTCBundlePolicy.maxBundle
                                    config.tcpCandidatePolicy = RTCTcpCandidatePolicy.disabled
                                    config.continualGatheringPolicy = RTCContinualGatheringPolicy.gatherContinually
                                    config.rtcpMuxPolicy = RTCRtcpMuxPolicy.require
                                    let factory = RTCPeerConnectionFactory.init()
                                    let videoSource = factory.avFoundationVideoSource(with: self.mediaContrain)
                                    let audioSource = factory.audioSource(with: self.mediaContrain)
                                    let videoTrack = factory.videoTrack(with: videoSource, trackId: "v0")
                                    let audioTrack = factory.audioTrack(with: audioSource, trackId: "a0")
                                    let media = factory.mediaStream(withStreamId: "<#T##String#>")
                                    let remote = Remote.init(name: clientData, id: id, peer: nil, media: nil, arrIce: [])
                                    participantJoineds.append(remote)
                                    remoteCollectionView.reloadData()
                                }
                                if "\(dictionary["method"] ?? "")" == "participantLeft"{
                                    print("participantLeft")
                                    
                                }
                                if "\(dictionary["method"] ?? "")" == "iceCandidate"{
                                    guard let params = dictionary["params"] as? DICT else {return}
                                    guard let sdp = params["candidate"] as? String else {return}
                                    guard let endpointName = params["endpointName"] as? String else {return}
                                    guard let sdpMLineIndex = params["sdpMLineIndex"] as? Int32 else {return}
                                    guard let sdpMid = params["sdpMid"] as? String else {return}
                                    let iceCandidate = RTCIceCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
                                    if endpointName == self.idLocal{
                                        if self.peerLocal?.remoteDescription != nil{
                                            self.peerLocal?.add(iceCandidate)
                                        }else{
                                            self.iceCandidates.append(iceCandidate)
                                        }
                                    }else{
                                        print("Set ice Candidates for user")
                                    }
                                }
                                else{
                                    guard let result = dictionary["result"] as? DICT else {return}
                                    if let values = result["value"] as? [DICT] {
                                        for value in values {
                                            print("Join Room")
                                            guard let id = value["id"] as? String else {return}
                                            guard let metadata = value["metadata"] as? String else {return}
                                            let meta = try convertToDictionary(from: metadata)
                                            guard let clientData = meta!["clientData"] as? String else {return}
                                            
                                            
                                            let remote = Remote.init(name: clientData, id: id, peer: nil, media: nil, arrIce: [])
                                            participantJoineds.append(remote)
                                            remoteCollectionView.reloadData()
                                        }
                                    }
                                    if let id = result["id"] as? String {
                                        // SWIFT 4
                                        if arrId.count < 1{
                                            arrId.append(id)
                                            self.idLocal = arrId.first
                                        }
                                    }
                                    if let sdpAnswer = result["sdpAnswer"] as? String {
                                        if self.peerLocal?.remoteDescription == nil{
                                            self.didReceiveAnswer(sdp: sdpAnswer)
                                        }else{
                                            print("Set sdpAnswer for user")
                                        }
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
                            let cell = remoteCollectionView.dequeueReusableCell(withReuseIdentifier: "CellRemoteView", for: indexPath) as! RemoteViewCollectionViewCell
                            cell.nameRemote.text = participantJoineds[indexPath.item].nameRemote
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
                        if collectionView == collectionGuset{
                            let widthCollectionCell = CGFloat(integerLiteral: 40)
                            let heightCollectionCell = collectionGuset.bounds.height
                            return CGSize(width: widthCollectionCell, height: heightCollectionCell)
                        }else{
                            let widthCollectionCell = CGFloat(integerLiteral: 150)
                            let heightCollectionCell = remoteCollectionView.bounds.height
                            return CGSize(width: widthCollectionCell, height: heightCollectionCell)
                        }
                    }
                }


                

