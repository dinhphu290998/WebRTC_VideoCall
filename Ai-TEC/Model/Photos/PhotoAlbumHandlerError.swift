//
//  PhotoAlbumHandlerError.swift
//  Ai-Tec
//
//  Created by vMio on 11/9/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import Foundation

public enum PhotoAlbumHandlerError {
    case unauthorized
    case authCancelled
    case albumNotExists
    case saveFailed
    case unknown
    case nilPhoto
    
    var titile: String {
        return "Photo Save Error"
    }
    
    var message: String {
        switch self {
        case .unauthorized:
            return "Not authorized to access photos. Enable photo access in the 'Settings' app to continue."
        case .authCancelled:
            return "The authorization process was cancelled. You will not be able to save to your photo albums without authorizing access."
        case .albumNotExists:
            return "Unable to create or find the specified album."
        case .saveFailed:
            return "Failed to save specified image."
        case .unknown:
            return "An unknown error occured."
        case .nilPhoto:
            return "Unable to save an invalid photo."
        }
    }
}
