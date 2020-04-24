//  NavigationBarWithSubtitle.swift

/*
    Package MobileWallet
    Created by S.Shovkoplyas on 16.04.2020
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

protocol TransactionDetailNavigationBarProtocol: class {
    var title: String? { get set }
    var subtitle: String? { get set }
}

class NavigationBarWithSubtitle: UIView, TransactionDetailNavigationBarProtocol {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let backButton = UIButton()

    var title: String? {
        get {
            titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }

    var subtitle: String? {
        get {
            subtitleLabel.text
        }
        set {
            subtitleLabel.text = newValue
        }
    }

    override func draw(_ rect: CGRect) {
        backgroundColor = Theme.shared.colors.appBackground

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4.0)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.0
        clipsToBounds = true
        layer.masksToBounds = false

        let animation = CABasicAnimation(keyPath: "shadowOpacity")
        animation.fromValue = layer.shadowOpacity
        animation.toValue = 0.1
        animation.duration = CATransaction.animationDuration()
        layer.add(animation, forKey: animation.keyPath)
        layer.shadowOpacity = 0.1

        setupTitle()
        setupSubtitle()
        setupBackButton()
    }

    private func setupTitle() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16.0).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true

        //Style
        titleLabel.font = Theme.shared.fonts.navigationBarTitle
        titleLabel.textColor = Theme.shared.colors.navigationBarTint
        titleLabel.textAlignment = .center
    }

    private func setupSubtitle() {
        addSubview(subtitleLabel)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 9.0).isActive = true
        subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true

        //Style
        subtitleLabel.textAlignment = .center
        subtitleLabel.font = Theme.shared.fonts.transactionScreenSubheadingLabel
        subtitleLabel.textColor = Theme.shared.colors.transactionScreenSubheadingLabel
    }

    private func setupBackButton() {
        addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
        backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        backButton.widthAnchor.constraint(equalToConstant: 45).isActive = true
        backButton.addTarget(self, action: #selector(backAction(_sender:)), for: .touchUpInside)

        let imageView = UIImageView(image: Theme.shared.images.backArrow)
        backButton.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.leadingAnchor.constraint(equalTo: backButton.leadingAnchor).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 13).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 8).isActive = true
        imageView.centerYAnchor.constraint(equalTo: backButton.centerYAnchor).isActive = true
        imageView.isUserInteractionEnabled = false
        //Style
        backButton.backgroundColor = .clear
    }

      @objc public func backAction(_sender: UIButton) {
        if var topController = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            guard let navigationController = topController as? UINavigationController else { return }
            navigationController.popViewController(animated: true)
        }
      }
}
