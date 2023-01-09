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

enum AnimatedRefreshingViewState: Equatable {
    // home view states
    case loading // sync.ing with base node
    case receiving // txs have been received or mined while syncing
    case completing // txs have been broadcast while syncing
    case updating // txs have been cancelled while syncing
    case success
    // post-base-node-sync update sequence

    // tx view states
    case txWaitingForSender
    case txWaitingForRecipient
    case txCompleted(confirmationCount: UInt64)
}

private class RefreshingInnerView: DynamicThemeView {
    private let statusLabel = UILabel()
    private let emojiLabel = UILabel()
    private let spinner = UIActivityIndicatorView()

    private var type: AnimatedRefreshingViewState = .loading

    func setupView(_ type: AnimatedRefreshingViewState) {

        self.type = type

        emojiLabel.removeFromSuperview()
        statusLabel.removeFromSuperview()
        spinner.removeFromSuperview()

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
            statusLabel.text = localized("refresh_view.checking")
        case .receiving:
            emojiLabel.text = "🤝"
            spinner.startAnimating()
            statusLabel.text = localized("refresh_view.receiving_new_txs")
        case .completing:
            emojiLabel.text = "🤝"
            spinner.startAnimating()
            statusLabel.text = localized("refresh_view.completing_txs")
        case .updating:
            emojiLabel.text = "🤝"
            spinner.startAnimating()
            statusLabel.text = localized("refresh_view.updating_txs")
        case .success:
            statusLabel.text = localized("refresh_view.success")
            spinner.stopAnimating()
        case .txWaitingForRecipient:
            emojiLabel.text = ""
            spinner.stopAnimating()
            statusLabel.text = localized("refresh_view.waiting_for_recipient")
        case .txWaitingForSender:
            emojiLabel.text = ""
            spinner.stopAnimating()
            statusLabel.text = localized("refresh_view.waiting_for_sender")
        case .txCompleted(let confirmationCount):
            guard let requiredConfirmationCount = try? Tari.shared.transactions.requiredConfirmationsCount else {
                statusLabel.text = localized("refresh_view.final_processing")
                break
            }
            emojiLabel.text = ""
            spinner.stopAnimating()
            statusLabel.text = String(
                format: localized("refresh_view.final_processing_with_param"),
                confirmationCount,
                requiredConfirmationCount + 1
            )
        }

        update(theme: theme)
    }

    override func update(theme: ColorTheme) {
        super.update(theme: theme)

        let color: UIColor?

        switch type {
        case .loading, .receiving, .completing, .updating:
            color = theme.brand.purple
        case .success:
            color = theme.system.green
        case .txWaitingForRecipient, .txWaitingForSender, .txCompleted:
            color = theme.system.yellow
        }

        statusLabel.textColor = color
    }
}

class AnimatedRefreshingView: DynamicThemeView {
    private let cornerRadius: CGFloat = 20
    static let containerHeight: CGFloat = 48

    private var currentInnerView = RefreshingInnerView()
    private var currentInnerViewTopAnchor = NSLayoutConstraint()
    private var currentInnerViewBottomAnchor = NSLayoutConstraint()
    private var currentState: AnimatedRefreshingViewState = .loading

    private var isUpdatingState: Bool = false

    enum StateType {
        case none
        case updateData
        case txtView
    }

    var stateType: StateType = .none

    func setupView(_ type: AnimatedRefreshingViewState,
                   visible: Bool = false) {
        currentState = type

        layer.cornerRadius = cornerRadius

        currentInnerView.setupView(type)
        setupInnerView(currentInnerView)

        currentInnerViewTopAnchor = currentInnerView.topAnchor.constraint(equalTo: topAnchor)
        currentInnerViewTopAnchor.isActive = true
        currentInnerViewBottomAnchor = currentInnerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        currentInnerViewBottomAnchor.isActive = true

        if !visible {
            alpha = 0
        }
    }

