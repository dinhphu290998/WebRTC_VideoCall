//
//  PhotoCell.swift
//  Ai-Tec
//
//  Created by vMio on 11/1/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit
import Kingfisher
class PhotoCell: UICollectionViewCell {
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var timestampLabel: UILabel!
    
    public func setPhoto(url: URL) {
        photoImageView.kf.indicatorType = .activity
        photoImageView.kf.setImage(with: url)
        if let timestampCapture = url.timestampCaptured {
            timestampLabel.text = timestampCapture
        } else {
            timestampLabel.text = ""
        }
    }
}
