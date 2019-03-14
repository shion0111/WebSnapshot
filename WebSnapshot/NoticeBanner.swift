//
//  NoticeBanner.swift
//  WebSnapshot
//
//  Created by Antelis on 26/07/2017.
//  Copyright © 2017 shion. All rights reserved.
//

import UIKit

private enum NoticeBannerState {
    case displayed, hidden, finished
}

class NoticeBanner: UIView {
    private let backgroundView: UIView = {
       let view = UIView()
        view.backgroundColor = UIColor(red:0/255.0, green:152.0/255.0, blue:255.0/255.0, alpha:1.0)
       return view
    }()
    private let noticeLabel: UILabel = {
        let label = UILabel()
        //label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        label.textAlignment = .center
        return label
    }()
    
    open var bannerHeight: Int = 64
    
    // display duration of banner
    open var displayDuration: Double = 0.7
    // bounce parameters
    var animationSpringVal = (damping: 0.6, velocity: 1.70)
    
    //open var didTapBlock: (() -> ())?
    open var didDismissCallback: (() -> (Void))?
    
    private var state = NoticeBannerState.hidden {
        didSet {
            if state != oldValue {
                forceUpdates()
            }
        }
    }
    
    class func currentWindow() -> UIWindow? {
        for window in UIApplication.shared.windows.reversed() {
            if window.isKeyWindow && window.windowLevel == UIWindow.Level.normal &&  window.frame != CGRect.zero { return window }
        }
        return nil
    }
    
    public required init(message: String, dismissCallback: (() -> (Void))? = nil ) {
        
        self.didDismissCallback = dismissCallback
        self.noticeLabel.text = message
        super.init(frame: CGRect.zero)
        prepareBanner()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    private func prepareBanner() {
        translatesAutoresizingMaskIntoConstraints = false
        minimumHeightConstraint = backgroundView.constraintWithAttribute(.height, .greaterThanOrEqual, to: CGFloat(bannerHeight))
        //contentTopOffsetConstraint = self.constraintWithAttribute(.top, .equal, to: .top, of: backgroundView)
        
        self.addSubview(backgroundView)
        addConstraint(minimumHeightConstraint)
        addConstraint(backgroundView.constraintWithAttribute(.width, .lessThanOrEqual, to: UIScreen.main.bounds.size.width))
        addConstraints(backgroundView.constraintsEqualToSuperview())
        noticeLabel.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(noticeLabel)
        
        backgroundView.addConstraint(noticeLabel.constraintWithAttribute(.width, .lessThanOrEqual, to: UIScreen.main.bounds.size.width-30))
        backgroundView.addConstraint(noticeLabel.constraintWithAttribute(.leading, .equal, to: backgroundView, constant: 15.0))
        backgroundView.addConstraint(noticeLabel.constraintWithAttribute(.trailing, .equal, to: backgroundView, constant: 15.0))
        backgroundView.addConstraint(noticeLabel.constraintWithAttribute(.top, .equal, to: backgroundView, constant: 22.0))
        
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 4
        
    }
    private func addGestureRecognizers() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action:  #selector(NoticeBanner.didTap(_:))))
    }
    
