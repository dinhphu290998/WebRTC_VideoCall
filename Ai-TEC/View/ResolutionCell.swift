//
//  ResolutionCell.swift
//  Ai-Tec
//
//  Created by Nguyễn Đình Phú on 10/25/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit

class ResolutionCell: UICollectionViewCell {
    @IBOutlet weak var resolutionLabel: UILabel!
    
    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected
                ? UIColor.init(red: 67/255.0, green: 56/255.0, blue: 202/255.0, alpha: 1.0)
                : .white
            resolutionLabel.textColor = isSelected ? .white : .black
        }
    }
}
