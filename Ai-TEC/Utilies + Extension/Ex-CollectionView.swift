//
//  Ex-CollectionView.swift
//  Ai-Tec
//
//  Created by Nguyễn Đình Phú on 10/25/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit

extension UICollectionView {
    func setup_horizotal(numberOfItems: CGFloat, padding: CGFloat) {
        let layout = UICollectionViewFlowLayout()
        let widthScreen = UIScreen.main.bounds.size.width
        let width = (widthScreen - padding * 2 - padding * (2 - 1))/2
        layout.itemSize = CGSize(width: width, height: 160)
        layout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        layout.minimumLineSpacing = padding
        layout.scrollDirection = .horizontal
        self.collectionViewLayout = layout
    }
    
    func setup_vertical(numberOfItems: CGFloat, padding: CGFloat) {
        let layout = UICollectionViewFlowLayout()
        let widthScreen = UIScreen.main.bounds.size.width
        let width = (widthScreen - padding * 2 - padding * (3 - 1))/3
        layout.itemSize = CGSize(width: width, height: width * 2)
        layout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        layout.minimumLineSpacing = padding
        layout.scrollDirection = .vertical
        self.collectionViewLayout = layout
    }
}
