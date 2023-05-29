//  ContactBookSearchField.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 26/04/2023
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

import TariCommon

final class ContactBookSearchField: DynamicThemeTextField {

    // MARK: - Subviews

    @View private var scanButton: PulseButton = {
        let view = PulseButton()
        view.setImage(.icons.qr, for: .normal)
        view.contentHorizontalAlignment = .fill
        view.contentVerticalAlignment = .fill
        view.imageEdgeInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        return view
    }()

    // MARK: - Properties

    var onScanButtonTap: (() -> Void)?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupView()
        setupSideViews()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupView() {
        font = .Avenir.medium.withSize(14.0)
        layer.cornerRadius = 6.0
        layer.borderWidth = 1.0
        heightAnchor.constraint(equalToConstant: 46.0).isActive = true
    }

    private func setupSideViews() {
        leftView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 20.0, height: 0.0))
        leftViewMode = .always
        rightView = scanButton
        rightViewMode = .always
    }

    private func setupCallbacks() {
        scanButton.onTap = { [weak self] in
            self?.onScanButtonTap?()
        }
    }

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
        textColor = theme.text.heading
        layer.borderColor = theme.neutral.tertiary?.cgColor
    }
}
