//
//  DataService.swift
//  Ai-Tec
//
//  Created by vMio on 11/20/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import Foundation
class CheckImage {
    static let shared: CheckImage = CheckImage()
    var check: Bool = true
    var checkKml: Bool = true
    var checkRemote: Bool = false
    var checkLocalView: Bool?
    var checkSend: Bool = true
    var checkRoite: Bool = true
}
