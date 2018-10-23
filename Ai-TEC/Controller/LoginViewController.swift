//
//  LoginViewController.swift
//  Ai-Tec
//
//  Created by Apple on 10/16/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit
import SVProgressHUD
import Starscream


class LoginViewController: UIViewController , WebSocketDelegate{
    
    
    
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField:UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameTextField.backgroundColor = UIColor.darkGray
        usernameTextField.textColor = UIColor.white
        usernameTextField.leftViewMode = .always
        
        passwordTextField.backgroundColor = UIColor.darkGray
        passwordTextField.textColor = UIColor.white
        passwordTextField.leftViewMode = .always
        
        //check version
        if let infoDict = Bundle.main.infoDictionary,
            let appVer = infoDict["CFBundleShortVersionString"],
            let buildNum = infoDict["CFBundleVersion"] {
            versionLabel.text = "Ver.\(appVer).\(buildNum)"
        }
        
        setNeedsStatusBarAppearanceUpdate()
        
        
        // WebSocket connect
        let url = URL(string: serverIP)
        SocketGlobal.shared.socket = WebSocket(url: url!)
        SocketGlobal.shared.socket?.connect()
        SocketGlobal.shared.socket?.delegate = self
        
    }
    

    @IBAction func loginButtonTouched(_ sender: Any) {
        
        SVProgressHUD.show()
        
        let nameUser = usernameTextField.text ?? ""
        UserDefaults.standard.set(nameUser, forKey: "yourname")
        
        let uuid = UUID().uuidString.lowercased()
        let password = passwordTextField.text ?? ""
        
        let dict = ["type":LOGIN,"name":nameUser, "password":password, "regId":uuid]
        
        //send message in sever
        SocketGlobal.shared.socket?.write(string: convertString(from: dict))
        
    }
    
    
    //DELEGATE webSocket
    func websocketDidConnect(socket: WebSocket) {
        print("websocketDidConnect")
    }
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        //error disconected
        print(error ?? "")
    }
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        // message connected and return message
        do {
            if let dictionary = try convertToDictionary(from: text){
                print(dictionary)
                let status : String = dictionary["status"] ?? ""
                let message : String = dictionary["message"] ?? ""
                print(status)
                print(message)
                
                if message == "Login success" && status == "success" {
                    SVProgressHUD.setStatus(message)
                    SVProgressHUD.dismiss(withDelay: 1)
                    
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                        self.performSegue(withIdentifier: "showContactSegueId", sender: self)
                    }
                }else{
                    SVProgressHUD.dismiss(withDelay: 3)
                    SVProgressHUD.setStatus(message)
                }
            }
        } catch {
            print(error)
        }
    }
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print(data)
    }

    
    // convert string to dictionary
    func convertToDictionary(from text: String) throws -> [String: String]? {
        guard let data = text.data(using: .utf8) else { return [:] }
        let anyResult: Any = try JSONSerialization.jsonObject(with: data, options: [])
        return anyResult as? [String: String]
    }
    //convert dictionary to string
    func convertString(from dict:[String:String]) -> String {
        let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.prettyPrinted)
        let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
        return jsonString
    }

}


