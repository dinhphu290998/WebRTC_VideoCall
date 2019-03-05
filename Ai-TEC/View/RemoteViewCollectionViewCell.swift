//
//  RemoteViewCollectionViewCell.swift
//  Ai-Tec
//
//  Created by Nguyễn Đình Phú on 11/15/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit

class RemoteViewCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var remoteView: RTCEAGLVideoView!
    @IBOutlet weak var nameRemote: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
