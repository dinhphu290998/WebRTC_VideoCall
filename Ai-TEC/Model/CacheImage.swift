//
//  CacheImage.swift
//  Ai-Tec
//
//  Created by vMio on 11/7/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit
class CacheImage {
    static var images : NSCache<NSString , AnyObject> = {
        var result = NSCache<NSString, AnyObject>()
        result.countLimit = 20
        result.totalCostLimit = 10 * 1024 * 1024
        return result
    }()
}


