//
//  LoadingIndicatorView.swift
//  WebSnapshot
//
//  Created by Antelis on 11/07/2017.
//  Copyright © 2017 shion. All rights reserved.
//

import Foundation
import UIKit

public enum LoadingIndicatorViewGlowMode {
    case forward, reverse, constant, noGlow
}

@IBDesignable
public class LoadingIndicatorView: UIView, CAAnimationDelegate {
    
    private enum Conversion {
        static func degreesToRadians (value: CGFloat) -> CGFloat {
            return value * CGFloat.pi / 180.0
        }
    }
    
    private enum Utility {
        static func clamp<T: Comparable>(value: T, minMax: (T, T)) -> T {
            let (min, max) = minMax
            if value < min {
                return min
            } else if value > max {
                return max
            } else {
                return value
            }
        }
        
        static func inverseLerp(value: CGFloat, minMax: (CGFloat, CGFloat)) -> CGFloat {
            return (value - minMax.0) / (minMax.1 - minMax.0)
        }
        
        static func lerp(value: CGFloat, minMax: (CGFloat, CGFloat)) -> CGFloat {
            return (minMax.1 - minMax.0) * value + minMax.0
        }
        
        static func colorLerp(value: CGFloat, minMax: (UIColor, UIColor)) -> UIColor {
            let clampedValue = clamp(value: value, minMax: (0, 1))
            
            let zero = CGFloat(0)
            
            var (r0, g0, b0, a0) = (zero, zero, zero, zero)
            minMax.0.getRed(&r0, green: &g0, blue: &b0, alpha: &a0)
            
            var (r1, g1, b1, a1) = (zero, zero, zero, zero)
            minMax.1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            
            return UIColor(red: lerp(value: clampedValue, minMax: (r0, r1)), green: lerp(value: clampedValue, minMax: (g0, g1)), blue: lerp(value: clampedValue, minMax: (b0, b1)), alpha: lerp(value: clampedValue, minMax: (a0, a1)))
        }
        
        static func mod(value: Double, range: Double, minMax: (Double, Double)) -> Double {
            let (min, max) = minMax
            assert(abs(range) <= abs(max - min), "range should be <= than the interval")
            if value >= min && value <= max {
                return value
            } else if value < min {
                return mod(value: value + range, range: range, minMax: minMax)
            } else {
                return mod(value: value - range, range: range, minMax: minMax)
            }
        }
    }
    
    private var progressLayer: LoadingIndicatorViewLayer? {
        get {
            if let layer = layer as? LoadingIndicatorViewLayer {
                return layer
            }
            return nil
        }
    }
    
    private var radius: CGFloat = 0 {
        didSet {
            if let p = progressLayer {
                p.radius = radius
            }
        }
    }
    
    
    public var clockwise: Bool = true
    public var roundedCorners: Bool = true
    public var lerpColorMode: Bool = false
    
    @IBInspectable public var gradientRotateSpeed: CGFloat = 0 {
        didSet {
            if let p = progressLayer {
                p.gradientRotateSpeed = gradientRotateSpeed
            }
        }
    }
    
    public var glowMode: LoadingIndicatorViewGlowMode = .forward
    
    public var progressThickness: CGFloat = 0.4
    public var trackThickness: CGFloat = 0.5
    public var trackColor: UIColor = .black
    
    public var progressColors: [UIColor] {
        get {
            if let p = progressLayer {
                return p.colorsArray
            }
            return []
        }
        
        set {
            set(colors: newValue)
        }
    }
    
    //These are used only from the Interface-Builder. Changing these from code will have no effect.
    //Also IB colors are limited to 3, whereas programatically we can have an arbitrary number of them.
    @objc @IBInspectable private var IBColor1: UIColor?
    @objc @IBInspectable private var IBColor2: UIColor?
    @objc @IBInspectable private var IBColor3: UIColor?
    
