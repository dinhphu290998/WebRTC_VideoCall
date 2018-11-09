//
//  PhotoAlbum.swift
//  Ai-Tec
//
//  Created by vMio on 11/9/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import Photos

class PhotoAlbum: PhotoAlbumHandler {
    var albumName: String
    
    init(named: String) {
        albumName = named
    }
}
