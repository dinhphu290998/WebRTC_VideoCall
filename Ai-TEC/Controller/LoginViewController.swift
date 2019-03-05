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
import CoreLocation

class LoginViewController: UIViewController , WebSocketDelegate, CLLocationManagerDelegate{
    
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField:UITextField!
    
    var numberID = 1
    let uuid = UUID().uuidString.lowercased()
    var userName = ""
    var passWord = ""
    var currentLocation: CLLocation?
    var locationManager: CLLocationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameTextField.backgroundColor = UIColor.darkGray
        usernameTextField.textColor = UIColor.white
        usernameTextField.leftViewMode = .always
        passwordTextField.backgroundColor = UIColor.darkGray
        passwordTextField.textColor = UIColor.white
        passwordTextField.leftViewMode = .always
        
        UserDefaults.standard.set(uuid, forKey: "uuid")
        setNeedsStatusBarAppearanceUpdate()

        infoVersion()
        setLocal()
        connectWebSocket()
    }
    
    func infoVersion(){
        //check version
        if let infoDict = Bundle.main.infoDictionary,
            let appVer = infoDict["CFBundleShortVersionString"],
            let buildNum = infoDict["CFBundleVersion"] {
            versionLabel.text = "Ver.\(appVer).\(buildNum)"
        }
    }
    func connectWebSocket(){
        // WebSocket connect
        let url = URL(string: serverIP)
        SocketGlobal.shared.socket = WebSocket(url: url!)
        SocketGlobal.shared.socket?.connect()
        SocketGlobal.shared.socket?.delegate = self
        
        //WebSocket Kurento
        let urlKRT = URL(string: urlKurento)
        SocketGlobal.shared.socketKurento = WebSocket(url: urlKRT!)
        SocketGlobal.shared.socketKurento?.disableSSLCertValidation = true
        SocketGlobal.shared.socketKurento?.connect()
        SocketGlobal.shared.socketKurento?.delegate = self
        
        //ping WebSocket Kurento
        let paramsJSON = ["interval":"3000"]
        let pingJSON = ["id":"\(numberID)","params":paramsJSON,"jsonrpc":"2.0","method":"ping"] as [String : Any]
        SocketGlobal.shared.socketKurento?.write(string: convertStringSA(from: pingJSON))
        Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.pingUpdate), userInfo: nil, repeats: true)
    }
    
    @objc func pingUpdate() {
        let dic = ["id":"\(numberID)","jsonrpc":"2.0","method":"ping"]
        SocketGlobal.shared.socketKurento?.write(string: convertString(from: dic))
    }
    
    func setLocal(){
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        userName = UserDefaults.standard.value(forKey: "yourname") as? String ?? ""
        passWord = UserDefaults.standard.value(forKey: "password") as? String ?? ""
        if userName != "" && passWord != "" {
            let dict = ["type":LOGIN,"name":userName, "password":passWord, "regId":uuid]
            //send message in sever
            SocketGlobal.shared.socket?.write(string: convertString(from: dict))
            SVProgressHUD.show()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        SVProgressHUD.dismiss()
    }
    
    @IBAction func loginButtonTouched(_ sender: Any) {
        SVProgressHUD.show()
        let nameUser = usernameTextField.text ?? ""
        UserDefaults.standard.set(nameUser, forKey: "yourname")
        let password = passwordTextField.text ?? ""
        UserDefaults.standard.set(password, forKey: "password")
        let dict = ["type":LOGIN,"name":nameUser, "password":password, "regId":uuid]
        //send message in sever
        SocketGlobal.shared.socket?.write(string: convertString(from: dict))
    }
    
    //DELEGATE webSocket
    func websocketDidConnect(socket: WebSocket) {
        print("Did Connect")
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        //error disconected
        print(error ?? "")
    }
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        // message connected and return message
        do {
            if let dictionary = try convertToDictionary(from: text){
                let status : String = dictionary["status"] ?? ""
                let message : String = dictionary["message"] ?? ""
                if message == "Login success" && status == "success" {
                    SVProgressHUD.setStatus(message)
                    SVProgressHUD.dismiss()
                    
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                        self.performSegue(withIdentifier: "showContactSegueId", sender: self)
                    }
                }else{
                    SVProgressHUD.dismiss(withDelay: 1)
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
    func convertStringSA(from dict:[String:Any]) -> String {
        let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions.prettyPrinted)
        let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String
        return jsonString
    }
}

extension LoginViewController {
    func clearDiskCache() {
        let fileManager = FileManager.default
        let myDocuments = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            try fileManager.removeItem(at: myDocuments)
        } catch {
            return
        }
    }
}
