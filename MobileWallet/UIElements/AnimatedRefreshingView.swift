//  RefreshingView.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/04/17
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

enum AnimatedRefreshingViewState {
    //Home view states
    case loading
    case receiving
    case success
    //TX view states
    case txWaitingForSender
    case txWaitingForRecipient
    case txCompleted
}

private class RefreshingInnerView: UIView {
    private let statusLabel = UILabel()
    private let emojiLabel = UILabel()
    private let spinner = UIActivityIndicatorView()

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setupView(_ type: AnimatedRefreshingViewState) {
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(emojiLabel)
        emojiLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        emojiLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        emojiLabel.font = .systemFont(ofSize: 18)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusLabel)
        statusLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        statusLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        statusLabel.textAlignment = .center
        statusLabel.font = Theme.shared.fonts.refreshViewLabel

        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)
        spinner.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        spinner.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
        spinner.hidesWhenStopped = true

        switch type {
        case .loading:
            emojiLabel.text = "⏳"
            spinner.startAnimating()
            statusLabel.text = NSLocalizedString("Checking for Updates", comment: "Refresh view")
            statusLabel.textColor = Theme.shared.colors.refreshViewLabelLoading
        case .receiving:
            emojiLabel.text = "🤝"
            spinner.startAnimating()
            statusLabel.text = NSLocalizedString("Receiving new transaction", comment: "Refresh view")
            statusLabel.textColor = Theme.shared.colors.refreshViewLabelLoading
        case .success:
            statusLabel.text = NSLocalizedString("You are up to date!", comment: "Refresh view")
            spinner.stopAnimating()
            statusLabel.textColor = Theme.shared.colors.refreshViewLabelSuccess
        case .txWaitingForRecipient:
            emojiLabel.text = ""
            spinner.stopAnimating()
            statusLabel.text = NSLocalizedString("Waiting for recipient to accept transaction", comment: "Refresh view")
            statusLabel.textColor = Theme.shared.colors.refreshViewLabelLoading
        case .txWaitingForSender:
            emojiLabel.text = ""
            spinner.stopAnimating()
            statusLabel.text = NSLocalizedString("Waiting for sender to complete transaction", comment: "Refresh view")
            statusLabel.textColor = Theme.shared.colors.refreshViewLabelLoading
        case .txCompleted:
            emojiLabel.text = ""
            spinner.stopAnimating()
            statusLabel.text = NSLocalizedString("Completing final processing…", comment: "Refresh view")
            statusLabel.textColor = Theme.shared.colors.refreshViewLabelLoading
        }
    }
}

class AnimatedRefreshingView: UIView {
    private let cornerRadius: CGFloat = 20
    static let containerHeight: CGFloat = 48

    private var currentInnerView = RefreshingInnerView()
    private var currentInnerViewTopAnchor = NSLayoutConstraint()
    private var currentInnerViewBottomAnchor = NSLayoutConstraint()
    private var currentState: AnimatedRefreshingViewState = .loading

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setupView(_ type: AnimatedRefreshingViewState, visible: Bool = false) {
        currentState = type
        backgroundColor = Theme.shared.colors.appBackground

        layer.cornerRadius = cornerRadius
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 2, height: 2)
        layer.shadowRadius = 5
        layer.shadowColor = Theme.shared.colors.defaultShadow?.cgColor

        currentInnerView.setupView(type)
        setupInnerView(currentInnerView)

        currentInnerViewTopAnchor = currentInnerView.topAnchor.constraint(equalTo: topAnchor)
        currentInnerViewTopAnchor.isActive = true
        currentInnerViewBottomAnchor = currentInnerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        currentInnerViewBottomAnchor.isActive = true

        heightAnchor.constraint(equalToConstant: AnimatedRefreshingView.containerHeight).isActive = true

        if !visible {
            alpha = 0
        }
    }

    func animateIn(delay: TimeInterval = 0.25, withDuration: TimeInterval = 0.5) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
            UIView.animate(withDuration: withDuration, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
                guard let self = self else { return }
                self.alpha = 1
                self.layoutIfNeeded()
            })
        })
    }

    func animateOut(_ onComplete: (() -> Void)? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
                guard let self = self else { return }
                self.alpha = 0
                self.layoutIfNeeded()
            }) { (_) in
                onComplete?()
            }
        })
    }

    private func setupInnerView(_ innerView: RefreshingInnerView) {
        innerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(innerView)
        innerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        innerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }

    func updateState(_ type: AnimatedRefreshingViewState) {
        guard currentState != type else {
            return
        }

        currentState = type

        let shiftUpPoints: CGFloat = 20

        let newInnerView = RefreshingInnerView()
        newInnerView.setupView(type)
        newInnerView.alpha = 0
        setupInnerView(newInnerView)

        let newInnerViewTopAnchor = newInnerView.topAnchor.constraint(equalTo: topAnchor, constant: shiftUpPoints)
        newInnerViewTopAnchor.isActive = true
        let newInnerViewBottomAnchor = newInnerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: shiftUpPoints)
        newInnerViewBottomAnchor.isActive = true

        //Shift the new inner view from the bottom up, while moving the current one up and out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
                    guard let self = self else { return }

                    self.currentInnerView.alpha = 0
                    newInnerView.alpha = 1

                    newInnerViewTopAnchor.constant = 0
                    newInnerViewBottomAnchor.constant = 0

                    self.currentInnerViewTopAnchor.constant = -shiftUpPoints
                    self.currentInnerViewBottomAnchor.constant = -shiftUpPoints
                    self.layoutIfNeeded()

            }) { [weak self] (_) in
                guard let self = self else { return }

                self.currentInnerView.removeFromSuperview()

                self.currentInnerView = newInnerView

                self.currentInnerViewTopAnchor.isActive = false
                self.currentInnerViewBottomAnchor.isActive = false

                newInnerViewTopAnchor.isActive = false
                newInnerViewBottomAnchor.isActive = false

                self.currentInnerViewTopAnchor = newInnerViewTopAnchor
                self.currentInnerViewBottomAnchor = newInnerViewBottomAnchor

                self.currentInnerViewTopAnchor.isActive = true
                self.currentInnerViewBottomAnchor.isActive = true
            }
        })
    }
}
