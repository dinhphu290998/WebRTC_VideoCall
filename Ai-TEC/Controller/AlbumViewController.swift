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
import Zip

class AlbumViewController: UIViewController {
    
    var nameRemote = ""
    var photos: [String]?
    let widthCell = Device.model.rawValue > DeviceModel.iPad2.rawValue ? Screen.width/4 - 8 : Screen.width/2 - 8
    let userData = UserDefaults(suiteName: UserDefaults.standard.string(forKey: "yourname"))
    
    var bytes = [UInt8]()
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
        albumCollectionView.reloadData()
        SocketGlobal.shared.socket?.delegate = self
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
         print("deinit Album ----------")
    }
    
    @IBAction func hangupButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "unwindVideoChat", sender: self)
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    //filliter kml
    func getImageKml(url: URL) {
       
        var dataKml = Data()
        if let dataZip = NSData(contentsOf: url) {
            var result = dataZip.length - 40
            let value = 0x04034b50
            let signature = withUnsafeBytes(of: value) { Data($0) }
            
            while result > 0 {
                do {
                    let fileHander = try FileHandle(forReadingFrom: url)
                    fileHander.seek(toFileOffset: UInt64(result))
                    let data = fileHander.readData(ofLength: 8)
                    print(data)
                    print(data.int32)
                    if data.int32 == signature.int32 {
                        fileHander.seek(toFileOffset: UInt64(result))
                        dataKml = fileHander.readDataToEndOfFile()
                        fileHander.closeFile()
                        break
                    } else {
                        result = result - 1
                    }
                } catch {
                    print("error")
                }
            }
        }
        let fileNameZip = getDocumentsDirectory().appendingPathComponent("\(nameRemote).zip")
        
        do {
            try dataKml.write(to: fileNameZip)
        } catch {
            print("error")
        }
        
        do {
            let documentsDirectory = FileManager.default.urls(for:.documentDirectory, in: .userDomainMask)[0]
            try Zip.unzipFile(fileNameZip, destination: documentsDirectory, overwrite: true, password: nil)
        } catch {
            print("error")
        }
        
    }
}

extension AlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate  {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let photos = photos {
            return photos.count
        }
        return 0
    }
    
    //After the url is pressed on the image type on the cell
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
    //After clicking, will move the map to the map
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "ViewPhotoViewControllerId") as? ViewPhotoViewController,
            let photos = photos,
            let url = URL(string: photos[indexPath.item])
        {
            vc.nameRemote = nameRemote
            vc.photoUrl = url
            
            let fileName = getDocumentsDirectory().appendingPathComponent("image.jpg")
        
            do {
                let data = try url.asURL()
                let dataImage = try Data(contentsOf: data)
                
                try dataImage.write(to: fileName)
            } catch {
                print("error")
            }
            getImageKml(url: fileName)
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
    
            let userData = UserDefaults(suiteName: UserDefaults.standard.string(forKey: "yourname"))
            let message: MessageSocket = MessageSocket(message: text)
            if message.type == functionSendImageUrl {
                var photosSender = userData?.stringArray(forKey: nameRemote)
                
                if photosSender == nil {
                    photosSender = []
                }
                
                if let photo = message.url  {
                    let url = photo
                    photosSender?.append(url)
                    userData?.set(photosSender, forKey: nameRemote)
                }
                
                let alert = UIAlertController(title: "お知らせ",
                                              message: "画像を受信しました。確認しますか？\n後でギャラリーにて確認する事も出来ます。",
                                              preferredStyle: .alert)
                let openAction = UIAlertAction(title: "開く", style: .default, handler: { (_) in
                    
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let vc = storyboard.instantiateViewController(withIdentifier: "AlbumViewControllerId")
                        as? AlbumViewController {
                        vc.nameRemote = self.nameRemote
                        self.present(vc, animated: true, completion: nil)
                    }
                })
                
                let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
                alert.addAction(openAction)
                alert.addAction(cancelAction)
                present(alert, animated: true, completion: nil)
            }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print(data)
    }
}

extension AlbumViewController: PhotoCellDelegate {
    func remove(indexPath: Int) {
        photos?.remove(at: indexPath)
        userData?.set(photos, forKey: nameRemote)
        albumCollectionView.reloadData()
    }
}


