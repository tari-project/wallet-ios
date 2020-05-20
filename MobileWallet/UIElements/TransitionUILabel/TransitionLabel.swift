//  TransitionUILabel.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 18.05.2020
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

import UIKit

class TransitionLabel: UIView {
    enum TransitionDirection: Equatable {
        case top
        case bottom
    }
    var direction: TransitionDirection = .top {
        didSet {
            switch direction {
            case .top: bottomConstraint?.isActive = false; topConstraint?.isActive = true
            case .bottom: topConstraint?.isActive = false; bottomConstraint?.isActive = true
            }
            layoutIfNeeded()
        }
    }
    private let label = UILabel()
    private var topConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var showConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?

    var text: String? {
        didSet {
            label.text = text
        }
    }

    var attributedText: NSAttributedString? {
        didSet {
            label.attributedText = attributedText
        }
    }

    var font: UIFont? {
        didSet {
            label.font = font
        }
    }

    var textColor: UIColor? {
        didSet {
            label.textColor = textColor
        }
    }

    var textAlignment: NSTextAlignment = .left {
        didSet {
            label.textAlignment = textAlignment
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        setupLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLabel() {
        addSubview(label)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false

        label.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        label.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true

        heightConstraint = label.heightAnchor.constraint(equalToConstant: 0)

        topConstraint = label.topAnchor.constraint(equalTo: bottomAnchor)
        topConstraint?.isActive = true

        bottomConstraint = label.bottomAnchor.constraint(equalTo: topAnchor)
        showConstraint = label.topAnchor.constraint(equalTo: topAnchor)
    }

    func showLabel(animated: Bool = true, duration: TimeInterval = CATransaction.animationDuration(), completion: (() -> Void)? = nil) {
        heightConstraint?.isActive = false
        layoutIfNeeded()
        label.alpha = 1.0

        topConstraint?.isActive = false
        bottomConstraint?.isActive = false
        showConstraint?.isActive = true

        UIView.animate(withDuration: duration, animations: { [weak self] in
            self?.layoutIfNeeded()
        }) { _ in
            completion?()
        }
    }

    func hideLabel(animated: Bool = true, duration: TimeInterval = CATransaction.animationDuration(), completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: { [weak self] in
            self?.label.alpha =  0.0
        }) { [weak self] _ in
            self?.heightConstraint?.isActive = true
            self?.showConstraint?.isActive = false

            switch self?.direction {
            case .top: self?.topConstraint?.isActive = true
            case .bottom: self?.bottomConstraint?.isActive = true
            default: break
            }
            self?.layoutIfNeeded()
            completion?()
        }
    }
}
