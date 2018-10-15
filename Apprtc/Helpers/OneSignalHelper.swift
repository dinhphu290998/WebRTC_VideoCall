//
//  OneSignalHelper.swift
//  Apprtc
//
//  Created by vmio69 on 12/15/17.
//  Copyright © 2017 Dhilip. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class OneSignalHelper: NSObject {
  
  public static func addDeviceNotification(token: String,
                                           completion: @escaping (_ regId: String?, _ error: String?) -> Void) {
    addDevice(token: token, appId: oneSignalAppNotiId) { (regId, error) in
      completion(regId, error)
    }
  }
  
  public static func addDeviceVoip(token: String,
                                   completion: @escaping (_ regId: String?, _ error: String?) -> Void) {
    addDevice(token: token, appId: oneSignalAppVoipId) { (regId, error) in
      completion(regId, error)
    }
  }
  
  public static func sendNotification(receiveId: String, message: String, data: [String: String],
                                      completion: @escaping (_ idNotification: String?, _ errors: [JSON]?) -> Void) {
    sendMessage(receiveId: receiveId, message: message, appId: oneSignalAppNotiId, apiKey: oneSignalApiNotiKey,
                data: data) { (idNotification, errors) in
                  completion(idNotification, errors)
    }
  }
  
  public static func sendCallVoip(receiveId: String, message: String, data: [String: String],
                                  completion: @escaping (_ idNotification: String?, _ errors: [JSON]?) -> Void) {
    sendMessage(receiveId: receiveId, message: message, appId: oneSignalAppVoipId, apiKey: oneSignalApiVoipKey,
                data: data) { (idNotification, errors) in
                  completion(idNotification, errors)
    }
  }
  
  private static func addDevice(token: String, appId: String,
                                completion: @escaping (_ regId: String?, _ error: String?) -> Void) {
    Alamofire.request(oneSignalApiAddDevice, method: .post,
                      parameters: ["app_id": appId, "device_type": "0",
                                   "device_model": UIDevice.current.model,
                                   "device_os": UIDevice.current.systemVersion, "language": "en",
                                   "identifier": token, "test_type": 1, "timezone": "+25200"],
                      encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
                        if let data: Data = response.data {
                          do {
                            let json: JSON = try JSON(data: data)
                            if json["success"].boolValue {
                              completion(json["id"].stringValue, nil)
                            } else {
                              completion(nil, "can't add device")
                            }
                          } catch let error {
                            print(error.localizedDescription)
                            completion(nil, "can't read data")
                          }
                        } else {
                          completion(nil, "request error")
                        }
    }
  }
  
  private static func sendMessage(receiveId: String, message: String, appId: String, apiKey: String,
                                  data: Dictionary<String, String>,
                                  completion: @escaping (_ idNotification: String?, _ errors: [JSON]?) -> Void) {
    print("send to: \(receiveId)")
    Alamofire.request(oneSignalApiSendNotification, method: .post,
                      parameters: ["include_player_ids": [receiveId], "app_id": appId,
                                   "contents": ["en": message], "data": data],
                      encoding: JSONEncoding.default,
                      headers: ["Content-Type": "application/json; charset=utf-8",
                                "Authorization": "Basic \(apiKey)"])
      .responseJSON { (response) in
        if let data: Data = response.data {
          do {
            let json: JSON = try JSON(data: data)
            print(json)
            if let id: String = json["id"].string {
              completion(id, nil)
            } else {
              if let errors: [JSON] = json["error"].array {
                completion(nil, errors)
              } else {
                completion(nil, ["unkown error"])
              }
            }
          } catch let error {
            print(error.localizedDescription)
            completion(nil, ["can't read data"])
          }
        } else {
          completion(nil, ["request error"])
        }
    }
  }
  
}
