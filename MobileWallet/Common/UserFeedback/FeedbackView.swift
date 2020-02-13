//  InfoFeedback.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/01/27
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

class FeedbackView: UIView {
    private let SIDE_PADDING: CGFloat = 30
    private let ELEMENT_PADDING: CGFloat = 20
    private let CORNER_RADIUS: CGFloat = 26

    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private var onCloseHandler: (() -> Void)?
    private var onCallToActionHandler: (() -> Void)?
    private let callToActionButton = SendButton()
    private let closeButton = TextButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    //common func to init our view
    private func setupView() {
        backgroundColor = Theme.shared.colors.appBackground
        layer.cornerRadius = CORNER_RADIUS
        heightAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
    }

    private func setupTitle() {
        addSubview(titleLabel)
        titleLabel.textColor = Theme.shared.colors.feedbackPopupTitle
        titleLabel.font = Theme.shared.fonts.errorFeedbackPopupTitle
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: SIDE_PADDING).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -SIDE_PADDING).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: titleLabel.font.pointSize * 1.2).isActive = true
    }

    private func setupDescription() {
        addSubview(descriptionLabel)
        descriptionLabel.textColor = Theme.shared.colors.feedbackPopupDescription
        descriptionLabel.font = Theme.shared.fonts.errorFeedbackPopupDescription
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 5
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: SIDE_PADDING).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -SIDE_PADDING).isActive = true
    }

    private func setupCloseButton() {
        closeButton.setVariation(.secondary)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(closeButton)
        closeButton.setTitle(NSLocalizedString("Close", comment: "User feedback bottom float"), for: .normal)
        closeButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        closeButton.addTarget(self, action: #selector(onCloseButtonPressed), for: .touchUpInside)
    }

    private func setupCallToActionButton() {
        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(callToActionButton)
        callToActionButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        callToActionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 160).isActive = true
        callToActionButton.addTarget(self, action: #selector(onCallToActionButtonPressed), for: .touchUpInside)
    }

    @objc private func onCloseButtonPressed() {
        if let onClose = onCloseHandler {
            onClose()
        }
    }

    @objc private func onCallToActionButtonPressed() {
        if let onAction = onCallToActionHandler {
            onAction()
        }

        if let onClose = onCloseHandler {
            onClose()
        }
    }

    private func setDescription(_ description: String) {
        let attributedDescription = NSMutableAttributedString(string: description)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 10
        paragraphStyle.alignment = .center
        attributedDescription.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: attributedDescription.length)
        )

        descriptionLabel.attributedText = attributedDescription
    }

    func setupError(title: String, description: String) {
        setupTitle()
        titleLabel.text = title
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: SIDE_PADDING).isActive = true

        setupDescription()
        setDescription(description)
        descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: ELEMENT_PADDING).isActive = true
        descriptionLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -SIDE_PADDING).isActive = true
    }

    func setupInfo(title: String, description: String, onClose: @escaping () -> Void) {
        setupTitle()
        titleLabel.text = title
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: SIDE_PADDING).isActive = true

        setupDescription()
        setDescription(description)
        descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: ELEMENT_PADDING).isActive = true

        setupCloseButton()
        closeButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: ELEMENT_PADDING).isActive = true
        closeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -SIDE_PADDING).isActive = true

        onCloseHandler = onClose
    }

    func setupSuccess(title: String) {
        setupDescription()
        descriptionLabel.text = title
        descriptionLabel.textColor = Theme.shared.colors.successFeedbackPopupTitle
        backgroundColor = Theme.shared.colors.successFeedbackPopupBackground
        layer.cornerRadius = 0

        descriptionLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    func setupCallToAction(
        title: String,
        description: String,
        cancelTitle: String,
        actionTitle: String,
        onClose: @escaping () -> Void,
        onAction: @escaping () -> Void) {
        setupTitle()
        titleLabel.text = title
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: SIDE_PADDING).isActive = true

        setupDescription()
        setDescription(description)
        descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: ELEMENT_PADDING).isActive = true

        setupCallToActionButton()
        onCallToActionHandler = onAction
        callToActionButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: ELEMENT_PADDING).isActive = true
        callToActionButton.setTitle(actionTitle, for: .normal)

        setupCloseButton()
        onCloseHandler = onClose
        closeButton.setTitle(cancelTitle, for: .normal)
        closeButton.topAnchor.constraint(equalTo: callToActionButton.bottomAnchor, constant: ELEMENT_PADDING).isActive = true
        closeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -SIDE_PADDING).isActive = true
    }
}
