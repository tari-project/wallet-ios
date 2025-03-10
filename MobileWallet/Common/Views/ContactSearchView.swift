//  AddRecipientSearchView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 25/10/2021
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

import TariCommon

final class ContactSearchView: DynamicThemeView {

    // MARK: - Subviews

    @View private(set) var textField: UITextField = {
        let view = UITextField()
        view.font = Theme.shared.fonts.searchContactsInputBoxText
        view.leftView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 11.0, height: 0.0))
        view.leftViewMode = .always
        return view
    }()

    @View private var yatIconView: UIImageView = {
        let view = UIImageView()
        view.image = .Icons.Yat.logo.withAlignmentRectInsets(UIEdgeInsets(top: -7.0, left: -11.0, bottom: -7.0, right: 0.0))
        view.contentMode = .scaleAspectFit
        return view
    }()

    @View private(set) var yatPreviewButton = PulseButton()

    @View private(set) var qrButton: PulseButton = {
        let view = PulseButton()
        view.setImage(.Icons.General.QR, for: .normal)
        view.imageView?.contentMode = .scaleAspectFit
        return view
    }()

    @View private var contentView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        return view
    }()

    @View private var previewView = ScrollableLabel()

    // MARK: - Properties

    var isQrButtonVisible: Bool = true {
        didSet { updateViews() }
    }

    var isYatLogoVisible: Bool = false {
        didSet { updateViews() }
    }

    var isPreviewButtonVisible: Bool = false {
        didSet { updateViews() }
    }

    var previewText: String? {
        didSet { updatePreview() }
    }

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
        layer.cornerRadius = 6.0
        layer.borderWidth = 2.0
    }

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
        layer.borderColor = theme.backgrounds.secondary?.cgColor
        previewView.backgroundColor = theme.backgrounds.primary
        qrButton.tintColor = theme.brand.purple
        yatIconView.tintColor = theme.icons.default
    }

    private func setupConstraints() {

        [yatIconView, textField, yatPreviewButton, qrButton].forEach(contentView.addArrangedSubview)
        [contentView, previewView].forEach(addSubview)

        let constraints = [
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            yatPreviewButton.widthAnchor.constraint(equalToConstant: 44.0),
            qrButton.widthAnchor.constraint(equalToConstant: 44.0),
            yatIconView.widthAnchor.constraint(equalToConstant: 33.0),
            previewView.topAnchor.constraint(equalTo: textField.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: textField.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: textField.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: textField.bottomAnchor),
            heightAnchor.constraint(equalToConstant: 46.0)
        ]

        updateViews()
        NSLayoutConstraint.activate(constraints)
    }

    private func updateViews() {
        qrButton.isHidden = !isQrButtonVisible
        yatPreviewButton.isHidden = !isPreviewButtonVisible
        yatIconView.isHidden = !isYatLogoVisible
    }

    private func updatePreview() {
        previewView.isHidden = previewText == nil
        previewView.label.text = previewText
        let iconName = previewView.isHidden ? "eye.fill" : "eye.slash.fill"
        yatPreviewButton.setImage(UIImage(systemName: iconName), for: .normal)
    }
}