    @objc internal func didTap(_ recognizer: UITapGestureRecognizer) {
        dismiss()
    }
    
    
    private var allConstraints = [NSLayoutConstraint]()
    private var displayedConstraint: NSLayoutConstraint?
    private var hiddenConstraint: NSLayoutConstraint?
    private var minimumHeightConstraint: NSLayoutConstraint!
    
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let superview = superview, state != .finished else { return }
        allConstraints = self.constraintsWithAttributes([.width], .equal, to: superview)
        superview.addConstraints(allConstraints)
        displayedConstraint = self.constraintWithAttribute(.top, .equal, to: .top, of: superview)
        let yOffset: CGFloat = -0.0 // Offset the bottom constraint to make room for the shadow to animate off screen.
        hiddenConstraint = self.constraintWithAttribute(.bottom, .equal, to: .top, of: superview, constant: yOffset)
        
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        superview?.layoutIfNeeded()
        layoutIfNeeded()
    }
    
    
    
    open func show(preaction:(() -> (Void))? = nil, predismissaction:(() -> (Void))? = nil) {
        
        guard let view = NoticeBanner.currentWindow() else {
            print("[NoticeBanner]: Could not find view.")
            return
        }
        view.addSubview(self)
        forceUpdates()
        let (damping, velocity) = self.animationSpringVal
        
        if preaction != nil { preaction?() }
        
        UIView.animate(withDuration: displayDuration, delay: 0.0, usingSpringWithDamping: CGFloat(damping), initialSpringVelocity: CGFloat(velocity), options: .allowUserInteraction, animations: {
            self.state = .displayed
        }, completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(Int(1000.0 * 2))) {
                if predismissaction != nil { predismissaction?() }
                self.dismiss()
            }
        })
    }
    open func dismiss() {
        let (damping, velocity) = self.animationSpringVal
        
        UIView.animate(withDuration: displayDuration, delay: 0.0, usingSpringWithDamping: CGFloat(damping), initialSpringVelocity: CGFloat(velocity), options: .allowUserInteraction, animations: {
            self.state = .hidden
            
        }, completion: { finished in
            self.state = .finished
            self.removeFromSuperview()
            self.didDismissCallback?()
        })
    }
    
    private func forceUpdates() {
        guard let superview = superview, let displayedConstraint = displayedConstraint, let hiddenConstraint = hiddenConstraint else { return }
        
        switch state {
        case .hidden:
            superview.removeConstraint(displayedConstraint)
            superview.addConstraint(hiddenConstraint)
        case .displayed:
            superview.removeConstraint(hiddenConstraint)
            superview.addConstraint(displayedConstraint)
        case .finished:
            superview.removeConstraint(hiddenConstraint)
            superview.removeConstraint(displayedConstraint)
            superview.removeConstraints(allConstraints)
        }
        
        setNeedsLayout()
        setNeedsUpdateConstraints()
        
        //superview.layoutIfNeeded()
        
        updateConstraintsIfNeeded()
        superview.layoutIfNeeded()
        
    }
}

extension NSLayoutConstraint {
    class func defaultConstraintsWithVisualFormat(_ format: String, options: NSLayoutConstraint.FormatOptions = NSLayoutConstraint.FormatOptions(), metrics: [String: AnyObject]? = nil, views: [String: AnyObject] = [:]) -> [NSLayoutConstraint] {
        return NSLayoutConstraint.constraints(withVisualFormat: format, options: options, metrics: metrics, views: views)
    }
}

extension UIView {
    func constraintsEqualToSuperview(_ edgeInsets: UIEdgeInsets = UIEdgeInsets.zero) -> [NSLayoutConstraint] {
        self.translatesAutoresizingMaskIntoConstraints = false
        var constraints = [NSLayoutConstraint]()
        if let superview = self.superview {
            constraints.append(self.constraintWithAttribute(.leading, .equal, to: superview, constant: edgeInsets.left))
            constraints.append(self.constraintWithAttribute(.trailing, .equal, to: superview, constant: edgeInsets.right))
            constraints.append(self.constraintWithAttribute(.top, .equal, to: superview, constant: edgeInsets.top))
            constraints.append(self.constraintWithAttribute(.bottom, .equal, to: superview, constant: edgeInsets.bottom))
        }
        return constraints
    }
    
    func constraintWithAttribute(_ attribute: NSLayoutConstraint.Attribute, _ relation: NSLayoutConstraint.Relation, to constant: CGFloat, multiplier: CGFloat = 1.0) -> NSLayoutConstraint {
        self.translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: attribute, relatedBy: relation, toItem: nil, attribute: .notAnAttribute, multiplier: multiplier, constant: constant)
    }
    
    func constraintWithAttribute(_ attribute: NSLayoutConstraint.Attribute, _ relation: NSLayoutConstraint.Relation, to otherAttribute: NSLayoutConstraint.Attribute, of item: AnyObject? = nil, multiplier: CGFloat = 1.0, constant: CGFloat = 0.0) -> NSLayoutConstraint {
        self.translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: attribute, relatedBy: relation, toItem: item ?? self, attribute: otherAttribute, multiplier: multiplier, constant: constant)
    }
    
    func constraintWithAttribute(_ attribute: NSLayoutConstraint.Attribute, _ relation: NSLayoutConstraint.Relation, to item: AnyObject, multiplier: CGFloat = 1.0, constant: CGFloat = 0.0) -> NSLayoutConstraint {
        self.translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: attribute, relatedBy: relation, toItem: item, attribute: attribute, multiplier: multiplier, constant: constant)
    }
    
    func constraintsWithAttributes(_ attributes: [NSLayoutConstraint.Attribute], _ relation: NSLayoutConstraint.Relation, to item: AnyObject, multiplier: CGFloat = 1.0, constant: CGFloat = 0.0) -> [NSLayoutConstraint] {
        return attributes.map { self.constraintWithAttribute($0, relation, to: item, multiplier: multiplier, constant: constant) }
    }
}
