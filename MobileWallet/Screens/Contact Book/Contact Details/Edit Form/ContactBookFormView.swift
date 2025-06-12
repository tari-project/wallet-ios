//  ContactBookFormView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 01/03/2023
	Using Swift 5.0
	Running on macOS 13.0

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
import Combine

final class ContactBookFormView: DynamicThemeView, FormShowable {

    struct TextFieldViewModel {
        let placeholder: String?
        let text: String?
        let isEmojiKeyboardVisible: Bool
        let autocapitalization: Bool
        let callback: ((String) -> Void)?
    }

    // MARK: - Subviews

    @View private var titleBar: NavigationBar = {
        let view = NavigationBar()
        view.backButtonType = .none
        return view
    }()

    @View private var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 20.0
        return view
    }()

    @View private var secureContentView = SecureWrapperView<UIView>()

    // MARK: - Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - FormShowable

    var focusedView: UIView? { stackView.arrangedSubviews.first }
    var initalReturkKeyType: UIReturnKeyType = .default
    var onCloseAction: (() -> Void)?

    // MARK: - Initialisers

    init(title: String?, rightButtonTitle: String?, textFieldsModels: [TextFieldViewModel]) {
        super.init()
        setupTitleBar(title: title, rightButtonTitle: rightButtonTitle)
        setupConstraints()
        update(textFieldsModels: textFieldsModels)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupTitleBar(title: String?, rightButtonTitle: String?) {
        titleBar.title = title
        titleBar.update(rightButton: NavigationBar.ButtonModel(title: rightButtonTitle, callback: { [weak self] in self?.onCloseAction?() }))
    }

    private func setupConstraints() {

        addSubview(secureContentView)
        [titleBar, stackView].forEach(secureContentView.view.addSubview)

        let constraints = [
            secureContentView.topAnchor.constraint(equalTo: topAnchor),
            secureContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            secureContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            secureContentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            titleBar.topAnchor.constraint(equalTo: topAnchor),
            titleBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: titleBar.bottomAnchor, constant: 26.0),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 26.0),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -26.0),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -26.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        secureContentView.view.backgroundColor = .Background.popup
    }

    private func update(textFieldsModels: [TextFieldViewModel]) {

        let textFields = textFieldsModels
            .enumerated()
            .map { index, model in
                let textField = FormTextField()

                textField.publisher
                    .sink { model.callback?($0) }
                    .store(in: &cancellables)

                textField.placeholder = model.placeholder
                textField.text = model.text
                textField.isEmojiKeyboardVisible = model.isEmojiKeyboardVisible
                textField.autocapitalizationType = model.autocapitalization ? .words : .none
                textField.onReturnPressed = { [weak self] in
                    self?.handleOnReturnPressedAction(index: index)
                }

                return textField
            }

        textFields
            .forEach { [weak self] in
                $0.returnKeyType = .next
                self?.stackView.addArrangedSubview($0)
            }

        textFields.last?.returnKeyType = .done

        initalReturkKeyType = textFields.count > 1 ? .next : .done
    }

    // MARK: - Actions

    private func handleOnReturnPressedAction(index: Int) {
        let nextIndex = index + 1
        guard stackView.arrangedSubviews.count > nextIndex else {
            onCloseAction?()
            return
        }
        stackView.arrangedSubviews[nextIndex].becomeFirstResponder()
    }

    override var intrinsicContentSize: CGSize {

        guard #available(iOS 16.0, *) else {
            return sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        }

        return super.intrinsicContentSize
    }
}
