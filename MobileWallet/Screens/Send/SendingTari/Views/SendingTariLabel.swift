//  SendingTariLabel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 09/02/2022
	Using Swift 5.0
	Running on macOS 12.1

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

final class SendingTariLabel: DynamicThemeView {

    // MARK: - Subviews

    @TariView var label: UILabel = {
        let view = UILabel()
        view.text = " "
        view.textAlignment = .center
        view.textColor = .Text.primary
        return view
    }()

    // MARK: - Properties

    var font: UIFont? {
        get { label.font }
        set { label.font = newValue }
    }

    var textColor: UIColor? {
        get { label.textColor }
        set { label.textColor = newValue }
    }

    private var labelTopAnchor: NSLayoutConstraint?
    private var labelBottomAnchor: NSLayoutConstraint?

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
        clipsToBounds = true
    }

    private func setupConstraints() {
        addSubview(label)

        let labelTopAnchor = label.topAnchor.constraint(equalTo: topAnchor)
        labelBottomAnchor = label.topAnchor.constraint(equalTo: bottomAnchor)
        self.labelTopAnchor = labelTopAnchor

        let constraints = [
            labelTopAnchor,
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.heightAnchor.constraint(equalTo: heightAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Actions

    func update(text: String?, completion: (() -> Void)? = nil) {
        hideLabel { [weak self] in
            self?.label.text = text
            self?.label.textColor = .black
            self?.showLabel {
                completion?()
            }
        }
    }

    private func hideLabel(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 1.0, delay: 0.0, options: [], animations: {
            self.label.alpha = 0.0
        }, completion: { _ in
            completion()
        })
    }

    private func showLabel(completion: @escaping () -> Void) {
        labelTopAnchor?.isActive = false
        labelBottomAnchor?.isActive = true
        layoutIfNeeded()

        label.alpha = 1.0
        label.textColor = .black

        labelBottomAnchor?.isActive = false
        labelTopAnchor?.isActive = true

        UIView.animate(withDuration: 0.5, delay: 0.0, options: [], animations: {
            self.layoutIfNeeded()
        }, completion: { _ in
            completion()
        })
    }

    // MARK: - Theme Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        label.textColor = .black
    }
}
