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

// Adapted from https://github.com/lemanhtien/MTSlideToOpen

import UIKit
import Lottie
import TariCommon

enum SlideViewVariation {
    case slide
    case loading
}

final class SlideView: DynamicThemeView {
    static private let thumbnailMargin: CGFloat = 10
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private let pendingAnimationView = AnimationView()

    var onSlideToEnd: (() -> Void)?

    var variation: SlideViewVariation = .slide {
        didSet {
            updateVariationStyle()
        }
    }

    // MARK: All Views
    let textLabel: UILabel = {
        let label = UILabel.init()
        return label
    }()
    let sliderTextLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    let thumbnailImageView: UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = true
        view.contentMode = .center
        view.image = Theme.shared.images.forwardArrow
        view.layer.cornerRadius = 4.0
        return view
    }()
    let sliderHolderView: UIView = {
        let view = UIView()
        return view
    }()
    let draggedView: UIView = {
        let view = UIView()
        return view
    }()
    let view: UIView = {
        let view = UIView()
        return view
    }()

    @View private var gradientBackgroundView = GradientView()

    // MARK: properties

    var animationVelocity: Double = 0.2
    var sliderViewTopDistance: CGFloat = 0 {
        didSet {
            topSliderConstraint?.constant = sliderViewTopDistance
            layoutIfNeeded()
        }
    }

    var thumbnailViewTopDistance: CGFloat = SlideView.thumbnailMargin {
        didSet {
            topThumbnailViewConstraint?.constant = thumbnailViewTopDistance
            layoutIfNeeded()
        }
    }
    var thumbnailViewStartingDistance: CGFloat = SlideView.thumbnailMargin {
        didSet {
            leadingThumbnailViewConstraint?.constant = thumbnailViewStartingDistance
            trailingDraggedViewConstraint?.constant = thumbnailViewStartingDistance
            setNeedsLayout()
        }
    }
    var textLabelLeadingDistance: CGFloat = SlideView.thumbnailMargin {
        didSet {
            leadingTextLabelConstraint?.constant = textLabelLeadingDistance
            setNeedsLayout()
        }
    }
    var isEnabled: Bool = true {
        didSet {
            animationChangedEnabledBlock?(isEnabled)
            updateIsEnabledStyle()
        }
    }
    var showSliderText: Bool = true {
        didSet {
            sliderTextLabel.isHidden = !showSliderText
        }
    }
    var animationChangedEnabledBlock: ((Bool) -> Void)?
    // MARK: Default styles
    var sliderCornerRadius: CGFloat = 0 {
        didSet {
            sliderHolderView.layer.cornerRadius = sliderCornerRadius
            draggedView.layer.cornerRadius = sliderCornerRadius
        }
    }

    var labelText: String = "Slide" {
        didSet {
            textLabel.text = labelText
            sliderTextLabel.text = labelText
        }
    }
    var textFont: UIFont = Theme.shared.fonts.actionButton {
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
    private var xEndingPoint: CGFloat { self.view.frame.maxX - thumbnailImageView.bounds.width - thumbnailViewStartingDistance }
    private var isFinished: Bool = false

    override init() {
        super.init()
        setupView()
    }
    private var panGestureRecognizer: UIPanGestureRecognizer!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setupView()
    }

    private func setupView() {
        addSubview(view)
        view.addSubview(gradientBackgroundView)
        view.addSubview(thumbnailImageView)
        view.addSubview(sliderHolderView)
        view.addSubview(draggedView)
        draggedView.addSubview(sliderTextLabel)
        sliderHolderView.addSubview(textLabel)
        view.addSubview(pendingAnimationView)
        view.bringSubviewToFront(thumbnailImageView)
        setupConstraint()
        setStyle()
        // Add pan gesture
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(_:)))
        panGestureRecognizer.minimumNumberOfTouches = 1
        thumbnailImageView.addGestureRecognizer(panGestureRecognizer)

        thumbnailViewStartingDistance = SlideView.thumbnailMargin
    }

    private func setupConstraint() {
        view.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
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
        leadingThumbnailViewConstraint = thumbnailImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        leadingThumbnailViewConstraint?.isActive = true
        topThumbnailViewConstraint = thumbnailImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: thumbnailViewTopDistance)
        topThumbnailViewConstraint?.isActive = true
        thumbnailImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        thumbnailImageView.heightAnchor.constraint(equalTo: thumbnailImageView.widthAnchor).isActive = true
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
        trailingDraggedViewConstraint = draggedView.trailingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: thumbnailViewStartingDistance)
        trailingDraggedViewConstraint?.isActive = true

        heightAnchor.constraint(equalToConstant: 60).isActive = true

        pendingAnimationView.backgroundBehavior = .pauseAndRestore
        pendingAnimationView.animation = Animation.named(.pendingCircleAnimation)

        pendingAnimationView.translatesAutoresizingMaskIntoConstraints = false
        pendingAnimationView.widthAnchor.constraint(equalToConstant: 45).isActive = true
        pendingAnimationView.heightAnchor.constraint(equalToConstant: 45).isActive = true
        pendingAnimationView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        pendingAnimationView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        pendingAnimationView.isHidden = true

        let constraints = [
            gradientBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            gradientBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setStyle() {

        textLabel.text = labelText
        textLabel.font = textFont
        textLabel.textAlignment = .center

        sliderTextLabel.text = labelText
        sliderTextLabel.font = textFont
        sliderTextLabel.textAlignment = .center
        sliderTextLabel.isHidden = !showSliderText

        sliderHolderView.layer.cornerRadius = sliderCornerRadius
        draggedView.backgroundColor = .clear
        draggedView.layer.cornerRadius = sliderCornerRadius
        draggedView.clipsToBounds = true
        draggedView.layer.masksToBounds = true
        draggedView.layer.cornerRadius = sliderCornerRadius
    }

    override func update(theme: ColorTheme) {
        super.update(theme: theme)

        gradientBackgroundView.locations = [
            GradientLocationData(color: theme.buttons.primaryStart, location: 0.0),
            GradientLocationData(color: theme.buttons.primaryEnd, location: 1.0)
        ]

        updateSliderState(theme: theme)
    }

    private func updateSliderState(theme: ColorTheme) {
        sliderTextLabel.textColor = isEnabled ? .clear : theme.buttons.disabled
        sliderHolderView.backgroundColor = isEnabled ? .clear : theme.buttons.disabled
        textLabel.textColor = isEnabled ? .Static.white : theme.buttons.disabledText

        thumbnailImageView.backgroundColor = isEnabled ? theme.buttons.primaryText : theme.buttons.disabledText
        thumbnailImageView.tintColor = isEnabled ? theme.brand.purple : theme.buttons.disabled
        thumbnailImageView.apply(shadow: isEnabled ? theme.shadows.box : .none)
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
        case .ended:
            if translatedPoint >= xEndingPoint / 2 {
                textLabel.alpha = 0
                updateThumbnailXPosition(xEndingPoint)
                // Finish action
                isFinished = true
                impactFeedbackGenerator.impactOccurred()
                onSlideToEnd?()
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
        default:
            break
        }
    }
    // Others
    private func updateVariationStyle() {
        switch variation {
        case .loading:
            pendingAnimationView.isHidden = false
            textLabel.isHidden = true
            sliderTextLabel.isHidden = true
            thumbnailImageView.isHidden = true
            gradientBackgroundView.isHidden = false
            pendingAnimationView.play(fromProgress: 0, toProgress: 1, loopMode: .loop)
        case .slide:
            pendingAnimationView.isHidden = true
            textLabel.isHidden = false
            sliderTextLabel.isHidden = false
            thumbnailImageView.isHidden = false
            pendingAnimationView.stop()
            updateIsEnabledStyle()
        }
    }

    private func updateIsEnabledStyle() {
        gradientBackgroundView.isHidden = !isEnabled
        updateSliderState(theme: theme)
    }
}
