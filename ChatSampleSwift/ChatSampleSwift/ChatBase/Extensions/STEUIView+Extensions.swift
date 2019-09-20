//
//  STEUIViewExtension.swift
//  ChatSampleSwift
//
//  Created by HoangDuoc on 12/24/18.
//  Copyright © 2018 HoangDuoc. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    /// Apply given views as masks
    ///
    /// - Parameter views: Views to apply as mask.
    /// ## Note: The view calling this function must have all the views in the given array as subviews.
    func setMaskingViews(_ views:[UIView]){
        
        let mutablePath = CGMutablePath()
        
        //Append path for each subview
        views.forEach { (view) in
            guard self.subviews.contains(view) else{
                fatalError("View:\(view) is not a subView of \(self). Therefore, it cannot be a masking view.")
            }
            //Check if ellipse
            if view.layer.cornerRadius == view.frame.size.height / 2, view.layer.masksToBounds{
                //Ellipse
                mutablePath.addEllipse(in: view.frame)
            }else{
                //Rect
                mutablePath.addRect(view.frame)
            }
        }
        
        //Create layer
        let maskLayer = CAShapeLayer()
        maskLayer.path = mutablePath
        
        //Apply layer as a mask
        self.layer.mask = maskLayer
    }
    
    func getSafeAreaInsets() -> UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return self.safeAreaInsets
        } else {
            return .zero
        }
    }
    
    func addBorderAt(edge: CAEdgeAntialiasingMask, color: UIColor) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        switch edge {
        case .layerTopEdge:
            border.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 0.5)
            break
        case .layerLeftEdge:
            border.frame = CGRect(x: 0, y: 0, width: 1.0, height: self.frame.size.height)
            break
        case .layerBottomEdge:
            border.frame = CGRect(x: 0, y: self.frame.height - 1.0, width: self.frame.width, height: 1.0)
            break
        case .layerRightEdge:
            border.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 1.0)
            break
        default:
            break
        }
        
        self.layer.addSublayer(border)
    }
    
    func round() {
        self.layer.cornerRadius = self.frame.width / 2
        self.clipsToBounds = true
    }
    
    // Round Corners
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let cornerPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        //Create a new layer to use as a mask
        let maskLayer = CAShapeLayer();
        
        // Set the path of the layer
        maskLayer.path = cornerPath.cgPath;
        self.layer.mask = maskLayer;
    }
}
