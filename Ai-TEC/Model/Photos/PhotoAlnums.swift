//
//  PhotoAlnums.swift
//  Ai-Tec
//
//  Created by vMio on 11/9/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import Foundation

public enum PhotoAlbums {
    
    
    
    case landscapes
   
    
    var albumName: String {
        switch self {
        case .landscapes:
            let data = UserDefaults.standard.value(forKey: "yourname") as? String ?? ""
            return data
        }
    }
    
    func album() -> PhotoAlbumHandler {
       return PhotoAlbum.init(named: albumName)
    }
}
