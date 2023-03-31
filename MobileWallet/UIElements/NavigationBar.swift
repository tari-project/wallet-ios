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

    enum BackButtonType {
        case back
        case close
        case none
    }

    // MARK: - Subviews

    @View private(set) var contentView = UIView()

    @View private var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.shared.fonts.navigationBarTitle
        view.textAlignment = .center
        return view
    }()

    @View private var backButton = BaseButton()
    @View private var separator = UIView()

    @View private(set) var rightButton: BaseButton = {
        let view = BaseButton()
        view.titleLabel?.font = Theme.shared.fonts.settingsDoneButton
        view.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: -8.0, bottom: 0.0, right: 8.0)
        return view
    }()

    @View private(set) var bottomContentView = UIView()

    @View private var progressView: UIProgressView = {
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
    var onRightButtonAction: (() -> Void)?

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
        [backButton, titleLabel, rightButton].forEach(contentView.addSubview)

        rightButton.setContentHuggingPriority(.required, for: .horizontal)

        let bottomContentViewHeightConstraint = bottomContentView.heightAnchor.constraint(equalToConstant: 0.0)
        bottomContentViewHeightConstraint.priority = .defaultHigh

        let constraints = [
            contentView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.heightAnchor.constraint(equalToConstant: 44.0),
            backButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44.0),
            backButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: rightButton.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rightButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            rightButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rightButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44.0),
            rightButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
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
        rightButton.onTap = { [weak self] in self?.onRightButtonAction?() }
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
        backButton.tintColor = theme.icons.default
        titleLabel.textColor = theme.text.heading
        separator.backgroundColor = theme.neutral.tertiary
        progressView.tintColor = theme.brand.purple

        rightButton.tintColor = theme.icons.default
        rightButton.setTitleColor(theme.brand.purple, for: .normal)
        rightButton.setTitleColor(theme.brand.purple?.withAlphaComponent(0.5), for: .highlighted)
        rightButton.setTitleColor(theme.icons.inactive, for: .disabled)
    }

    private func updateLeftButton() {

        let image: UIImage?

        switch backButtonType {
        case .back:
            image = Theme.shared.images.backArrow
        case .close:
            image = Theme.shared.images.close
        case .none:
            image = nil
        }

        backButton.setImage(image, for: .normal)
    }

    // MARK: - Actions

    private func handleBackButtonAction() {

        guard backButtonType != .none else { return }

        guard onBackButtonAction == nil else {
            onBackButtonAction?()
            return
        }

        let topController = UIApplication.shared.topController()

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
}
