//
//  CacheImage.swift
//  Ai-Tec
//
//  Created by vMio on 11/15/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import Foundation

class CacheImage {
    static var images: NSCache<NSString, AnyObject> = {
       var result = NSCache<NSString, AnyObject>()
       result.totalCostLimit = 30
       result.countLimit = 10 * 1024 * 1024
       return result
    }()
}
