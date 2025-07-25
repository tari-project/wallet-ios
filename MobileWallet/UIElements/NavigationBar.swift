//  NavigationBar.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 15.05.2020
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
import TariCommon

final class NavigationBar: DynamicThemeView {

    enum BackButtonType: Equatable {
        case back
        case close
        case text(String?)
        case none
    }

    struct ButtonModel {
        let image: UIImage?
        let title: String?
        let callback: (() -> Void)?

        init(image: UIImage?, callback: (() -> Void)?) {
            self.image = image
            title = nil
            self.callback = callback
        }

        init(title: String?, callback: (() -> Void)?) {
            image = nil
            self.title = title
            self.callback = callback
        }
    }

    // MARK: - Subviews

    @TariView private(set) var contentView = UIView()

    @TariView private var titleLabel: UILabel = {
        let view = UILabel()
        view.font = .Poppins.SemiBold.withSize(16)
        view.textAlignment = .center
        return view
    }()

    @TariView private var backButton: StylisedButton = {
        let view = StylisedButton(withStyle: .text, withSize: .small)
        return view
    }()

    @TariView private var separator = UIView()

    @TariView private var rightStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        return view
    }()

    @TariView private(set) var bottomContentView = UIView()

    @TariView private var progressView: UIProgressView = {
        let view = UIProgressView()
        view.isHidden = true
        return view
    }()

    // MARK: - Properties

    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    var backButtonType: BackButtonType = .back {
        didSet { updateLeftButton() }
    }

    var progress: Float? {
        didSet {
            guard let progress else {
                progressView.isHidden = true
                return
            }

            progressView.isHidden = false
            progressView.setProgress(progress, animated: oldValue != nil)
        }
    }

    var isSeparatorVisible: Bool {
        get { !separator.isHidden }
        set { separator.isHidden = !newValue }
    }

    var onBackButtonAction: (() -> Void)?

    override init() {
        super.init()
        setupConstraints()
        setupCallbacks()
        updateLeftButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Subviews

    private func setupConstraints() {

        [contentView, bottomContentView, separator, progressView].forEach(addSubview)
        [backButton, titleLabel, rightStackView].forEach(contentView.addSubview)

        let bottomContentViewHeightConstraint = bottomContentView.heightAnchor.constraint(equalToConstant: 0.0)
        bottomContentViewHeightConstraint.priority = .defaultHigh

        let constraints = [
            contentView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.heightAnchor.constraint(equalToConstant: 44.0),

            backButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8.0),
            backButton.widthAnchor.constraint(equalToConstant: 30),
            backButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            rightStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            rightStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8.0),
            rightStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            bottomContentView.topAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomContentViewHeightConstraint,
            separator.topAnchor.constraint(equalTo: bottomContentView.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1.0),
            progressView.topAnchor.constraint(equalTo: bottomAnchor),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {
        backButton.onTap = { [weak self] in self?.handleBackButtonAction() }
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        backgroundColor = .Background.secondary
        titleLabel.textColor = .Text.primary
        separator.backgroundColor = .clear
        progressView.tintColor = .Text.primary
        updateStackView(theme: theme)
    }

    private func updateStackView(theme: AppTheme) {
        rightStackView
            .arrangedSubviews
            .compactMap { $0 as? BaseButton }
            .forEach {
                $0.tintColor = theme.icons.default
                $0.setTitleColor(.Text.primary, for: .normal)
                $0.setTitleColor(.Text.primary.withAlphaComponent(0.5), for: .highlighted)
                $0.setTitleColor(.Action.disabledBackground, for: .disabled)
            }
    }

    func update(rightButton: ButtonModel) {
        update(rightButtons: [rightButton])
    }

    func update(rightButtons: [ButtonModel]) {

        rightStackView.removeAllViews()

        rightButtons
            .compactMap { [weak self] in self?.makeButton(model: $0) }
            .forEach(rightStackView.addArrangedSubview)

        updateStackView(theme: theme)
    }

    func rightButton(index: Int) -> BaseButton? {
        guard rightStackView.arrangedSubviews.count > index else { return nil }
        return rightStackView.arrangedSubviews[index] as? BaseButton
    }

    private func updateLeftButton() {

        var text: String?
        var image: UIImage?

        switch backButtonType {
        case .back:
            image = Theme.shared.images.backArrow
        case .close:
            image = Theme.shared.images.close
        case let .text(buttonText):
            text = buttonText
        case .none:
            break
        }

        backButton.setTitle(text, for: .normal)
        backButton.setImage(image, for: .normal)
    }

    // MARK: - Actions

    private func handleBackButtonAction() {
        guard backButtonType != .none else { return }

        if let onBackButtonAction {
            onBackButtonAction()
            return
        }

        let topController = UIApplication.shared.topController

        guard let navigationController = topController as? UINavigationController else {
            topController?.dismiss(animated: true)
            return
        }
        guard navigationController.viewControllers.first == navigationController.topViewController else {
            navigationController.popViewController(animated: true)
            return
        }

        navigationController.dismiss(animated: true)
    }

    // MARK: - Factories

    private func makeButton(model: ButtonModel) -> BaseButton {
        @TariView var button = BaseButton()
        button.titleLabel?.font = Theme.shared.fonts.settingsDoneButton
        button.setTitle(model.title, for: .normal)
        button.setImage(model.image, for: .normal)
        button.onTap = model.callback
        button.widthAnchor.constraint(greaterThanOrEqualTo: button.heightAnchor).isActive = true
        return button
    }
}
