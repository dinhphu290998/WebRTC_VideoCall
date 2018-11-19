//
//  AlbumViewController.swift
//  Ai-Tec
//
//  Created by vMio on 10/31/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit
import Material
import Starscream
import CoreData
import os.log

class AlbumViewController: UIViewController {
    
    var nameRemote = ""
    var photos: [String]?
    let widthCell = Device.model.rawValue > DeviceModel.iPad2.rawValue ? Screen.width/4 - 8 : Screen.width/2 - 8
    let userData = UserDefaults(suiteName: UserDefaults.standard.string(forKey: "yourname"))
    
    @IBOutlet weak var albumCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let photos = userData?.stringArray(forKey: nameRemote) {
            self.photos = photos.sorted(by: { (photo1, photo2) -> Bool in
                return photo1 > photo2
            })
        }
        self.albumCollectionView.reloadData()
        SocketGlobal.shared.socket?.delegate = self
    
    }
    

    @IBAction func backButtonTouched(_ sender: Any) {
      self.dismiss(animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

extension AlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate  {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let photos = photos {
            return photos.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCellId", for: indexPath) as? PhotoCell {
            if let url = URL(string: photos![indexPath.item]) {
                cell.setPhoto(url: url)
                cell.indexPath = indexPath
                
                cell.delegate = self
            }
            return cell
        }
      
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "ViewPhotoViewControllerId") as? ViewPhotoViewController,
            let photos = photos,
            let url = URL(string: photos[indexPath.item])
        {
            vc.photoUrl = url
            vc.nameRemote = nameRemote
            present(vc, animated: true, completion: nil)
        }
    }
    
 
}

extension AlbumViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: widthCell, height: widthCell)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
    }
}

extension AlbumViewController: WebSocketDelegate {
    func websocketDidConnect(socket: WebSocket) {
       print("")
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print(error ?? "")
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        if let messageString: String = text {
            print(messageString)
            let userData = UserDefaults(suiteName: UserDefaults.standard.string(forKey: "yourname"))
            let message: MessageSocket = MessageSocket(message: messageString)
            if message.type == functionSendImageUrl {
                var photosSender = userData?.stringArray(forKey: nameRemote)
                if photosSender == nil {
                    photosSender = []
                }
                if let photo = message.url  {
                    let url = "\(urlHostHttp)data/\(photo)"
                    photosSender?.append(url)
                    userData?.set(photosSender, forKey: nameRemote)
                }
                
                let alert = UIAlertController(title: "お知らせ",
                                              message: "画像を受信しました。確認しますか？\n後でギャラリーにて確認する事も出来ます。",
                                              preferredStyle: .alert)
                let openAction = UIAlertAction(title: "開く", style: .default, handler: { (_) in
                })
                
                let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
                alert.addAction(openAction)
                alert.addAction(cancelAction)
                
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print(data)
    }
    
}

extension AlbumViewController: PhotoCellDelegate {
    func remove(indexPath: IndexPath) {
        photos?.remove(at: indexPath.row)
    }

}
