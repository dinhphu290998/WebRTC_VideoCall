//
//  ContactViewController.swift
//  Ai-Tec
//
//  Created by Apple on 10/17/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit
import Starscream
import CoreLocation
import Alamofire
class ContactViewController: UIViewController ,WebSocketDelegate , UITableViewDelegate , UITableViewDataSource, XMLParserDelegate, CLLocationManagerDelegate{
    
    
    @IBOutlet weak var myAvatarImageView: UIImageView!
    @IBOutlet weak var myStatusView: UIView!
    @IBOutlet weak var myNameLabel: UILabel!
    @IBOutlet weak var contactTableView: UITableView!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var emergencyButton: UIButton!
    @IBOutlet weak var conferenceButton: UIButton!
    
    var dictCall : [String:String] = [:]
    var nameUserAnswer = ""
    var userName = ""
    var checkButton = true
    var checkPK = true
    var index : Int?
    var uuid: Any?
    var room = ""
    var idKRT = ""
    var contacts : [User] = []
    var currentLocation: CLLocation?
    var locationManager: CLLocationManager = CLLocationManager()
    override func viewDidLoad() {
        super.viewDidLoad()
        callButton.layer.cornerRadius = 6
        logoutButton.layer.cornerRadius = 6
        conferenceButton.layer.cornerRadius = 6
        myAvatarImageView.image = UIImage(named: "bg_search")
        myNameLabel.text = UserDefaults.standard.value(forKey: "yourname") as? String
        myStatusView.layer.cornerRadius = 6
        myStatusView.layer.masksToBounds = true
        SocketGlobal.shared.socket?.delegate = self
        SocketGlobal.shared.socketKurento?.delegate = self
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        userName = UserDefaults.standard.value(forKey: "yourname") as? String ?? ""
        let dict = ["type" : DISCOVERY, "name" : userName ]
        room = Date().ticks
        SocketGlobal.shared.room = room
        uuid = UserDefaults.standard.value(forKey: "uuid")
        //login to socket
        SocketGlobal.shared.socket?.write(string: convertString(from: dict))
        contactTableView.reloadData()
    }
    @IBAction func unwindToContact(segue: UIStoryboardSegue) { }
    @IBAction func logoutButtonTouched(_ sender: Any) {
        let alert = UIAlertController(title: "ログアウトしても宜しいですか？", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "はい", style: UIAlertActionStyle.destructive, handler: { _ in
            
            SocketGlobal.shared.socket?.disconnect()
            self.performSegue(withIdentifier: "backLoginSegueId", sender: self)
            
            UserDefaults.standard.removeObject(forKey: "yourname")
            UserDefaults.standard.removeObject(forKey: "password")
            
        }))
        alert.addAction(UIAlertAction(title: "いいえ", style: UIAlertActionStyle.cancel, handler:nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func Conference(_ sender: UIButton) {
        if self.index != nil{
            let checkName = UserDefaults.standard.value(forKey: "nameReceive")
            var listName = [""]
            for user in self.contacts{
                listName.append(user.name)
            }
            if listName.contains(checkName as! String) {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                    self.performSegue(withIdentifier: "KorentoViewControllerStoryBoardId", sender: self)
                }
                let nameRecieve = self.contacts[self.index!].name
                let dict = ["type":"conference invitation","host":self.userName,"receive":"\(nameRecieve)", "name":"\(self.userName)", "room":"\(SocketGlobal.shared.room ?? "")" ]
                SocketGlobal.shared.socket?.write(string: self.convertString(from: dict))
            }
            nameUserAnswer = "\(dictCall["receive"]!)"
        }
        checkPK = false
        index = nil
    }
    
    @IBAction func CallP2P(_ sender: UIButton) {
        // creat new
        if index != nil {
            let checkName = UserDefaults.standard.value(forKey: "nameReceive")
            var listName = [""]
            for user in contacts{
                listName.append(user.name)
            }
            if listName.contains(checkName as! String){
                SocketGlobal.shared.socket?.write(string: convertString(from: dictCall))
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                    self.performSegue(withIdentifier: "showRingingSegueId", sender: self)
                }
            }
            nameUserAnswer = "\(dictCall["receive"]!)"
        }
        checkPK = true
        checkButton = false
        index = nil
    }
    
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
                switch "\(dictionary["type"] ?? "")" {
                case "discovery":
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
                    index = nil
                    contactTableView.reloadData()
                case "call":
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                        self.performSegue(withIdentifier: "showRingingSegueId", sender: self)
                    }
                    nameUserAnswer = "\(dictionary["name"]!)"
                    checkPK = true
                    checkButton = true
                case "conference invitation":
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                        self.performSegue(withIdentifier: "showRingingSegueId", sender: self)
                    }
                    checkPK = false
                    checkButton = true
                    nameUserAnswer = "\(dictionary["host"] ?? "")"
                    SocketGlobal.shared.room = dictionary["room"] as? String
                default:
                    guard let result = dictionary["result"] as? DICT else {return}
                    if let id = result["id"] as? String {
                        if id != ""{
                            idKRT = id
                        }
                    }
                }
            }
        } catch {
            print("error")
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print(data)
    }
    
    //TableVIew DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = contactTableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath) as! ContactTableViewCell
        cell.photoUser.image = UIImage(named: "bg_search")
        cell.nameUser.text = contacts[indexPath.row].name
        if contacts[indexPath.row].status == 1 {
            cell.viewStatus.backgroundColor = .green
            cell.isUserInteractionEnabled = true
        } else {
            cell.viewStatus.backgroundColor = .red
            cell.isUserInteractionEnabled = false
        }
        return cell
    }
    
    //TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        index = indexPath.row
        let receiName = contacts[indexPath.row].name
        UserDefaults.standard.set(receiName, forKey: "nameReceive")
        let dict = ["type" : CALL, "name" : userName, "host" : userName , "receive" : receiName]
        dictCall = dict
    }
    
    
    
    // MARK: - SEGUE
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRingingSegueId" {
            let callingVc = segue.destination as? RingingViewController
            callingVc?.nameUserCall = nameUserAnswer
            callingVc?.check = checkButton
            callingVc?.checkPK = checkPK
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