    func animateIn(delay: TimeInterval = 0.25,
                   withDuration: TimeInterval = 0.5) {
        if alpha == 1 { return }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + delay
        ) {
            UIView.animate(
                withDuration: withDuration,
                delay: 0,
                options: .curveEaseInOut,
                animations: {
                    [weak self] in
                    guard let self = self else { return }
                    self.alpha = 1
                    self.layoutIfNeeded()
                }
            )
        }
    }

    func animateOut(_ onComplete: (() -> Void)? = nil) {
        if alpha == 0 { return }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.1
        ) {
            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                options: .curveEaseInOut,
                animations: {
                    [weak self] in
                    guard let self = self else { return }
                    self.alpha = 0
                    self.layoutIfNeeded()
                }
            ) { (_) in
                onComplete?()
            }
        }
    }

    private func setupInnerView(_ innerView: RefreshingInnerView) {
        innerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(innerView)
        innerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        innerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }

    func playUpdateSequence(hasReceivedTx: Bool,
                            hasMinedTx: Bool,
                            hasBroadcastTx: Bool,
                            hasCancelledTx: Bool,
                            completion: @escaping () -> Void) {
        showReceivingTxsState(
            hasReceivedTx: hasReceivedTx,
            hasMinedTx: hasMinedTx,
            hasBroadcastTx: hasBroadcastTx,
            hasCancelledTx: hasCancelledTx,
            completion: completion
        )
    }

    private func showReceivingTxsState(hasReceivedTx: Bool,
                                       hasMinedTx: Bool,
                                       hasBroadcastTx: Bool,
                                       hasCancelledTx: Bool,
                                       completion: @escaping () -> Void) {
        if hasReceivedTx || hasMinedTx {
            updateState(.receiving) {
                [weak self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                    [weak self] in
                    self?.showCompletingTxsState(
                        hasBroadcastTx: hasBroadcastTx,
                        hasCancelledTx: hasCancelledTx,
                        completion: completion
                    )
                }
            }
        } else {
            showCompletingTxsState(
                hasBroadcastTx: hasBroadcastTx,
                hasCancelledTx: hasCancelledTx,
                completion: completion
            )
        }
    }

    private func showCompletingTxsState(hasBroadcastTx: Bool,
                                        hasCancelledTx: Bool,
                                        completion: @escaping () -> Void) {
        if hasBroadcastTx {
            updateState(.completing) {
                [weak self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                    [weak self] in
                    self?.showUpdatingTxsState(
                        hasCancelledTx: hasCancelledTx,
                        completion: completion
                    )
                }
            }
        } else {
            showUpdatingTxsState(
                hasCancelledTx: hasCancelledTx,
                completion: completion
            )
        }
    }

    private func showUpdatingTxsState(hasCancelledTx: Bool,
                                      completion: @escaping () -> Void) {
        if hasCancelledTx {
            updateState(.updating) {
                [weak self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                    [weak self] in
                    self?.showSuccessState(completion: completion)
                }
            }
        } else {
            showSuccessState(completion: completion)
        }
    }

    private func showSuccessState(completion: @escaping () -> Void) {
        updateState(.success) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                completion()
            }
        }
    }

    func updateState(_ newState: AnimatedRefreshingViewState,
                     animated: Bool = true,
                     completion: (() -> Void)? = nil) {
        guard currentState != newState else {
            return
        }
        if isUpdatingState {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.5 + CATransaction.animationDuration()
            ) {
                [weak self] in
                self?.updateState(newState)
            }
            return
        }

        isUpdatingState = true
        currentState = newState

        let shiftUpPoints: CGFloat = 20

        let newInnerView = RefreshingInnerView()
        newInnerView.setupView(newState)
        newInnerView.alpha = 0
        setupInnerView(newInnerView)

        let newInnerViewTopAnchor = newInnerView.topAnchor.constraint(
            equalTo: topAnchor,
            constant: shiftUpPoints
        )
        newInnerViewTopAnchor.isActive = true
        let newInnerViewBottomAnchor = newInnerView.bottomAnchor.constraint(
            equalTo: bottomAnchor,
            constant: shiftUpPoints
        )
        newInnerViewBottomAnchor.isActive = true

        // Shift the new inner view from the bottom up, while moving the current one up and out
        DispatchQueue.main.asyncAfter(
            deadline: .now() + (animated ? CATransaction.animationDuration() : 0.0)
        ) {
            UIView.animate(
                withDuration: (animated ? 0.5 : 0.0),
                delay: 0,
                options: .curveEaseInOut,
                animations: {
                    [weak self] in
                    guard let self = self else { return }
                    self.currentInnerView.alpha = 0
                    newInnerView.alpha = 1
                    newInnerViewTopAnchor.constant = 0
                    newInnerViewBottomAnchor.constant = 0
                    self.currentInnerViewTopAnchor.constant = -shiftUpPoints
                    self.currentInnerViewBottomAnchor.constant = -shiftUpPoints
                    self.layoutIfNeeded()
                }
            ) {
                [weak self] (_) in
                guard let self = self else { return }
                self.isUpdatingState = false
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
                completion?()
            }
        }
    }

    override func update(theme: ColorTheme) {
        super.update(theme: theme)

        backgroundColor = theme.backgrounds.primary
        apply(shadow: theme.shadows.box)
    }
}
