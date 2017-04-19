//
//  SpinnerView.swift
//  edX
//
//  Created by Akiva Leffert on 6/3/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

private var startTime : NSTimeInterval?

private let animationKey = "org.edx.spin"


@objc public class SpinnerView : UIView {
    @objc public enum SpinSize:Int, RawRepresentable {
        case Small
        case Medium
        case Large

        public typealias RawValue = String
        public var rawValue: RawValue {
            switch self {
            case .Small:
                return "SMALL"
            case .Medium:
                return "MEDIUM"
            case .Large:
                return "LARGE"
            }
        }
        public init?(rawValue: RawValue) {
            switch rawValue {
            case "SMALL":
                self = .Small
            case "MEDIUM":
                self = .Medium
            case "Large":
                self = .Large
            default:
                self = .Large
            }
        }
    }

    @objc public enum Color:Int, RawRepresentable {
        case Primary
        case White

        private var value : UIColor {
            switch self {
            case Primary: return OEXStyles.sharedStyles().primaryBaseColor()
            case White: return OEXStyles.sharedStyles().neutralWhite()
            }
        }
        public typealias RawValue = String
        public var rawValue: RawValue {
            switch self {
            case .Primary:
                return "PRIMARY"
            case .White:
                return "WHITE"
            }
        }
        public init?(rawValue: RawValue) {
            switch rawValue {
            case "PRIMARY":
                self = .Primary
            case "WHITE":
                self = .White
            default:
                self = .Primary
            }
        }
    }



//public class SpinnerView : UIView {
//    
//    public enum Size {
//        case Small
//        case Medium
//        case Large
//    }
//    
//    public enum Color {
//        case Primary
//        case White
//        
//        private var value : UIColor {
//            switch self {
//            case Primary: return OEXStyles.sharedStyles().primaryBaseColor()
//            case White: return OEXStyles.sharedStyles().neutralWhite()
//            }
//        }
//    }

    private let content = UIImageView()
    private let size : SpinSize
    private var stopped : Bool = false {
        didSet {
            if hidesWhenStopped {
                self.hidden = stopped
            }
        }
    }
    
    public var hidesWhenStopped = false
    
     public init(size : SpinSize, color : Color) {
        self.size = size
        super.init(frame : CGRectZero)
        addSubview(content)
        content.image = Icon.Spinner.imageWithFontSize(30)
        content.tintColor = color.value
        content.contentMode = .ScaleAspectFit
    }
    
    public override class func requiresConstraintBasedLayout() -> Bool {
        return true
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        content.frame = self.bounds
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func didMoveToWindow() {
        if !stopped {
            addSpinAnimation()
        }
        else {
            removeSpinAnimation()
        }
    }
    
    public override func intrinsicContentSize() -> CGSize {
        switch size {
        case .Small:
            return CGSizeMake(12, 12)
        case .Medium:
            return CGSizeMake(18, 18)
        case .Large:
            return CGSizeMake(24, 24)
        }
    }
    
    private func addSpinAnimation() {
        if let window = self.window {
            let animation = CAKeyframeAnimation(keyPath: "transform.rotation")
            let dots = 8
            let direction : Double = UIApplication.sharedApplication().userInterfaceLayoutDirection == .LeftToRight ? 1 : -1
            animation.keyTimes = Array(count: dots) {
                return (Double($0) / Double(dots)) as NSNumber
            }
            animation.values = Array(count: dots) {
                return (direction * Double($0) / Double(dots)) * 2.0 * M_PI as NSNumber
            }
            animation.repeatCount = Float.infinity
            animation.duration = 0.6
            animation.additive = true
            animation.calculationMode = kCAAnimationDiscrete
            /// Set time to zero so they all sync up
            animation.beginTime = window.layer.convertTime(0, toLayer: self.layer)
            self.content.layer.addAnimation(animation, forKey: animationKey)
        }
        else {
            removeSpinAnimation()
        }
    }
    
    private func removeSpinAnimation() {
        self.content.layer.removeAnimationForKey(animationKey)
    }
    
    public func startAnimating() {
        if stopped {
            addSpinAnimation()
        }
        stopped = false
    }
    
    public func stopAnimating() {
        removeSpinAnimation()
        stopped = true
    }
}
