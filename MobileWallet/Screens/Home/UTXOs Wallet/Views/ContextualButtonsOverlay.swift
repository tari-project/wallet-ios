//  ContextualButtonsOverlay.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 14/06/2022
	Using Swift 5.0
	Running on macOS 12.3

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
import TariCommon

final class ContextualButtonsOverlay: DynamicThemeView {

    struct ButtonModel {
        let text: String?
        let image: UIImage?
        let callback: (() -> Void)?
    }

    // MARK: - Constants

    private let animationTime: TimeInterval = 0.3
    private let buttonsCollapseDelay: TimeInterval = 3.0
    private let separatorTag = 1

    // MARK: - Subviews

    @TariView private var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 0.0
        return view
    }()

    @TariView private var contentView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10.0
        return view
    }()

    // MARK: - Properties

    private var contextualButtonsCollapseTimer: Timer?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        backgroundColor = .clear
    }

    private func setupConstraints() {

        [contentView].forEach(addSubview)
        contentView.addSubview(stackView)

        let constraints = [
            contentView.topAnchor.constraint(equalTo: stackView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14.0),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -32.0)

        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Actions

    func setup(buttons: [ButtonModel]) {

        Task {
            guard await hideButtons() else { return }
            removeAllButtons()
            addButtons(models: buttons)
            showButtons()
            scheduleButtonsCollapse()
        }
    }

    private func hideButtons() async -> Bool {

        guard !stackView.arrangedSubviews.isEmpty else {
            contentView.alpha = 0.0
            return true
        }

        return await withCheckedContinuation { continuation in

            UIView.animate(
                withDuration: animationTime,
                delay: 0.0,
                options: [.beginFromCurrentState],
                animations: { self.contentView.alpha = 0.0 },
                completion: { continuation.resume(returning: $0) }
            )
        }
    }

    private func removeAllButtons() {
        stackView.removeAllViews()
    }

    private func addButtons(models: [ButtonModel]) {
        models.reduce(into: [UIView]()) { result, model in

            let button = ContextualButton()
            button.update(text: model.text, icon: model.image)

            button.onTap = {
                model.callback?()
            }

            let separator = makeSeparator()
            result += [button, separator]
        }
        .dropLast()
        .forEach { stackView.addArrangedSubview($0) }

        updateElementsColors(theme: theme)
    }

    private func showButtons() {
        UIView.animate(withDuration: animationTime) {
            self.contentView.alpha = 1.0
        }
    }

    private func scheduleButtonsCollapse() {
        contextualButtonsCollapseTimer?.invalidate()
        contextualButtonsCollapseTimer = Timer.scheduledTimer(withTimeInterval: buttonsCollapseDelay, repeats: false) { [weak self] _ in
            self?.collapseButtons()
        }
    }

    private func collapseButtons() {

        UIView.animate(
            withDuration: animationTime,
            delay: 0.0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.0,
            options: [.beginFromCurrentState],
            animations: {
                self.stackView.arrangedSubviews
                    .compactMap { $0 as? ContextualButton }
                    .forEach { $0.isExpanded = false }
                self.layoutIfNeeded()
            },
            completion: nil
        )
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        contentView.backgroundColor = theme.components.overlay?.withAlphaComponent(0.9)
        updateElementsColors(theme: theme)
    }

    private func updateElementsColors(theme: AppTheme) {

        stackView.arrangedSubviews
            .compactMap { $0 as? ContextualButton }
            .forEach { $0.tintColor = theme.text.heading }

        stackView.arrangedSubviews
            .filter { $0.tag == separatorTag }
            .forEach { $0.backgroundColor = theme.neutral.secondary }
    }

    // MARK: - Factories

    private func makeSeparator() -> UIView {
        let view = UIView()
        view.tag = separatorTag
        view.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        return view
    }

    // MARK: - Touches

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool { contentView.frame.contains(point) }
}
