//  TariPopUp.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 10/04/2022
	Using Swift 5.0
	Running on macOS 12.3

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

final class TariPopUp: DynamicThemeView {

    // MARK: - Subviews

    @View private var backgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 26.0
        return view
    }()

    // MARK: - Properties

    var topOffset: CGFloat = 0.0 {
        didSet { backgroundViewTopConstraint?.constant = topOffset }
    }

    var backgroundViewTopConstraint: NSLayoutConstraint?

    // MARK: - Initialisers

    init(headerSection: UIView?, contentSection: UIView?, buttonsSection: UIView?) {
        super.init()
        setupConstraints(headerSection: headerSection, contentSection: contentSection, buttonsSection: buttonsSection)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints(headerSection: UIView?, contentSection: UIView?, buttonsSection: UIView?) {

        addSubview(backgroundView)

        let backgroundViewTopConstraint = backgroundView.topAnchor.constraint(equalTo: topAnchor)
        self.backgroundViewTopConstraint = backgroundViewTopConstraint

        var constraints = [
            backgroundViewTopConstraint,
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        var viewOnTop: UIView?

        if let headerSection = headerSection {
            constraints += makeConstraints(forView: headerSection, viewOnTop: viewOnTop)
            viewOnTop = headerSection
            headerSection.translatesAutoresizingMaskIntoConstraints = false
            addSubview(headerSection)
        }

        if let contentSection = contentSection {
            constraints += makeConstraints(forView: contentSection, viewOnTop: viewOnTop)
            viewOnTop = contentSection
            contentSection.translatesAutoresizingMaskIntoConstraints = false
            addSubview(contentSection)
        }

        if let buttonsSection = buttonsSection {
            constraints += makeConstraints(forView: buttonsSection, viewOnTop: viewOnTop)
            viewOnTop = buttonsSection
            buttonsSection.translatesAutoresizingMaskIntoConstraints = false
            addSubview(buttonsSection)
        }

        guard let viewOnTop = viewOnTop else { return }
        constraints.append(viewOnTop.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -22.0))
        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundView.backgroundColor = theme.components.overlay
    }

    // MARK: - Helpers

    private func makeConstraints(forView view: UIView, viewOnTop: UIView?) -> [NSLayoutConstraint] {
        let anchor = viewOnTop?.bottomAnchor ?? topAnchor
        var constraints = [
            view.topAnchor.constraint(equalTo: anchor, constant: 22.0),
            view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22.0),
            view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22.0)
        ]

        if UIDevice.current.userInterfaceIdiom == .pad {
            constraints.append(view.widthAnchor.constraint(equalToConstant: 350.0))
        }

        return constraints
    }
}
