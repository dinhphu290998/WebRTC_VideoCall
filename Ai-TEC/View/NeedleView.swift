//
//  NeedleView.swift
//  Ai-Tec
//
//  Created by Nguyễn Đình Phú on 12/18/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit

class NeedleView: UIView {
    var halfFrameWidth : CGFloat = 0
    var fullFrameWidth : CGFloat = 0
    let needleBottomWith : CGFloat = 10.0
    var needleLength: CGFloat = 0
    var centerView: CGPoint?
    
    override func draw(_ rect: CGRect) {
        halfFrameWidth = self.bounds.width/2
        fullFrameWidth = self.bounds.width
        needleLength = halfFrameWidth * 0.5
        centerView = CGPoint(x: halfFrameWidth, y: halfFrameWidth)
        
        // tao kim cho la ban
        createNeedle()
    }
    
    func createNeedle(){
        let upperNeedle = UIBezierPath()
        upperNeedle.move(to: CGPoint(x: halfFrameWidth - needleBottomWith, y: halfFrameWidth))
        upperNeedle.addLine(to: CGPoint(x: halfFrameWidth, y: needleLength))
        upperNeedle.addLine(to: CGPoint(x: halfFrameWidth + needleBottomWith, y: halfFrameWidth))
        upperNeedle.close()
        UIColor.red.setFill()
        upperNeedle.fill()
        
        let bottomNeedle = UIBezierPath()
        bottomNeedle.move(to: CGPoint(x: halfFrameWidth - needleBottomWith, y: halfFrameWidth))
        bottomNeedle.addLine(to: CGPoint(x: halfFrameWidth, y: fullFrameWidth - needleLength))
        bottomNeedle.addLine(to: CGPoint(x: halfFrameWidth + needleBottomWith, y: halfFrameWidth))
        bottomNeedle.close()
        UIColor.blue.setFill()
        bottomNeedle.fill()
        
        let centerPin = UIBezierPath(arcCenter: centerView!, radius: 5.0, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        UIColor.darkGray.setFill()
        centerPin.fill()
    }
}
