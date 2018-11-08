//
//  PhotoCell.swift
//  Ai-Tec
//
//  Created by vMio on 11/1/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit
import Kingfisher

protocol PhotoCellDelegate: class {
    func delete(index: Int)
}


class PhotoCell: UICollectionViewCell {
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var timestampLabel: UILabel!
    
  
    var index: IndexPath?
    weak var delegate: PhotoCellDelegate?
    public func setPhoto(url: URL) {   
//      photoImageView.kf.indicatorType = .activity
//      photoImageView.kf.setImage(with: url)
        ImageDownloader.default.downloadImage(with: url, retrieveImageTask: nil, options: [], progressBlock: nil, completionHandler: { (image,_ ,_ ,data) in

            self.photoImageView.image = image
            print(image)
            UIImageWriteToSavedPhotosAlbum(self.photoImageView.image!, self, nil, nil)
        })
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let myString = formatter.string(from: Date())
        let yourDate = formatter.date(from: myString)
        let myStrongafd = formatter.string(from: yourDate!)
        timestampLabel.text = myStrongafd
    }
    
    @IBAction func deleteButtonDidTap(_ sender: Any) {
        delegate?.delete(index: index?.row ?? 0)
     
    }
    

    
}
