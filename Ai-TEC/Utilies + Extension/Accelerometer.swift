//
//  Accelerometer.swift
//  Ai-Tec
//
//  Created by Nguyễn Đình Phú on 12/20/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit
import CoreMotion

class Accelerometer {
    func getAccelerometer(){
        var motionManager: CMMotionManager!
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
//        var x: Double = 0.0
//        var y: Double = 0.0
//        var z: Double = 0.0

    }
}
