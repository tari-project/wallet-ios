//  CustomTabBar.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/08/12
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

import TariCommon

class RoundedShadowView: UIView {
    private var shadowLayer: CAShapeLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        shadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: 20).cgPath
        shadowLayer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1).cgColor
        shadowLayer.shadowOffset = CGSize(width: 0, height: 0)
        shadowLayer.shadowRadius = 40
        shadowLayer.shadowOpacity = 1
        shadowLayer.opacity = 1.0
        shadowLayer.isHidden = false
        shadowLayer.masksToBounds = false
        shadowLayer.fillColor = UIColor.Components.navbarBackground.cgColor
    }

    func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = false
        layer.insertSublayer(shadowLayer, at: 0)
    }
}

final class CustomTabBar: DynamicThemeTabBar {
    @View private var secureContentView = SecureWrapperView<UIView>()

    override init() {
        super.init()
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func setup() {
        clipsToBounds = false
        backgroundColor = .clear

        let rounded = RoundedShadowView()
        addSubview(rounded)
        addSubview(secureContentView)

        let constraints = [
            rounded.topAnchor.constraint(equalTo: topAnchor),
            rounded.leadingAnchor.constraint(equalTo: leadingAnchor),
            rounded.trailingAnchor.constraint(equalTo: trailingAnchor),
            rounded.bottomAnchor.constraint(equalTo: bottomAnchor),

            secureContentView.topAnchor.constraint(equalTo: topAnchor),
            secureContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            secureContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            secureContentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    override func addSubview(_ view: UIView) {

        guard view != secureContentView else {
            super.addSubview(view)
            return
        }

        secureContentView.view.addSubview(view)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        super.sizeThatFits(size)
        var sizeThatFits = super.sizeThatFits(size)
        let bottomInset = UIApplication.shared.firstWindow?.safeAreaInsets.bottom ?? 0
        sizeThatFits.height = 59 + bottomInset
        return sizeThatFits
    }

    override func update(theme: AppTheme) {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .Components.navbarBackground
        appearance.stackedLayoutAppearance.normal.iconColor = .Components.navbarIcons
        appearance.stackedLayoutAppearance.selected.iconColor = .Components.navbarIcons

        standardAppearance = appearance
        scrollEdgeAppearance = appearance

        secureContentView.view.backgroundColor = .Background.secondary
    }
}
