//
//  CompassView.swift
//  Ai-Tec
//
//  Created by Nguyễn Đình Phú on 12/17/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit

class CompassView: UIView {
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
       
        // tao cac diem cho la ban
        createRound()
    }
    
    func createRound() {
        let innerRing = UIBezierPath(arcCenter: centerView!, radius: halfFrameWidth - 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        UIColor.red.setStroke()
        innerRing.lineWidth = 2
        innerRing.stroke()
        
        let outerRing = UIBezierPath(arcCenter: centerView!, radius: (halfFrameWidth - 5) * 0.95, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        UIColor.red.setStroke()
        outerRing.lineWidth = 1
        outerRing.stroke()
        
        for degree in stride(from: 0, to: 360, by: 1){
            if degree == 270{
                let outerPoint = archLocationPoint(degree: CGFloat(degree), distance: 0.9)
                let innerPoint = archLocationPoint(degree: CGFloat(degree), distance: 0.7)
                let markLine = UIBezierPath()
                markLine.move(to: outerPoint)
                markLine.addLine(to: innerPoint)
                markLine.lineWidth = 5
                markLine.stroke()
                UIColor.red.setStroke()
            }
            if degree % 90 == 0 && degree != 270{
                let outerPoint = archLocationPoint(degree: CGFloat(degree), distance: 0.9)
                let innerPoint = archLocationPoint(degree: CGFloat(degree), distance: 0.8)
                let markLine = UIBezierPath()
                markLine.move(to: outerPoint)
                markLine.addLine(to: innerPoint)
                markLine.lineWidth = 4
                markLine.stroke()
                UIColor.red.setStroke()
            }
            if degree % 15 == 0 && degree % 90 != 0{
                let outerPoint = archLocationPoint(degree: CGFloat(degree), distance: 0.9)
                let innerPoint = archLocationPoint(degree: CGFloat(degree), distance: 0.8)
                let markLine = UIBezierPath()
                markLine.move(to: outerPoint)
                markLine.addLine(to: innerPoint)
                markLine.lineWidth = 2
                markLine.stroke()
                UIColor.red.setStroke()
            }else{
                let outerPoint = archLocationPoint(degree: CGFloat(degree), distance: 0.9)
                let innerPoint = archLocationPoint(degree: CGFloat(degree), distance: 0.85)
                let markLine = UIBezierPath()
                markLine.move(to: outerPoint)
                markLine.addLine(to: innerPoint)
                markLine.lineWidth = 1
                markLine.stroke()
                UIColor.red.setStroke()
            }
        }
    }
    
    func archLocationPoint(degree: CGFloat,distance:CGFloat) -> CGPoint{
        var location: CGPoint?
        let radian : CGFloat = degree * .pi / 180
        let arcPath = UIBezierPath(arcCenter: centerView!, radius: halfFrameWidth * distance, startAngle: 0, endAngle: radian, clockwise: true)
        location = arcPath.currentPoint
        return location!
    }
    
    
}
