//  SlideView.swift

/*
    Package MobileWallet
    Created by Jason van den Berg on 2020/02/26
    Using Swift 5.0
    Running on macOS 10.15

    Copyright 2019 The Tari Project

    Redistribution and use in source and binary forms, with or
    without modification, are permitted provided that the
    following conditions are met:

    1. Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above
    copyright notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of
    its contributors may be used to endorse or promote products
    derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
    CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
    OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
    CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
    NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
    HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
    OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

//Adapted from https://github.com/lemanhtien/MTSlideToOpen

import UIKit

@objc public protocol SlideViewDelegate {
    func slideViewDidFinish(_ sender: SlideView)
}

@objcMembers public class SlideView: UIView {
    static private let thumbnailMargin: CGFloat = 5
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    static private let thumbnailShadowRadius: Float = 0.5

    // MARK: All Views
    public let textLabel: UILabel = {
        let label = UILabel.init()
        return label
    }()
    public let sliderTextLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    public let thumnailImageView: UIImageView = {
        let view = SlideViewRoundImageView()
        view.isUserInteractionEnabled = true
        view.contentMode = .center

        view.layer.shadowOpacity = thumbnailShadowRadius
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.shadowRadius = SlideView.thumbnailMargin
        view.layer.shadowColor = Theme.shared.colors.gradientEndColor!.cgColor

        view.image = Theme.shared.images.forwardArrow
        return view
    }()
    public let sliderHolderView: UIView = {
        let view = UIView()
        return view
    }()
    public let draggedView: UIView = {
        let view = UIView()
        return view
    }()
    public let view: UIView = {
        let view = UIView()
        return view
    }()

    // MARK: Public properties
    public weak var delegate: SlideViewDelegate?
    public var animationVelocity: Double = 0.2
    public var sliderViewTopDistance: CGFloat = 0 {
        didSet {
            topSliderConstraint?.constant = sliderViewTopDistance
            layoutIfNeeded()
        }
    }

    public var thumbnailViewTopDistance: CGFloat = SlideView.thumbnailMargin {
        didSet {
            topThumbnailViewConstraint?.constant = thumbnailViewTopDistance
            layoutIfNeeded()
        }
    }
    public var thumbnailViewStartingDistance: CGFloat = SlideView.thumbnailMargin {
        didSet {
            leadingThumbnailViewConstraint?.constant = thumbnailViewStartingDistance
            trailingDraggedViewConstraint?.constant = thumbnailViewStartingDistance
            setNeedsLayout()
        }
    }
    public var textLabelLeadingDistance: CGFloat = SlideView.thumbnailMargin {
        didSet {
            leadingTextLabelConstraint?.constant = textLabelLeadingDistance
            setNeedsLayout()
        }
    }
    public var isEnabled: Bool = true {
        didSet {
            animationChangedEnabledBlock?(isEnabled)

            if isEnabled {
                sliderBackgroundColor = .clear// Theme.shared.colors.actionButtonBackgroundSimple!
                //slidingColor = Theme.shared.colors.actionButtonBackgroundSimple!
                textColor = Theme.shared.colors.actionButtonTitle!
                thumnailImageView.image = thumnailImageView.image?.withTintColor(Theme.shared.colors.actionButtonBackgroundSimple!)
                thumnailImageView.layer.shadowOpacity = SlideView.thumbnailShadowRadius
                sliderHolderView.applyGradient()
            } else {
                sliderBackgroundColor = Theme.shared.colors.actionButtonBackgroundDisabled!
                //slidingColor = Theme.shared.colors.actionButtonBackgroundDisabled!
                textColor = Theme.shared.colors.actionButtonTitleDisabled!
                thumnailImageView.image = thumnailImageView.image?.withTintColor(Theme.shared.colors.actionButtonTitleDisabled!)
                thumnailImageView.layer.shadowOpacity = 0
                sliderHolderView.removeGradient()
            }
        }
    }
    public var showSliderText: Bool = true {
        didSet {
            sliderTextLabel.isHidden = !showSliderText
        }
    }
    public var animationChangedEnabledBlock: ((Bool) -> Void)?
    // MARK: Default styles
    public var sliderCornerRadius: CGFloat = ActionButton.RADIUS_POINTS {
        didSet {
            sliderHolderView.layer.cornerRadius = sliderCornerRadius
            draggedView.layer.cornerRadius = sliderCornerRadius
        }
    }
    public var sliderBackgroundColor: UIColor = .clear {
        didSet {
            sliderHolderView.backgroundColor = sliderBackgroundColor
            sliderTextLabel.textColor = sliderBackgroundColor
        }
    }

    public var textColor: UIColor = Theme.shared.colors.actionButtonTitle! {
        didSet {
            textLabel.textColor = textColor
        }
    }

    public var slidingColor: UIColor = .clear {
        didSet {
            draggedView.backgroundColor = slidingColor
        }
    }
    public var thumbnailColor: UIColor = Theme.shared.colors.actionButtonTitle! {
        didSet {
            thumnailImageView.backgroundColor = thumbnailColor
        }
    }
    public var labelText: String = "Slide" {
        didSet {
            textLabel.text = labelText
            sliderTextLabel.text = labelText
        }
    }
    public var textFont: UIFont = Theme.shared.fonts.actionButton! {
        didSet {
            textLabel.font = textFont
            sliderTextLabel.font = textFont
        }
    }
    // MARK: Private Properties
    private var leadingThumbnailViewConstraint: NSLayoutConstraint?
    private var leadingTextLabelConstraint: NSLayoutConstraint?
    private var topSliderConstraint: NSLayoutConstraint?
    private var topThumbnailViewConstraint: NSLayoutConstraint?
    private var trailingDraggedViewConstraint: NSLayoutConstraint?
    private var xPositionInThumbnailView: CGFloat = 0
    private var xEndingPoint: CGFloat {
        get {
            return (self.view.frame.maxX - thumnailImageView.bounds.width - thumbnailViewStartingDistance)
        }
    }
    private var isFinished: Bool = false

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    private var panGestureRecognizer: UIPanGestureRecognizer!

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupView()
    }

    private func setupView() {
        self.addSubview(view)
        view.addSubview(thumnailImageView)
        view.addSubview(sliderHolderView)
        view.addSubview(draggedView)
        draggedView.addSubview(sliderTextLabel)
        sliderHolderView.addSubview(textLabel)
        view.bringSubviewToFront(self.thumnailImageView)
        setupConstraint()
        setStyle()
        // Add pan gesture
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(_:)))
        panGestureRecognizer.minimumNumberOfTouches = 1
        thumnailImageView.addGestureRecognizer(panGestureRecognizer)

        thumbnailViewStartingDistance = SlideView.thumbnailMargin
    }

    private func setupConstraint() {
        view.translatesAutoresizingMaskIntoConstraints = false
        thumnailImageView.translatesAutoresizingMaskIntoConstraints = false
        sliderHolderView.translatesAutoresizingMaskIntoConstraints = false
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        sliderTextLabel.translatesAutoresizingMaskIntoConstraints = false
        draggedView.translatesAutoresizingMaskIntoConstraints = false
        // Setup for view
        view.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        // Setup for circle View
        leadingThumbnailViewConstraint = thumnailImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        leadingThumbnailViewConstraint?.isActive = true
        topThumbnailViewConstraint = thumnailImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: thumbnailViewTopDistance)
        topThumbnailViewConstraint?.isActive = true
        thumnailImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        thumnailImageView.heightAnchor.constraint(equalTo: thumnailImageView.widthAnchor).isActive = true
        // Setup for slider holder view
        topSliderConstraint = sliderHolderView.topAnchor.constraint(equalTo: view.topAnchor, constant: sliderViewTopDistance)
        topSliderConstraint?.isActive = true
        sliderHolderView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        sliderHolderView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        sliderHolderView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        // Setup for textLabel
        textLabel.topAnchor.constraint(equalTo: sliderHolderView.topAnchor).isActive = true
        textLabel.centerYAnchor.constraint(equalTo: sliderHolderView.centerYAnchor).isActive = true
        leadingTextLabelConstraint = textLabel.leadingAnchor.constraint(equalTo: sliderHolderView.leadingAnchor, constant: textLabelLeadingDistance)
        leadingTextLabelConstraint?.isActive = true
        textLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: CGFloat(-8)).isActive = true
        // Setup for sliderTextLabel
        sliderTextLabel.topAnchor.constraint(equalTo: textLabel.topAnchor).isActive = true
        sliderTextLabel.centerYAnchor.constraint(equalTo: textLabel.centerYAnchor).isActive = true
        sliderTextLabel.leadingAnchor.constraint(equalTo: textLabel.leadingAnchor).isActive = true
        sliderTextLabel.trailingAnchor.constraint(equalTo: textLabel.trailingAnchor).isActive = true
        // Setup for Dragged View
        draggedView.leadingAnchor.constraint(equalTo: sliderHolderView.leadingAnchor).isActive = true
        draggedView.topAnchor.constraint(equalTo: sliderHolderView.topAnchor).isActive = true
        draggedView.centerYAnchor.constraint(equalTo: sliderHolderView.centerYAnchor).isActive = true
        trailingDraggedViewConstraint = draggedView.trailingAnchor.constraint(equalTo: thumnailImageView.trailingAnchor, constant: thumbnailViewStartingDistance)
        trailingDraggedViewConstraint?.isActive = true

        heightAnchor.constraint(equalToConstant: ActionButton.HEIGHT).isActive = true
    }

    private func setStyle() {
        thumnailImageView.backgroundColor = thumbnailColor
        textLabel.text = labelText
        textLabel.font = textFont
        textLabel.textColor = textColor
        textLabel.textAlignment = .center

        sliderTextLabel.text = labelText
        sliderTextLabel.font = textFont
        sliderTextLabel.textColor = sliderBackgroundColor
        sliderTextLabel.textAlignment = .center
        sliderTextLabel.isHidden = !showSliderText

        sliderHolderView.backgroundColor = sliderBackgroundColor
        sliderHolderView.layer.cornerRadius = sliderCornerRadius
        draggedView.backgroundColor = slidingColor
        draggedView.layer.cornerRadius = sliderCornerRadius
        draggedView.clipsToBounds = true
        draggedView.layer.masksToBounds = true
    }

    private func isTapOnThumbnailViewWithPoint(_ point: CGPoint) -> Bool {
        return self.thumnailImageView.frame.contains(point)
    }

    private func updateThumbnailXPosition(_ x: CGFloat) {
        leadingThumbnailViewConstraint?.constant = x
        setNeedsLayout()
    }

    // MARK: UIPanGestureRecognizer
    @objc private func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        if isFinished || !isEnabled {
            return
        }
        let translatedPoint = sender.translation(in: view).x
        switch sender.state {
        case .began:
            impactFeedbackGenerator.prepare()
            break
        case .changed:
            if translatedPoint >= xEndingPoint {
                updateThumbnailXPosition(xEndingPoint)
                return
            }
            if translatedPoint <= thumbnailViewStartingDistance {
                textLabel.alpha = 1
                updateThumbnailXPosition(thumbnailViewStartingDistance)
                return
            }
            updateThumbnailXPosition(translatedPoint)
            textLabel.alpha = (xEndingPoint - translatedPoint) / xEndingPoint
            break
        case .ended:
            if translatedPoint >= xEndingPoint {
                textLabel.alpha = 0
                updateThumbnailXPosition(xEndingPoint)
                // Finish action
                isFinished = true
                impactFeedbackGenerator.impactOccurred()
                delegate?.slideViewDidFinish(self)
                return
            }
            if translatedPoint <= thumbnailViewStartingDistance {
                textLabel.alpha = 1
                updateThumbnailXPosition(thumbnailViewStartingDistance)
                return
            }
            UIView.animate(withDuration: animationVelocity) {
                self.leadingThumbnailViewConstraint?.constant = self.thumbnailViewStartingDistance
                self.textLabel.alpha = 1
                self.layoutIfNeeded()
            }
            break
        default:
            break
        }
    }
    // Others
    public func resetStateWithAnimation(_ animated: Bool) {
        let action = {
            self.leadingThumbnailViewConstraint?.constant = self.thumbnailViewStartingDistance
            self.textLabel.alpha = 1
            self.layoutIfNeeded()
            //
            self.isFinished = false
        }
        if animated {
            UIView.animate(withDuration: animationVelocity) {
               action()
            }
        } else {
            action()
        }
    }
}

class SlideViewRoundImageView: UIImageView {
    override func layoutSubviews() {
        super.layoutSubviews()
        //let radius: CGFloat = self.bounds.size.width / 2.0
        self.layer.cornerRadius = ActionButton.RADIUS_POINTS
    }
}
