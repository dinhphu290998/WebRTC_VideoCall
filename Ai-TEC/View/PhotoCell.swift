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
    func remove(indexPath: Int)
}

class PhotoCell: UICollectionViewCell {
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var timestampLabel: UILabel!
    
    var dispatchWorkItem: DispatchWorkItem?
    var indexPath: IndexPath!
    weak var delegate: PhotoCellDelegate?
    
    // assign a url for the photo
    public func setPhoto(url: URL) {
        photoImageView.kf.indicatorType = .activity
        photoImageView.kf.setImage(with: url)
        
        fetchImage(from: url) { (image) in
            self.photoImageView.image = image
        }
        
        if let timestampCapture = url.timestampCaptured {
            timestampLabel.text = timestampCapture
        } else {
            timestampLabel.text = ""
        }
    }
    @IBAction func deleteButtonDidTap(_ sender: Any) {
        delegate?.remove(indexPath: indexPath.row)
    }
    
    func fetchImage(from url: URL, completedHandler: @escaping (UIImage?) -> Void) {
        var image: UIImage?
        dispatchWorkItem = DispatchWorkItem(block: {
            if let cache = CacheImage.images.object(forKey: url.absoluteString as NSString) as? UIImage {
                image = cache
            } else {
                // câu lệnh thực hiện
                do {
                    // try: thử
                    let aData = try Data(contentsOf: url)
                    image = UIImage(data: aData)
                    CacheImage.images.setObject(image!, forKey: url.absoluteString as NSString)
                }
                    // câu lệnh bắt lỗi
                catch {
                    print("Cache Image Error")
                }
            }
        })
        DispatchQueue.global().async {
            self.dispatchWorkItem?.perform()
            DispatchQueue.main.async {
                completedHandler(image)
            }
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}


