//
//  AppDelegate.swift
//  Apprtc
//
//  Created by Mahabali on 9/5/15.
//  Copyright (c) 2015 Mahabali. All rights reserved.
//

import UIKit
import WebRTC
import PushKit
import SwiftyJSON
import CallKit
import GoogleMaps
import Fabric
import Crashlytics
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  private let pushRegistry = PKPushRegistry(queue: DispatchQueue.main)

  func application(_ application: UIApplication, didFinishLaunchingWithOptions
    launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    RTCInitializeSSL()

    // Enable all notification type.
    // VoIP Notifications don't present a UI but we will use this to show local nofications later
    let notificationSettings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)

    //register the notification settings
    application.registerUserNotificationSettings(notificationSettings)
    application.registerForRemoteNotifications()
    window!.makeKeyAndVisible()

    UIApplication.shared.isIdleTimerDisabled = true
    UIApplication.shared.applicationIconBadgeNumber = 0

    GMSServices.provideAPIKey(googleMapApiKey)
    Fabric.with([Crashlytics.self])

    if #available(iOS 10, *) {
      UNUserNotificationCenter.current().delegate = self
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge],
                                                              completionHandler: { (accepted, _) in
                                                                if !accepted {
                                                                  print("Notification access denied.")
                                                                }
      })
    } else if #available(iOS 9, *) {
      let notificationTypes: UIUserNotificationType
      notificationTypes = [.alert, .sound]
      let notificationSetting = UIUserNotificationSettings(types: notificationTypes, categories: nil)
      UIApplication.shared.registerUserNotificationSettings(notificationSetting)
    }
    return true
  }

  func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
    //PushKit
    pushRegistry.delegate = self
    var typeSet = Set<PKPushType>()
    typeSet.insert(.voIP)
    pushRegistry.desiredPushTypes = typeSet

  }

  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02x", $1)})
    print("device Token: \(deviceTokenString)")
  }

  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
    print(userInfo)
  }

  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state.
    // This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message)
    // or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates.
    // Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers,
    // and store enough application state information to restore your application to its current state
    // in case it is terminated later.
    // If your application supports background execution,
    // this method is called instead of applicationWillTerminate: when the user quits.
    // NotificationCenter.default.post(name: Notification.Name("activeAppNotification"), object: nil, userInfo: nil)
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the inactive state;
    // here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive.
    // If the application was previously in the background, optionally refresh the user interface.
    NotificationCenter.default.post(name: Notification.Name("activeAppNotification"), object: nil, userInfo: nil)
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate.
    // See also applicationDidEnterBackground:.
    RTCCleanupSSL()
  }

  func application(_ application: UIApplication,
                   supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    return UIInterfaceOrientationMask.portrait
  }

}

extension AppDelegate: UNUserNotificationCenterDelegate {

}

extension AppDelegate: PKPushRegistryDelegate {
  // MARK: - PUSH KIT DELEGATE
  func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {

    let token = pushCredentials.token.reduce("", {$0 + String(format: "%02x", $1)})
    print("voip token: \(token)")
    OneSignalHelper.addDeviceVoip(token: token, completion: { (regId, _) in
      if let regId: String = regId {
        UserDefaults.standard.set(regId, forKey: "regId")
        UserDefaults.standard.set(token, forKey: "voipToken")
      } else {
        print("one signal can't add device")
      }
    })
  }

  func pushRegistry(_ registry: PKPushRegistry,
                    didReceiveIncomingPushWith payload: PKPushPayload,
                    for type: PKPushType) {
    print("incoming \(payload.dictionaryPayload)")
    //CallKit only support iOS10 above
    //earlier versions use lacal notification
    if #available(iOS 10.0, *) {
      // TODO:
      //- change dummy data -> real user data
      //- open app when answer calling
      if UIApplication.shared.applicationState == .background {
        let data: Dictionary = payload.dictionaryPayload
        if let data = data["custom"] as? [String: Any],
          let caller = data["a"] as? [String: String],
          let callerName = caller["callerName"],
          let callerRegId = caller["callerRegId"] {
          let config = CXProviderConfiguration(localizedName: "Ai-TEC")
          config.iconTemplateImageData = UIImagePNGRepresentation(UIImage(named: "AppIcon")!)
          config.ringtoneSound = "ringtone.caf"
          config.supportsVideo = true
          let provider = CXProvider(configuration: config)
          provider.setDelegate(self, queue: nil)
          let update = CXCallUpdate()
          update.remoteHandle = CXHandle(type: .generic, value: callerName)
          update.hasVideo = true
          provider.reportNewIncomingCall(with: UUID(), update: update, completion: { (error) in
            print(error?.localizedDescription ?? "")
          })
          print(callerRegId)
        }
      }
    } else {
      // Fallback on earlier versions
      if UIApplication.shared.applicationState == .background {
        let localNoti = UILocalNotification()
        localNoti.alertBody = "test"
        localNoti.applicationIconBadgeNumber = 1
        localNoti.soundName = UILocalNotificationDefaultSoundName
        UIApplication.shared.presentLocalNotificationNow(localNoti)
      }
    }
  }

  func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
    print(notification)
  }

  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    print("token invalid")
  }

  //    // iOS 11 only
  //    func pushRegistry(_ registry: PKPushRegistry,
  //                      didReceiveIncomingPushWith payload: PKPushPayload,
  //                      for type: PKPushType, completion: @escaping () -> Void) {
  //        print("incoming completion \(payload.dictionaryPayload)")
  //        if #available(iOS 10.0, *) {
  //            let data: Dictionary = payload.dictionaryPayload
  //            if let data = data["custom"] as? Dictionary<String, Any>,
  //                let caller = data["a"] as? Dictionary<String, String>,
  //                let callerName = caller["callerName"],
  //                let callerRegId = caller["callerRegId"] {
  //                let config = CXProviderConfiguration(localizedName: "Ai-TEC")
  //                config.iconTemplateImageData = UIImagePNGRepresentation(UIImage(named: "AppIcon")!)
  //                config.ringtoneSound = "ringtone.caf"
  //                config.supportsVideo = true
  //                let provider = CXProvider(configuration: config)
  //                provider.setDelegate(self, queue: nil)
  //                let update = CXCallUpdate()
  //                update.remoteHandle = CXHandle(type: .generic, value: callerName)
  //                update.hasVideo = true
  //                provider.reportNewIncomingCall(with: UUID(), update: update, completion: { (error) in
  //                    print(error?.localizedDescription ?? "")
  //                })
  //                print(callerRegId)
  //            }
  //        } else {
  //            // Fallback on earlier versions
  //        }
  //    }
}

@available(iOS 10.0, *)
extension AppDelegate: CXProviderDelegate {
  // MARK: - CALL KIT DELEGATE
  func providerDidBegin(_ provider: CXProvider) {
  }
  func providerDidReset(_ provider: CXProvider) {
  }
  func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
    action.fulfill()
  }
  func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
    action.fulfill()
  }

  func provider(_ provider: CXProvider, perform action: CXStartCallAction) {

  }
}
