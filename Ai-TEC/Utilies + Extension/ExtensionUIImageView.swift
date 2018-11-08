//
//  ExtensionUIImageView.swift
//  Ai-Tec
//
//  Created by vMio on 11/5/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit

extension UIImageView {
    func imageURLString(url: String) {
        guard let url = URL(string: url) else { return }
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url) {
                DispatchQueue.main.async {
                    self.image = UIImage(data: data)
                }
            }
        }
    }
}
