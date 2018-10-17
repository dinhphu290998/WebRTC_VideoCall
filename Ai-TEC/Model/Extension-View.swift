//
//  Extension-View.swift
//  Ai-Tec
//
//  Created by Apple on 10/17/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit

@IBDesignable class DesignableUI: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        view()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        view()
    }
    func view() {
        self.layer.cornerRadius = UIScreen.main.bounds.width / 2
        self.layer.masksToBounds = true
    }
}
