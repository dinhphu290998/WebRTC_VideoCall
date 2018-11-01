//
//  ContactViewController.swift
//  Ai-Tec
//
//  Created by Apple on 10/17/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit
import Starscream
import GoogleMaps

class ContactViewController: UIViewController ,WebSocketDelegate , UITableViewDelegate , UITableViewDataSource{
    
    
    @IBOutlet weak var myAvatarImageView: UIImageView!
    @IBOutlet weak var myStatusView: UIView!
    @IBOutlet weak var myNameLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var contactTableView: UITableView!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var emergencyButton: UIButton!
    
    var dictCall : [String:String] = [:]
    var nameUserAnswer = ""
    var userName = ""
    var checkButton = true
    var index : Int?
    
    var currentLocation: CLLocation?
    var locationManager: CLLocationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myAvatarImageView.image = UIImage(named: "bg_search")
        myNameLabel.text = UserDefaults.standard.value(forKey: "yourname") as? String
        myStatusView.layer.cornerRadius = 6
        myStatusView.layer.masksToBounds = true
        
        SocketGlobal.shared.socket?.delegate = self
        
        userName = UserDefaults.standard.value(forKey: "yourname") as? String ?? ""
        let dict = ["type":DISCOVERY,"name":userName]
        
        //login to socket
        SocketGlobal.shared.socket?.write(string: convertString(from: dict))
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.stopUpdatingLocation()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        contactTableView.reloadData()
    }
    @IBAction func logoutButtonTouched(_ sender: Any) {
        let alert = UIAlertController(title: "ログアウトアカウント", message: "本気ですか？?", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "はい", style: UIAlertActionStyle.destructive, handler: { _ in
            SocketGlobal.shared.socket?.disconnect()
            self.performSegue(withIdentifier: "backLoginSegueId", sender: self)
            
        }))
        alert.addAction(UIAlertAction(title: "いいえ", style: UIAlertActionStyle.cancel, handler: nil))
        // show the alert
        self.present(alert, animated: true, completion: nil)
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
                    SocketGlobal.shared.contacts = listUser
                    contactTableView.reloadData()
                case "call":
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                        self.performSegue(withIdentifier: "showRingingSegueId", sender: self)
                    }
                    nameUserAnswer = "\(dictionary["name"]!)"
                    checkButton = true
                default:
                    print("Answer")
                }
                
            }
        } catch {
            print(error)
        }
    }
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print(data)
    }
    
    
    //TableVIew DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SocketGlobal.shared.contacts.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = contactTableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath) as! ContactTableViewCell
        cell.photoUser.image = UIImage(named: "bg_search")
        cell.nameUser.text = SocketGlobal.shared.contacts[indexPath.row].name
        if SocketGlobal.shared.contacts[indexPath.row].status == 1 {
            cell.viewStatus.backgroundColor = .green
            cell.isUserInteractionEnabled = true
        }else{
            cell.viewStatus.backgroundColor = .red
            cell.isUserInteractionEnabled = false
        }
        return cell
    }
    
    //TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        index = indexPath.row
        let receiName = SocketGlobal.shared.contacts[indexPath.row].name
        UserDefaults.standard.set(receiName, forKey: "nameReceive")
        let dict = ["type" : CALL ,"name" : userName, "host" : userName , "receive" : receiName]
        dictCall = dict
        
        
    }
    
    
    @IBAction func CallP2P(_ sender: UIButton) {
        if index != nil {
            if dictCall["name"] != nil && SocketGlobal.shared.contacts[index!].status == 1{
                SocketGlobal.shared.socket?.write(string: convertString(from: dictCall))
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                    self.performSegue(withIdentifier: "showRingingSegueId", sender: self)
                }
                nameUserAnswer = "\(dictCall["receive"]!)"
            }
        }
        checkButton = false
    }
    
    // MARK: - SEGUE
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRingingSegueId" {
            let callingVc = segue.destination as? RingingViewController
                callingVc?.nameUserCall = nameUserAnswer
                callingVc?.check = checkButton
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

extension ContactViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = manager.location
    }
}
