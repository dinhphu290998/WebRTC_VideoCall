//
//  AlbumViewController.swift
//  Ai-Tec
//
//  Created by vMio on 10/31/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit
import Material
class AlbumViewController: UIViewController {
    var nameRemote = ""
    var photos: [String]?
    let widthCell = Device.model.rawValue > DeviceModel.iPad2.rawValue ? Screen.width/4 - 8 : Screen.width/2 - 8
     let userData = UserDefaults(suiteName: UserDefaults.standard.string(forKey: "yourname"))
    @IBOutlet weak var albumCollectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let photos = userData?.stringArray(forKey: nameRemote) {
            self.photos = photos.sorted(by: { (photo1, photo2) -> Bool in
                return photo1 > photo2
            })
            self.albumCollectionView.reloadData()
        }
        
    }

    @IBAction func backButtonTouched(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    

}

extension AlbumViewController: UICollectionViewDataSource  {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let photos = photos {
            return photos.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCellId", for: indexPath) as? PhotoCell {
            if let photos = photos,
                let url = URL(string: photos[indexPath.item]) {
                cell.setPhoto(url: url)
            }
            return cell
        }
        return UICollectionViewCell()
    }
}

extension AlbumViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "ViewPhotoViewControllerId") as? ViewPhotoViewController,
            let photos = photos,
            let url = URL(string: photos[indexPath.item])
            {
                vc.photoUrl = url
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
