//  AnimatedBalanceLabel.swift

/*
    Package MobileWallet
    Created by Semih Cihan on 7.02.2020
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

import Foundation
import Foundation
import UIKit

class AnimatedBalanceLabel: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
    }

    var minimumScaleFactor: CGFloat = 0.0 {
        didSet {
            labels.forEach({ $0.minimumScaleFactor = minimumScaleFactor})
        }
    }

    var textAlignment: NSTextAlignment = .left {
        didSet {
            adjustLabelTextAlignment()
        }
    }

    var animationDuration = 0.2
    var delayBetweenCharacterAnimations = 0.05
    var slideAnimationDuration = 0.2

    private var animating = false

    private var labelsLeftLayoutGuide: UILayoutGuide = UILayoutGuide()
    private var labelsRightLayoutGuide: UILayoutGuide = UILayoutGuide()

    var attributedText: NSAttributedString? {
        didSet {
            updateDisplayedText()
        }
    }

    var displayedAttributedText: NSAttributedString?

    private var labels = [UILabel]()

    private func updateDisplayedText() {
        guard !animating else {
            return
        }

        guard let attributedText = attributedText else {
            clearLabels()
            displayedAttributedText = nil
            return
        }

        if displayedAttributedText == nil {
            displayedAttributedText = attributedText
            clearLabels()
            labels = createLabels(attributedText: displayedAttributedText!)
            layoutLabels()
        } else if !attributedText.isEqual(to: displayedAttributedText!) {
            animating = true
            displayedAttributedText = attributedText
            animateValueChange()
        }
    }

    private func clearLabels() {
        labels.forEach({$0.removeFromSuperview()})
        labels = [UILabel]()
    }

    private func createLabels(attributedText: NSAttributedString) -> [UILabel] {
        var createdLabels = [UILabel]()
        for i in 0..<attributedText.length {
            let label = createLabel()
            label.attributedText = attributedText.attributedSubstring(from: NSRange(location: i, length: 1))
            createdLabels.append(label)
        }
        return createdLabels
    }

    private func createLabel() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .left
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.backgroundColor = .clear
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func adjustLabelTextAlignment() {
        removeLayoutGuide(labelsLeftLayoutGuide)
        removeLayoutGuide(labelsRightLayoutGuide)
        labelsLeftLayoutGuide = UILayoutGuide()
        labelsRightLayoutGuide = UILayoutGuide()

        addLayoutGuide(labelsLeftLayoutGuide)
        labelsLeftLayoutGuide.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        labelsLeftLayoutGuide.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        labelsLeftLayoutGuide.heightAnchor.constraint(equalToConstant: 0).isActive = true

        addLayoutGuide(labelsRightLayoutGuide)
        labelsRightLayoutGuide.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        labelsRightLayoutGuide.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        labelsRightLayoutGuide.heightAnchor.constraint(equalToConstant: 0).isActive = true

        switch textAlignment {
        case .center:
            labelsLeftLayoutGuide.widthAnchor.constraint(equalTo: labelsRightLayoutGuide.widthAnchor).isActive = true
        case .right:
            labelsRightLayoutGuide.widthAnchor.constraint(equalToConstant: 0).isActive = true
        default:
            labelsLeftLayoutGuide.widthAnchor.constraint(equalToConstant: 0).isActive = true
        }

        if let firstLabel = labels.first, let lastLabel = labels.last, firstLabel.superview === labelsLeftLayoutGuide.owningView, lastLabel.superview === labelsRightLayoutGuide.owningView {
            firstLabel.leftAnchor.constraint(equalTo: labelsLeftLayoutGuide.rightAnchor).isActive = true
            lastLabel.rightAnchor.constraint(equalTo: labelsRightLayoutGuide.leftAnchor).isActive = true
        }
    }

    private func layoutLabels() {
        adjustLabelTextAlignment()

        for i in 0..<labels.count {
            let label = labels[i]
            addSubview(label)
            var leftAnc: NSLayoutXAxisAnchor!

            if i == 0 {
                let constraint = label.centerYAnchor.constraint(equalTo: centerYAnchor)
                constraint.isActive = true
                leftAnc = labelsLeftLayoutGuide.rightAnchor
            } else {
                let constraint = label.firstBaselineAnchor.constraint(equalTo: labels[i - 1].firstBaselineAnchor)
                constraint.isActive = true
                leftAnc = labels[i - 1].rightAnchor
            }
            label.leftAnchor.constraint(equalTo: leftAnc).isActive = true
        }

        labels.last?.rightAnchor.constraint(equalTo: labelsRightLayoutGuide.leftAnchor).isActive = true
        self.layoutIfNeeded()
    }

    private func enabledCharacterAnimations(displayedAttributedText: NSAttributedString) -> [Bool] {
        var oldText = labels.compactMap({$0.attributedText?.string ?? " "})
        var newText = displayedAttributedText.string.map({String($0)})
        var requiredAnimations = Array.init(repeating: true, count: max(oldText.count, newText.count))

        if oldText.count < newText.count {
            oldText.insert(contentsOf: Array.init(repeating: " ", count: newText.count - oldText.count), at: 0)
        } else if newText.count < oldText.count {
            newText.insert(contentsOf: Array.init(repeating: " ", count: oldText.count - newText.count), at: 0)
        }

        for i in 0..<requiredAnimations.count {
            requiredAnimations[i] = oldText[i] != newText[i]
        }
        return requiredAnimations
    }

    private func animateValueChange() {
        guard let displayedAttributedText = displayedAttributedText else {
            return
        }

        let oldLength = labels.count
        let newLength = displayedAttributedText.length
        let charactersRequiringAnimation = enabledCharacterAnimations(displayedAttributedText: displayedAttributedText)

        if newLength > oldLength {
            for i in oldLength..<newLength {
                let label = createLabel()
                label.isHidden = true
                label.attributedText = displayedAttributedText.attributedSubstring(from: NSRange(location: i - oldLength, length: 1))
                labels.insert(label, at: i - oldLength)
            }

            labels.forEach({$0.removeFromSuperview()})

            UIView.animate(withDuration: slideAnimationDuration, delay: 0, options: [.curveEaseIn], animations: { [weak self] in
                guard let self = self else {return}
                self.layoutLabels()
            }) { [weak self] (_) in
                guard let self = self else {return}
                var delay = 0.0
                for i in 0..<displayedAttributedText.string.count {
                    let requiresAnimation = charactersRequiringAnimation[i]
                    DispatchQueue.main.asyncAfter(deadline: .now() + (requiresAnimation ? delay : 0)) { [requiresAnimation, i] in
                        let label = self.labels[i]
                        label.attributedText = displayedAttributedText.attributedSubstring(from: NSRange(location: i, length: 1))
                        label.isHidden = false
                        if requiresAnimation {
                            self.pushTransition(self.animationDuration, layer: label.layer, transitionSubtype: .fromTop)
                        }
                    }
                    delay += requiresAnimation ? self.delayBetweenCharacterAnimations : 0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + delay + self.animationDuration) {
                    self.animating = false
                    self.updateDisplayedText()
                }
            }

        } else {
            var delay = 0.0
            for i in 0..<oldLength {
                let requiresAnimation = charactersRequiringAnimation[i]
                DispatchQueue.main.asyncAfter(deadline: .now() + (requiresAnimation ? delay : 0)) { [requiresAnimation, i, weak self] in
                    guard let self = self else {return}
                    let label = self.labels[i]
                    if i < oldLength - newLength {
                        UIView.animate(withDuration: self.animationDuration) {
                            label.isHidden = true
                        }
                    } else {
                        label.attributedText = displayedAttributedText.attributedSubstring(from: NSRange(location: i - (oldLength - newLength), length: 1))
                    }
                    if requiresAnimation {
                        self.pushTransition(self.animationDuration, layer: label.layer, transitionSubtype: i < oldLength - newLength ? .fromBottom : .fromTop)
                    }
                }
                delay += requiresAnimation ? self.delayBetweenCharacterAnimations : 0
            }

            let slideAnimationDelay = delay + self.animationDuration - self.delayBetweenCharacterAnimations
            DispatchQueue.main.asyncAfter(deadline: .now() + slideAnimationDelay) { [weak self] in
                guard let self = self else {return}

                for _ in 0..<oldLength - newLength {
                    self.labels.first?.removeFromSuperview()
                    self.labels.remove(at: 0)
                }

                UIView.animate(withDuration: self.slideAnimationDuration, delay: 0, options: [.curveEaseIn], animations: {
                    self.labels.first?.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
                    self.labels.first?.leftAnchor.constraint(equalTo: self.labelsLeftLayoutGuide.rightAnchor).isActive = true
                    self.layoutIfNeeded()
                }) { (_) in
                    self.animating = false
                    self.updateDisplayedText()
                }
            }
        }
    }

    private func pushTransition(_ duration: CFTimeInterval, layer: CALayer, transitionSubtype: CATransitionSubtype) {
        let moveAnimation: CATransition = CATransition()
        moveAnimation.timingFunction = CAMediaTimingFunction(name:
            CAMediaTimingFunctionName.easeIn)
        moveAnimation.type = CATransitionType.push
        moveAnimation.subtype = transitionSubtype
        moveAnimation.duration = duration
        layer.add(moveAnimation, forKey: CATransitionType.push.rawValue)
    }

}