    private var animationCompletionBlock: ((Bool) -> Void)?
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setInitialValues()
        refreshValues()
        checkAndSetIBColors()
    }
    
    convenience public init(frame: CGRect, colors: UIColor...) {
        self.init(frame: frame)
        set(colors: colors)
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        translatesAutoresizingMaskIntoConstraints = false
        setInitialValues()
        refreshValues()
    }
    
    public override func awakeFromNib() {
        checkAndSetIBColors()
    }
    
    override public class var layerClass: AnyClass {
        return LoadingIndicatorViewLayer.self
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        radius = (frame.size.width/2.0) * 0.8
    }
    
    private func setInitialValues() {
        radius = (frame.size.width/2.0) * 0.8 //We always apply a 20% padding, stopping glows from being clipped
        backgroundColor = .clear
        set(colors: .white, .cyan)
    }
    
    private func refreshValues() {
        if let progressLayer = progressLayer {
            progressLayer.angle = 0
            progressLayer.clockwise = clockwise
            progressLayer.roundedCorners = roundedCorners
            progressLayer.lerpColorMode = lerpColorMode
            progressLayer.gradientRotateSpeed = gradientRotateSpeed
            progressLayer.glowMode = glowMode
            progressLayer.progressThickness = progressThickness/2
            progressLayer.trackColor = trackColor
            progressLayer.trackThickness = trackThickness/2
        }
    }
    
    private func checkAndSetIBColors() {
        let nonNilColors = [IBColor1, IBColor2, IBColor3].compactMap { $0 }
        if !nonNilColors.isEmpty {
            set(colors: nonNilColors)
        }
    }
    
    public func set(colors: UIColor...) {
        set(colors: colors)
    }
    
    private func set(colors: [UIColor]) {
        if let progressLayer = progressLayer {
            progressLayer.colorsArray = colors
            progressLayer.setNeedsDisplay()
        }
    }
    
    public func startAnimation() {
        animate(duration: 1, relativeDuration: false, completion:nil)
    }
    
    public func animate(duration: TimeInterval, relativeDuration: Bool = true, completion: ((Bool) -> Void)?) {
        if isAnimating() {
            pauseAnimation()
        }
        
        let animationDuration: TimeInterval
        if relativeDuration {
            animationDuration = duration
        } else {
            let traveledAngle = Utility.mod(value: 360, range: 360, minMax: (0, 360))
            let scaledDuration = (TimeInterval(traveledAngle) * duration) / 360
            animationDuration = scaledDuration
        }
        
        let animation = CABasicAnimation(keyPath: "angle")
        animation.fromValue = 0
        animation.toValue = 360
        animation.duration = animationDuration
        animation.repeatCount = .infinity
        animation.delegate = self
        animation.isRemovedOnCompletion = false
        animationCompletionBlock = completion
        if let progressLayer = progressLayer {
            progressLayer.add(animation, forKey: "angle")
        }
    }
    
    public func pauseAnimation() {
        if let progressLayer = progressLayer {
            progressLayer.removeAllAnimations()
        }
    }
    
    public func stopAnimation() {
        if let progressLayer = progressLayer {
            progressLayer.removeAllAnimations()
        }
    }
    
    public func isAnimating() -> Bool {
        if let progressLayer = progressLayer {
            return progressLayer.animation(forKey: "angle") != nil
        }
        
        return false
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let completionBlock = animationCompletionBlock {
            animationCompletionBlock = nil
            completionBlock(flag)
        }
    }
    
    public override func didMoveToWindow() {
        if let window = window, let progressLayer = progressLayer {
            progressLayer.contentsScale = window.screen.scale
        }
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil && isAnimating() {
            pauseAnimation()
        }
    }
    
    public override func prepareForInterfaceBuilder() {
        setInitialValues()
        refreshValues()
        checkAndSetIBColors()
        if let progressLayer = progressLayer {
            progressLayer.setNeedsDisplay()
        }
    }
    
    private class LoadingIndicatorViewLayer: CALayer {
        @NSManaged var angle: Double
        var radius: CGFloat = 0 {
            didSet {
                invalidateGradientCache()
            }
        }
        var startAngle: Double = 0
        var clockwise: Bool = true {
            didSet {
                if clockwise != oldValue {
                    invalidateGradientCache()
                }
            }
        }
        var roundedCorners: Bool = true
        var lerpColorMode: Bool = false
        var gradientRotateSpeed: CGFloat = 0 {
            didSet {
                invalidateGradientCache()
            }
        }
        var glowMode: LoadingIndicatorViewGlowMode = .forward
        var progressThickness: CGFloat = 0.5
        var trackThickness: CGFloat = 0.5
        var trackColor: UIColor = .black
        var progressInsideFillColor: UIColor = .clear
        var colorsArray: [UIColor] = [] {
            didSet {
                invalidateGradientCache()
            }
        }
        private var gradientCache: CGGradient?
        private var locationsCache: [CGFloat]?
        
        private enum GlowConstants {
            private static let sizeToGlowRatio: CGFloat = 0.00015
            static func glowAmount(forAngle angle: Double, glowMode: LoadingIndicatorViewGlowMode, size: CGFloat) -> CGFloat {
                switch glowMode {
                case .forward:
                    return CGFloat(angle) * size * sizeToGlowRatio*2.0
                case .reverse:
                    return CGFloat(360 - angle) * size * sizeToGlowRatio*2.0
                case .constant:
                    return 360 * size * sizeToGlowRatio*2.0
                default:
                    return 0
                }
            }
        }
        
        override class func needsDisplay(forKey key: String) -> Bool {
            return key == "angle" ? true : super.needsDisplay(forKey: key)
        }
        
        override init(layer: Any) {
            super.init(layer: layer)
            if let progressLayer = layer as? LoadingIndicatorViewLayer {
                radius = progressLayer.radius
                angle = progressLayer.angle
                startAngle = progressLayer.startAngle
                clockwise = progressLayer.clockwise
                roundedCorners = progressLayer.roundedCorners
                lerpColorMode = progressLayer.lerpColorMode
                gradientRotateSpeed = progressLayer.gradientRotateSpeed
                glowMode = progressLayer.glowMode
                progressThickness = progressLayer.progressThickness
                trackThickness = progressLayer.trackThickness
                trackColor = progressLayer.trackColor
                colorsArray = progressLayer.colorsArray
                progressInsideFillColor = progressLayer.progressInsideFillColor
            }
        }
        
        override init() {
            super.init()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        override func draw(in ctx: CGContext) {
            UIGraphicsPushContext(ctx)
            
            let size = bounds.size
            let width = size.width
            let height = size.height
            
            let trackLineWidth = radius * trackThickness
            let progressLineWidth = radius * progressThickness
            let arcRadius = max(radius - trackLineWidth/2, radius - progressLineWidth/2)
            ctx.addArc(center: CGPoint(x: width/2.0, y: height/2.0), radius: arcRadius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)
            trackColor.set()
            ctx.setStrokeColor(trackColor.cgColor)
            ctx.setFillColor(progressInsideFillColor.cgColor)
            ctx.setLineWidth(trackLineWidth)
            ctx.setLineCap(CGLineCap.butt)
            ctx.drawPath(using: .fillStroke)
            
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            
            let imageCtx = UIGraphicsGetCurrentContext()
            let reducedAngle = Utility.mod(value: angle, range: 360, minMax: (0, 360))
            let fromAngle = Conversion.degreesToRadians(value: CGFloat(-startAngle))
            let toAngle = Conversion.degreesToRadians(value: CGFloat((clockwise == true ? -reducedAngle : reducedAngle) - startAngle))
            
            imageCtx?.addArc(center: CGPoint(x: width/2.0, y: height/2.0), radius: arcRadius, startAngle: fromAngle, endAngle: toAngle, clockwise: clockwise)
            
            let glowValue = GlowConstants.glowAmount(forAngle: reducedAngle, glowMode: glowMode, size: width)
            if glowValue > 0 {
                imageCtx?.setShadow(offset: CGSize.zero, blur: glowValue, color: UIColor.black.cgColor)
            }
            
            let linecap: CGLineCap = roundedCorners == true ? .round : .butt
            imageCtx?.setLineCap(linecap)
            imageCtx?.setLineWidth(progressLineWidth)
            imageCtx?.drawPath(using: .stroke)
            
            let drawMask: CGImage = UIGraphicsGetCurrentContext()!.makeImage()!
            UIGraphicsEndImageContext()
            
            ctx.saveGState()
            ctx.clip(to: bounds, mask: drawMask)
            
            //Gradient - Fill
            if !lerpColorMode && colorsArray.count > 1 {
                let rgbColorsArray: [UIColor] = colorsArray.map { color in // Make sure every color in colors array is in RGB color space
                    if color.cgColor.numberOfComponents == 2 {
                        if let whiteValue = color.cgColor.components?[0] {
                            return UIColor(red: whiteValue, green: whiteValue, blue: whiteValue, alpha: 1.0)
                        } else {
                            return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                        }
                    } else {
                        return color
                    }
                }
                
                let componentsArray = rgbColorsArray.flatMap { color -> [CGFloat] in
                    guard let components = color.cgColor.components else { return [] }
                    return [components[0], components[1], components[2], 1.0]
                }
                
                drawGradientWith(context: ctx, componentsArray: componentsArray)
            } else {
                var color: UIColor?
                if colorsArray.isEmpty {
                    color = UIColor.white
                } else if colorsArray.count == 1 {
                    color = colorsArray[0]
                } else {
                    // lerpColorMode is true
                    let t00 = CGFloat(reducedAngle) / 360
                    let steps = colorsArray.count - 1
                    let step = 1 / CGFloat(steps)
                    for i00 in 1...steps {
                        let fi0 = CGFloat(i00)
                        if t00 <= fi0 * step || i00 == steps {
                            let colorT = Utility.inverseLerp(value: t00, minMax: ((fi0 - 1) * step, fi0 * step))
                            color = Utility.colorLerp(value: colorT, minMax: (colorsArray[i00 - 1], colorsArray[i00]))
                            break
                        }
                    }
                }
                
                if let color = color {
                    fillRectWith(context: ctx, color: color)
                }
            }
            ctx.restoreGState()
            UIGraphicsPopContext()
        }
        
        private func fillRectWith(context: CGContext!, color: UIColor) {
            context.setFillColor(color.cgColor)
            context.fill(bounds)
        }
        
        private func drawGradientWith(context: CGContext!, componentsArray: [CGFloat]) {
            let baseSpace = CGColorSpaceCreateDeviceRGB()
            let locations = locationsCache ?? gradientLocationsFor(colorCount: componentsArray.count/4, gradientWidth: bounds.size.width)
            let gradient: CGGradient
            
            if let cachedGradient = gradientCache {
                gradient = cachedGradient
            } else {
                guard let cachedGradient = CGGradient(colorSpace: baseSpace, colorComponents: componentsArray, locations: locations, count: componentsArray.count/4) else {
                    return
                }
                
                gradientCache = cachedGradient
                gradient = cachedGradient
            }
            
            let halfX = bounds.size.width / 2.0
            let floatPi = CGFloat.pi
            let rotateSpeed = clockwise == true ? gradientRotateSpeed : gradientRotateSpeed * -1
            let angleInRadians = Conversion.degreesToRadians(value: rotateSpeed * CGFloat(angle) - 90)
            let oppositeAngle = angleInRadians > floatPi ? angleInRadians - floatPi : angleInRadians + floatPi
            
            let startPoint = CGPoint(x: (cos(angleInRadians) * halfX) + halfX, y: (sin(angleInRadians) * halfX) + halfX)
            let endPoint = CGPoint(x: (cos(oppositeAngle) * halfX) + halfX, y: (sin(oppositeAngle) * halfX) + halfX)
            
            context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: .drawsBeforeStartLocation)
        }
        
        private func gradientLocationsFor(colorCount: Int, gradientWidth: CGFloat) -> [CGFloat] {
            if colorCount == 0 || gradientWidth == 0 {
                return []
            } else {
                let progressLineWidth = radius * progressThickness
                let firstPoint = gradientWidth/2 - (radius - progressLineWidth/2)
                let increment = (gradientWidth - (2*firstPoint))/CGFloat(colorCount - 1)
                
                let locationsArray = (0..<colorCount).map { firstPoint + (CGFloat($0) * increment) }
                let result = locationsArray.map { $0 / gradientWidth }
                locationsCache = result
                return result
            }
        }
        
        private func invalidateGradientCache() {
            gradientCache = nil
            locationsCache = nil
        }
    }
}
