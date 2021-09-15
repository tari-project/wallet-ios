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

struct UserFeedbackFormInput {
    let key: String
    let placeholder: String
    // Possibly add keyboard type
}

class FeedbackView: UIView {
    private let sidePadding: CGFloat = 30
    private let elementPadding: CGFloat = 20
    private let cornerRadius: CGFloat = 26

    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private var onCloseHandler: (() -> Void)?
    private var onCallToActionHandler: (() -> Void)?
    private var onSubmitActionHandler: (([String: String]) -> Void)?
    // private var formInputResults: [String: String]?
    private var formInputs: [String: UITextField] = [:]
    private let callToActionButton = ActionButton()
    private let closeButton = TextButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    // common func to init our view
    private func setupView() {
        backgroundColor = Theme.shared.colors.appBackground
        layer.cornerRadius = cornerRadius
        heightAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
    }

    private func setupTitle() {
        addSubview(titleLabel)
        titleLabel.textColor = Theme.shared.colors.feedbackPopupTitle
        titleLabel.font = Theme.shared.fonts.feedbackPopupTitle
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: sidePadding).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -sidePadding).isActive = true
    }

    private func setupDescription() {
        addSubview(descriptionLabel)
        descriptionLabel.textColor = Theme.shared.colors.feedbackPopupDescription
        descriptionLabel.font = Theme.shared.fonts.feedbackPopupDescription
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: sidePadding).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -sidePadding).isActive = true
        descriptionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: descriptionLabel.font.pointSize * 1.15).isActive = true
    }

    private func setupCloseButton() {
        closeButton.setVariation(.secondary)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(closeButton)
        closeButton.setTitle(localized("feedback_view.close"), for: .normal)
        closeButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        closeButton.addTarget(self, action: #selector(onCloseButtonPressed), for: .touchUpInside)
    }

    private func setupCallToActionButton(isDestructive: Bool = false,
                                         _ action: Selector) {
        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
        if isDestructive { callToActionButton.variation = .destructive }
        addSubview(callToActionButton)
        callToActionButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        callToActionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 160).isActive = true
        callToActionButton.addTarget(self, action: action, for: .touchUpInside)
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
    }

    @objc private func onSubmitActionButtonPressed() {
        if let onAction = onSubmitActionHandler {
            var results: [String: String] = [:]

            formInputs.forEach { (arg0) in
                let (key, inputField) = arg0
                if let text = inputField.text {
                    results[key] = text
                }
            }

            onAction(results)
        }

        if let onClose = onCloseHandler {
            onClose()
        }
    }

    private func setDescription(_ description: String,
                                boldParts: [String]? = nil) {
        let attributedDescription = NSMutableAttributedString(string: description)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        attributedDescription.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: attributedDescription.length)
        )
        // add bold parts if any
        for boldPart in boldParts ?? [] {
            if let startIndex = description.indexDistance(of: boldPart) {
                let range = NSRange(location: startIndex, length: boldPart.count)
                attributedDescription.addAttribute(
                    .font,
                    value: Theme.shared.fonts.feedbackPopupDescriptionBold,
                    range: range
                )
            }
        }
        descriptionLabel.attributedText = attributedDescription
    }

    func setupError(title: String, description: String) {
        setupTitle()
        titleLabel.text = title
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: sidePadding).isActive = true

        setupDescription()
        setDescription(description)
        descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: elementPadding).isActive = true
        descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -sidePadding).isActive = true
    }

    func setupError(title: String, description: String, onClose: @escaping (() -> Void)) {
        setupError(title: title, description: description)
        setupCloseButton()
        closeButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: elementPadding).isActive = true
        closeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -sidePadding).isActive = true

        onCloseHandler = onClose
    }

    func setupInfo(title: String, description: String, onClose: @escaping () -> Void) {
        setupTitle()
        titleLabel.text = title
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: sidePadding).isActive = true

        setupDescription()
        setDescription(description)
        descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: elementPadding).isActive = true

        setupCloseButton()
        closeButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: elementPadding).isActive = true
        closeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -sidePadding).isActive = true

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
        boldedTitle: String? = nil,
        description: String,
        descriptionBoldParts: [String]? = nil,
        cancelTitle: String,
        actionTitle: String,
        isDestructive: Bool = false,
        onClose: @escaping () -> Void,
        onAction: @escaping () -> Void) {
        setupTitle()
        if let boldText = boldedTitle {
            if let startIndex = title.indexDistance(of: boldText) {
                let attributedTitle = NSMutableAttributedString(
                    string: title,
                    attributes: [
                        .font: Theme.shared.fonts.feedbackPopupTitle,
                        .foregroundColor: Theme.shared.colors.feedbackPopupTitle!
                    ]
                )

                let range = NSRange(location: startIndex, length: boldText.count)
                attributedTitle.addAttribute(.font, value: Theme.shared.fonts.feedbackPopupHeavy, range: range)

                titleLabel.attributedText = attributedTitle
            }
        } else {
            titleLabel.text = title
        }

        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: sidePadding).isActive = true

        setupDescription()
        setDescription(description, boldParts: descriptionBoldParts)
        descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: elementPadding).isActive = true

        setupCallToActionButton(isDestructive: isDestructive, #selector(onCallToActionButtonPressed))
        onCallToActionHandler = onAction
        callToActionButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: elementPadding).isActive = true
        callToActionButton.setTitle(actionTitle, for: .normal)

        setupCloseButton()
        if isDestructive {
            closeButton.setVariation(.primary)
        }
        onCloseHandler = onClose
        closeButton.setTitle(cancelTitle, for: .normal)
        closeButton.topAnchor.constraint(equalTo: callToActionButton.bottomAnchor, constant: elementPadding).isActive = true
        closeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -sidePadding).isActive = true
    }

    func setupCallToActionDetailed(
        containerView: UIView,
        image: UIImage,
        imageTop: CGFloat,
        title: String,
        boldedTitle: String,
        description: String,
        cancelTitle: String,
        actionTitle: String,
        actionIcon: UIImage,
        onClose: @escaping () -> Void,
        onAction: @escaping () -> Void) {

        let imageView = UIImageView()
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 180).isActive = true
        imageView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: topAnchor, constant: -imageTop).isActive = true

        setupTitle()

        let attributedTitle = NSMutableAttributedString(
            string: title,
            attributes: [
                .font: Theme.shared.fonts.feedbackPopupTitle,
                .foregroundColor: Theme.shared.colors.feedbackPopupTitle!
            ]
        )

        if let startIndex = title.indexDistance(of: boldedTitle) {
            let range = NSRange(location: startIndex, length: boldedTitle.count)
            attributedTitle.addAttribute(.font, value: Theme.shared.fonts.feedbackPopupHeavy, range: range)
        }

        titleLabel.attributedText = attributedTitle
        titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: elementPadding).isActive = true

        setupDescription()
        setDescription(description)
        descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: elementPadding).isActive = true

        setupCallToActionButton(#selector(onCallToActionButtonPressed))
        onCallToActionHandler = onAction
        callToActionButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: sidePadding).isActive = true
        callToActionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true
        callToActionButton.setTitle(actionTitle, for: .normal)
        callToActionButton.setImage(actionIcon, for: .normal)

        setupCloseButton()
        onCloseHandler = onClose
        closeButton.setTitle(cancelTitle, for: .normal)
        closeButton.topAnchor.constraint(equalTo: callToActionButton.bottomAnchor, constant: elementPadding).isActive = true
        closeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -sidePadding).isActive = true
    }

    private func setupInputField(_ inputField: UITextField) {
        inputField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(inputField)

        inputField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: sidePadding).isActive = true
        inputField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -sidePadding).isActive = true
        inputField.heightAnchor.constraint(equalToConstant: 40).isActive = true

        inputField.borderStyle = .roundedRect
    }

    func setupForm(
        title: String,
        cancelTitle: String,
        actionTitle: String,
        inputs: [UserFeedbackFormInput],
        onClose: @escaping () -> Void,
        onSubmit: @escaping ([String: String]) -> Void) {
        setupTitle()
        titleLabel.text = title
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: sidePadding).isActive = true

        setupCallToActionButton(#selector(onSubmitActionButtonPressed))
        onSubmitActionHandler = onSubmit

        var lastInput: UITextField?

        formInputs = [:]

        inputs.forEach { (input) in
            let inputField = UITextField()
            setupInputField(inputField)
            formInputs[input.key] = inputField

            inputField.placeholder = input.placeholder

            if let previousInput = lastInput {
                inputField.topAnchor.constraint(equalTo: previousInput.bottomAnchor, constant: elementPadding).isActive = true
            } else {
                // This is the first input
                inputField.becomeFirstResponder()
                inputField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: elementPadding).isActive = true
            }

            lastInput = inputField
        }

        if let bottomInput = lastInput {
            callToActionButton.topAnchor.constraint(equalTo: bottomInput.bottomAnchor, constant: elementPadding).isActive = true
        } else {
            callToActionButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: elementPadding).isActive = true
        }
        callToActionButton.setTitle(actionTitle, for: .normal)

        setupCloseButton()
        onCloseHandler = onClose
        closeButton.setTitle(cancelTitle, for: .normal)
        closeButton.topAnchor.constraint(equalTo: callToActionButton.bottomAnchor, constant: elementPadding).isActive = true
        closeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -sidePadding).isActive = true
    }
}
