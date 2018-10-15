//
//  ContactTableViewCell.swift
//  Apprtc
//
//  Created by vmio69 on 12/14/17.
//  Copyright © 2017 Dhilip. All rights reserved.
//

import UIKit
import Material

class ContactTableViewCell: UITableViewCell {

  @IBOutlet weak var avatarImageView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var statusView: UIView!

  override func awakeFromNib() {
    super.awakeFromNib()
  }

  func updateUser(user: User) {
    avatarImageView?.clipsToBounds = true
    let w = Screen.width/5 - 16
    avatarImageView?.layer.cornerRadius = w/2
//    avatarImageView?.setRandomDownloadImage(Int(w), height: Int(w))
    avatarImageView.image = #imageLiteral(resourceName: "avatar")
    nameLabel?.text = user.name
    statusView.layer.cornerRadius = w/12
    statusView.backgroundColor = (user.status == "1") ? UIColor.green : UIColor.red
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    //        self.backgroundColor = UIColor.lightGray
  }

}
