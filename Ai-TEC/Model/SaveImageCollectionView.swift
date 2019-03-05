//
//  SaveImageCollectionView.swift
//  Ai-Tec
//
//  Created by vMio on 11/5/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit
import os.log

class SaveImageCollectionView: NSObject, NSCoding {
    
    //MARK: Properties
    var photoImage: UIImage?
    
    
    //MARK: Archiving Paths
    static let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = documentsDirectory.appendingPathComponent("saveImageCollectionView")
    
    //MARK: Types
    struct PropertyKey
    {
        static let photoImage = "photoImage"
    }

     //MARK: Initialization
    
    init?(photoImage: UIImage?) {
        self.photoImage = photoImage
    }
    
    //MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(photoImage, forKey: PropertyKey.photoImage)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let photoImage = aDecoder.decodeObject(forKey: PropertyKey.photoImage)
        
        self.init(photoImage: photoImage as? UIImage)
    }
    
}
