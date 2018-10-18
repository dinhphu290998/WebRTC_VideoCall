//
//  ContactViewController.swift
//  Ai-Tec
//
//  Created by Apple on 10/17/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit
import Starscream


class ContactViewController: UIViewController ,WebSocketDelegate , UITableViewDelegate , UITableViewDataSource{
    

    @IBOutlet weak var myAvatarImageView: UIImageView!
    @IBOutlet weak var myStatusView: UIView!
    @IBOutlet weak var myNameLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var contactTableView: UITableView!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var emergencyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myAvatarImageView.image = UIImage(named: "bg_search")
        myNameLabel.text = UserDefaults.standard.value(forKey: "yourname") as? String
        
        SocketGlobal.shared.socket?.delegate = self
        
        let username = UserDefaults.standard.value(forKey: "yourname") as? String ?? ""
        let dict = ["type":DISCOVERY,"name":username]
        
        //login to socket
        SocketGlobal.shared.socket?.write(string: convertString(from: dict))
    }

    @IBAction func logoutButtonTouched(_ sender: Any) {
        let alert = UIAlertController(title: "Logout Account", message: "Are you sure?", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "YES", style: UIAlertActionStyle.destructive, handler: { _ in
            SocketGlobal.shared.socket?.disconnect()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                self.performSegue(withIdentifier: "backLoginSegueId", sender: self)
            }
        }))
        alert.addAction(UIAlertAction(title: "NO", style: UIAlertActionStyle.cancel, handler: nil))
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }

    //DELEGATE websocket
    func websocketDidConnect(socket: WebSocket) {
        print("websocketDidConnect")
    }
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print(error ?? "")
    }
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        print(text)
        
        do {
            if let dictionary = try convertToDictionary(from: text){
                print(dictionary)
                guard let data = dictionary["data"] as? [DICT] else {return}
                var listUser : [User] = []
                for dataObj in data {
                    if let user = User(dict: dataObj) {
                            listUser.append(user)
                    }
                    for i in 0..<listUser.count {
                        if listUser[i].name == "\(UserDefaults.standard.value(forKey: "yourname")!)" {
                            listUser.remove(at: i)
                        }
                    }
                }
                SocketGlobal.shared.contacts = listUser
                contactTableView.reloadData()
            }
        } catch {
            print(error)
        }
    }
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print(data)
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
    
    
    //TableVIew DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SocketGlobal.shared.contacts.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = contactTableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath) as! ContactTableViewCell
        cell.photoUser.image = UIImage(named: "bg_search")
        cell.nameUser.text = SocketGlobal.shared.contacts[indexPath.row].name
        return cell
    }
    
    //TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let yourName = UserDefaults.standard.value(forKey: "yourname") as? String ?? ""
        let receiName = SocketGlobal.shared.contacts[indexPath.row].name
        let dict = ["type" : CALL , "host" : yourName , "receive" : receiName]
        print(dict)

        
    }
    
    
    @IBAction func CallP2P(_ sender: UIButton) {
        let dic = ["receive": "jtest2","name":"vtest2", "host": "vtest2", "type": "call"]
        SocketGlobal.shared.socket?.write(string: convertString(from: dic))
    }
}
