//
//  ContactTableViewCell.swift
//  Ai-Tec
//
//  Created by Apple on 10/17/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit

class ContactTableViewCell: UITableViewCell {

    @IBOutlet weak var nameUser: UILabel!
    @IBOutlet weak var photoUser: UIImageView!
    @IBOutlet weak var viewStatus: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        viewStatus.layer.cornerRadius = viewStatus.frame.width/3
        viewStatus.layer.masksToBounds = true
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
