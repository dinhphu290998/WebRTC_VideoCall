//
//  PhotoCell.swift
//  Ai-Tec
//
//  Created by vMio on 11/1/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit
import Kingfisher
import Photos
protocol PhotoCellDelegate: class {
    func delete(index: Int)
}


class PhotoCell: UICollectionViewCell {
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var timestampLabel: UILabel!

    var dispatchWorkItem: DispatchWorkItem?
    let viewModel = ViewModel()
    var index: IndexPath?
    weak var delegate: PhotoCellDelegate?
    
   // assign a url for the photo
    
    public func setPhoto(url: URL) {
    
        ImageDownloader.default.downloadImage(with: url, retrieveImageTask: nil, options: [], progressBlock: nil, completionHandler: { (image,_ ,_ ,data) in
      
            self.photoImageView.image = image
            print(image as Any)
           
            // create a sender album
            

            self.viewModel.savePhoto(self.photoImageView.image!, completion: { (error) in
                DispatchQueue.main.async {
                    if let error = error {
                        print(error)
                    }
                   
                    print("Save Image To Album -------------------")
                }
            })
        })
        
        fetchImage(from: url) { (image) in
            self.photoImageView.image = image
        }
    
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let myString = formatter.string(from: Date())
        let yourDate = formatter.date(from: myString)
        let myStrongafd = formatter.string(from: yourDate!)
        timestampLabel.text = myStrongafd
        UserDefaults.standard.set(timestampLabel.text, forKey: "name")
        
    }
    
    
    @IBAction func deleteButtonDidTap(_ sender: Any) {
        delegate?.delete(index: index?.row ?? 0)
        
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
}
