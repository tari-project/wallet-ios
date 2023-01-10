//  CustomBridgesHeaderView.swift

/*
	Package MobileWallet
	Created by Browncoat on 06/12/2022
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

final class CustomBridgesHeaderView: DynamicThemeHeaderFooterView {

    // MARK: - Subiews

    @View private var label: UILabel = {
        let view = UILabel()
        view.font = Theme.shared.fonts.settingsTableViewLastBackupDate
        view.text = localized("custom_bridges.item.paste_bridges")
        return view
    }()

    @View private var textView: UITextView = {
        let view = UITextView()
        view.textContainerInset = UIEdgeInsets(top: 15.0, left: 20.0, bottom: 15.0, right: 20.0)
        return view
    }()

    private let toolbar = UIToolbar()

    // MARK: - Properties

    var text: String? {
        get { textView.attributedText.string }
        set { updateTextViewToAttrbutedText(with: newValue) }
    }

    var textViewDelegate: UITextViewDelegate? {
        get { textView.delegate }
        set { textView.delegate = newValue }
    }

    var isTextViewActive: Bool = false {
        didSet { updateTextViewColors() }
    }

    private var inactiveTextColor: UIColor?
    private var activeTextColor: UIColor?

    // MARK: - Initialisers

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {

        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: localized("settings.done"), style: UIBarButtonItem.Style.done, target: textView, action: #selector(UITextField.resignFirstResponder))
        ]

        toolbar.sizeToFit()

        textView.inputAccessoryView = toolbar
    }

    private func setupConstraints() {

        [label, textView].forEach(contentView.addSubview)

        let constraints = [
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25.0),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -25.0),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 25.0),
            label.heightAnchor.constraint(equalToConstant: 18.0),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            textView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 15.0),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -35.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)

        label.textColor = theme.text.heading
        textView.backgroundColor = theme.backgrounds.primary
        inactiveTextColor = theme.text.lightText
        activeTextColor = theme.text.heading

        updateTextViewColors()
    }

    private func updateTextViewColors() {
        textView.textColor = isTextViewActive ? activeTextColor : inactiveTextColor
    }

    private func updateTextViewToAttrbutedText(with string: String?) {

        let string = string ?? ""
        let attributedString: NSMutableAttributedString = NSMutableAttributedString(string: string)

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byCharWrapping

        attributedString.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: string.count))

        textView.attributedText = attributedString
        textViewDelegate?.textViewDidChange?(textView)

        updateTextViewColors()
    }
}
