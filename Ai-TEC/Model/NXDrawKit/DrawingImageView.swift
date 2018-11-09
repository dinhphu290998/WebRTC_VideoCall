//
//  DrawingImageView.swift
//  Ai-Tec
//
//  Created by vMio on 11/9/18.
//  Copyright © 2018 vMio. All rights reserved.
//

import UIKit

class DrawingImageView: UIImageView {
    var path = UIBezierPath()
    var previousTouchPoint = CGPoint.zero
    var shapeLayer = CAShapeLayer()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been  implemented")
    }
    
    func setupView() {
        self.layer.addSublayer(shapeLayer)
        self.shapeLayer.lineWidth = 4
        self.shapeLayer.strokeColor = UIColor.white.cgColor
        self.isUserInteractionEnabled = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let location = touches.first?.location(in: self) {
            previousTouchPoint = location
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        if let location = touches.first?.location(in: self) {
            path.move(to: location)
            path.addLine(to: previousTouchPoint)
            previousTouchPoint = location
            shapeLayer.path = path.cgPath
        }
    }
    
}

extension UIView {
    
    var screenShot: UIImage? {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale)
        if let context = UIGraphicsGetCurrentContext() {
            layer.render(in: context)
            let screenshot = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return screenshot
        }
        return nil
    }
}
