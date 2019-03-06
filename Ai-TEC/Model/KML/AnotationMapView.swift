//
//  AnotationMapView.swift
//  Ai-Tec
//
//  Created by vmio vmio on 3/6/19.
//  Copyright © 2019 vMio. All rights reserved.
//

import Foundation
import MapViewPlus
class AnotationMapView {
    static let  shared: AnotationMapView = AnotationMapView()
    var annotations: [AnnotationPlus] = []
}
