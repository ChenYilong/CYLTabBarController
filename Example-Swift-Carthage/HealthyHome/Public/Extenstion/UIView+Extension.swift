//
//  UIView+Extension.swift
//  SalesService
//
//  Created by 康洲 on 2019/10/10.
//  Copyright © 2019 康洲. All rights reserved.
//

import UIKit

extension UIView {
    //.x
    public var x: CGFloat {
        get {
            return self.frame.origin.x
        }
        set {
            var rect = self.frame
            rect.origin.x = newValue
            self.frame = rect
        }
    }
    
    //.y
    public var y: CGFloat {
        get {
            return self.frame.origin.y
        }
        set {
            var rect = self.frame
            rect.origin.y = newValue
            self.frame = rect
        }
    }
    
    //.maxX
    public var maxX: CGFloat {
        get {
            return self.frame.maxX
        }
    }
    
    //.maxY
    public var maxY: CGFloat {
        get {
            return self.frame.maxY
        }
    }
    
    //.centenrX
    public var centerX: CGFloat {
        get {
            return self.center.x
        }
        set {
            self.center = CGPoint(x: newValue, y: newValue)
        }
    }
    
    //.centerY
    public var centerY: CGFloat {
        get {
            return self.center.y
        }
        set {
            self.center = CGPoint(x: newValue, y: newValue)
        }
    }
    
    //.width
    public var width:CGFloat {
        get {
            return self.frame.size.width
        }
        set {
            var rect = self.frame
            rect.size.width = newValue
            self.frame = rect
        }
    }
    
    //.height
    public var height: CGFloat {
        get {
            return self.frame.size.height
        }
        set {
            var rect = self.frame
            rect.size.height = newValue
            self.frame = rect
        }
    }
}
