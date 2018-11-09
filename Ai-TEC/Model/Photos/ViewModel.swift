//
//  ViewModel.swift
//  Ai-Tec
//
//  Created by vMio on 11/9/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit

class ViewModel {
    let landscapeAlbum = PhotoAlbums.landscapes.album()
    let portraitAlbum = PhotoAlbums.portraits.album()
    
    func savePhoto(_ photo: UIImage?, completion: @escaping (PhotoAlbumHandlerError?) -> Void) {
        guard let photo = photo else {
            completion(.nilPhoto)
            return
        }
        landscapeAlbum.save(photo, completion: completion)
    }
}
