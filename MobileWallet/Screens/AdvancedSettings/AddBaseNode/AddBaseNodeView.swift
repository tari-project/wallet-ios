//  AddBaseNodeView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 19/07/2021
	Using Swift 5.0
	Running on macOS 12.0

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

final class AddBaseNodeView: DynamicThemeView {

    // MARK: - Subviews

    private let nameTitleLabel: UILabel = {
        let view = UILabel()
        view.text = localized("add_base_node.section.name")
        view.font = Theme.shared.fonts.tableViewSection
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let nameTextField: RoundedInputField = {
        let view = RoundedInputField()
        view.font = Theme.shared.fonts.textField
        view.returnKeyType = .next
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let peerTitleLabel: UILabel = {
        let view = UILabel()
        view.text = localized("add_base_node.section.peer")
        view.font = Theme.shared.fonts.tableViewSection
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let peerTextView: RoundedTextView = {
        let view = RoundedTextView()
        view.font = Theme.shared.fonts.textField
        view.returnKeyType = .done
        view.autocorrectionType = .no
        view.autocapitalizationType = .none
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.secondary
        nameTitleLabel.textColor = theme.text.heading
        peerTitleLabel.textColor = theme.text.heading
    }

    private let saveButton: ActionButton = {
        let view = ActionButton()
        view.setTitle(localized("add_base_node.button.save"), for: .normal)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let contentStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 12.0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let scrollView: ContentScrollView = {
        let view = ContentScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Properties

    var name: String? { nameTextField.text }
    var peer: String? { peerTextView.text }
    var onTapOnSaveButton: (() -> Void)?

    private var scrollViewBottomConstraint: NSLayoutConstraint?

    // MARK: - Initializers

    override init() {
        super.init()
        setupConstraints()
        setupFeedbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        peerTitleLabel.setContentHuggingPriority(.required, for: .vertical)

        addSubview(scrollView)
        scrollView.contentView.addSubview(contentStackView)
        [nameTitleLabel, nameTextField, peerTitleLabel, peerTextView, saveButton].forEach(contentStackView.addArrangedSubview)

        let scrollViewBottomConstraint = scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        self.scrollViewBottomConstraint = scrollViewBottomConstraint

        let constraints = [
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollViewBottomConstraint,
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor, constant: 12.0),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor, constant: 12.0),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor, constant: -12.0),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentView.bottomAnchor, constant: -12.0),
            peerTextView.heightAnchor.constraint(equalToConstant: 100.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupFeedbacks() {
        saveButton.addTarget(self, action: #selector(onTapOnSaveButtonAction), for: .touchUpInside)
        nameTextField.delegate = self
        peerTextView.delegate = self
    }

    // MARK: - Actions

    func update(bottomMargin: CGFloat, animationTime: TimeInterval) {
        scrollViewBottomConstraint?.constant = -bottomMargin
        setNeedsLayout()
        UIView.animate(withDuration: animationTime, delay: 0.0, options: [.curveEaseInOut]) {
            self.layoutIfNeeded()
        }
    }

    func focusOnNameTextField() {
        nameTextField.becomeFirstResponder()
    }

    // MARK: - Action targets

    @objc private func onTapOnSaveButtonAction() {
        onTapOnSaveButton?()
    }
}

extension AddBaseNodeView: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        peerTextView.becomeFirstResponder()
        return false
    }
}

extension AddBaseNodeView: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard text == "\n" else { return true }
        textView.resignFirstResponder()
        return false
    }
}
