//
//  ResolutionCell.swift
//  Apprtc
//
//  Created by vmio69 on 1/2/18.
//  Copyright © 2018 Dhilip. All rights reserved.
//

import UIKit

class ResolutionCell: UICollectionViewCell {

  @IBOutlet weak var resolutionLabel: UILabel!

  public func setResolution(resolution: String) {
    resolutionLabel.text = resolution
  }

  override var isSelected: Bool {
    didSet {
      backgroundColor = isSelected
        ? UIColor.init(red: 67/255.0, green: 202/255.0, blue: 56/255.0, alpha: 1.0)
        : .white
      resolutionLabel.textColor = isSelected ? .white : .black
    }
  }
}
