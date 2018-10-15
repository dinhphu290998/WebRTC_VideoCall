//
//  PhotoCell.swift
//  Apprtc
//
//  Created by vmio69 on 2/1/18.
//  Copyright © 2018 Dhilip. All rights reserved.
//

import UIKit
import Kingfisher

class PhotoCell: UICollectionViewCell {
  @IBOutlet weak var photoImageView: UIImageView!
  @IBOutlet weak var timestampLabel: UILabel!
  @IBOutlet weak var deleteButton: UIButton!

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
