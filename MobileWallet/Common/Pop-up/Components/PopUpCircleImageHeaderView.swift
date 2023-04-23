//  PopUpCircleImageHeaderView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 20/04/2023
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

final class PopUpCircleImageHeaderView: DynamicThemeView {

    enum ImageTint {
        case purple
        case red
    }

    // MARK: - Subviews

    @View private var circleBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 40.0
        return view
    }()

    @View private var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    @View private var titleLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.light.withSize(18.0)
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()

    var image: UIImage? {
        get { imageView.image }
        set { imageView.image = newValue }
    }

    var imageTintColor: ImageTint? {
        didSet { updateImageTintColor(theme: theme) }
    }

    var text: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        [circleBackgroundView, titleLabel].forEach(addSubview)
        circleBackgroundView.addSubview(imageView)

        let constraints = [
            circleBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            circleBackgroundView.centerXAnchor.constraint(equalTo: centerXAnchor),
            circleBackgroundView.heightAnchor.constraint(equalToConstant: 80.0),
            circleBackgroundView.widthAnchor.constraint(equalToConstant: 80.0),
            imageView.topAnchor.constraint(equalTo: circleBackgroundView.topAnchor, constant: 10.0),
            imageView.leadingAnchor.constraint(equalTo: circleBackgroundView.leadingAnchor, constant: 10.0),
            imageView.trailingAnchor.constraint(equalTo: circleBackgroundView.trailingAnchor, constant: -10.0),
            imageView.bottomAnchor.constraint(equalTo: circleBackgroundView.bottomAnchor, constant: -10.0),
            titleLabel.topAnchor.constraint(equalTo: circleBackgroundView.bottomAnchor, constant: 20.0),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20.0),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        circleBackgroundView.backgroundColor = theme.backgrounds.primary
        circleBackgroundView.apply(shadow: theme.shadows.box)
        titleLabel.textColor = theme.text.heading

        updateImageTintColor(theme: theme)
    }

    private func updateImageTintColor(theme: ColorTheme) {

        switch imageTintColor {
        case .none:
            imageView.tintColor = .clear
        case .purple:
            imageView.tintColor = theme.brand.purple
        case .red:
            imageView.tintColor = theme.system.red
        }
    }
}
