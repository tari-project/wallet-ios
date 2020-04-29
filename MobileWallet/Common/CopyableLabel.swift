//  CopyableLabel.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 27.04.2020
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

class CopyableLabel: UILabel {

    private let copiedView = UIView()
    private var copiableViewParent: UIView?

    var cornerRadius: CGFloat = 0.0 {
        didSet {
            layer.cornerRadius = cornerRadius
            copiedView.layer.cornerRadius = cornerRadius
        }
    }

    lazy var longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showMenu))

    init(copiableViewParent: UIView? = nil) {
        self.copiableViewParent = copiableViewParent
        super.init(frame: .zero)
        sharedInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }

    private func sharedInit() {
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(longPressGesture)
    }

    @objc func showMenu(sender: AnyObject?) {
        self.becomeFirstResponder()

        let menu = UIMenuController.shared

        if !menu.isMenuVisible {
            menu.showMenu(from: self, rect: CGRect(x: 0, y: 0, width: bounds.width/2, height: bounds.height))
        }
    }

    override func copy(_ sender: Any?) {
        let board = UIPasteboard.general
        UIView.animate(withDuration: CATransaction.animationDuration()) {
        }

        UIView.animate(withDuration: CATransaction.animationDuration(), animations: { [weak self] in
            self?.copiedView.alpha = 1.0
            self?.layoutIfNeeded()
        }) { (_) in
            UIView.animate(withDuration: CATransaction.animationDuration(), delay: 0.5, animations: { [weak self] in
                self?.copiedView.alpha = 0.0
                self?.layoutIfNeeded()
            })
        }
        board.string = text
    }

    func hideMenu() {
        let menu = UIMenuController.shared
        menu.hideMenu()
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(UIResponderStandardEditActions.copy)
    }
}

extension CopyableLabel {

    override func didMoveToSuperview() {
        addCopiedView()
    }

    private func addCopiedView() {
        if copiableViewParent == nil {
            copiableViewParent = self
        }

        copiedView.alpha = 0.0
        copiedView.layer.borderWidth = 2
        copiedView.layer.borderColor = Theme.shared.colors.transactionCellValuePositiveText?.cgColor
        copiedView.backgroundColor = UIColor.white.withAlphaComponent(0.75)

        let greenView = UIView()
        greenView.backgroundColor = Theme.shared.colors.transactionCellValuePositiveText?.withAlphaComponent(0.12)

        let copiedLabel = UILabel()
        copiedLabel.text = "COPIED"
        copiedLabel.font = Theme.shared.fonts.copiedLabelFont
        copiedLabel.textColor = Theme.shared.colors.textButtonSecondary

        self.addSubview(copiedView)
        copiedView.addSubview(greenView)

        copiedView.addSubview(copiedLabel)

        copiedView.translatesAutoresizingMaskIntoConstraints = false

        copiedView.widthAnchor.constraint(equalTo: copiableViewParent!.widthAnchor, multiplier: 1.0).isActive = true
        copiedView.heightAnchor.constraint(equalTo: copiableViewParent!.heightAnchor, multiplier: 1.0).isActive = true
        copiedView.centerXAnchor.constraint(equalTo: copiableViewParent!.centerXAnchor).isActive = true
        copiedView.centerYAnchor.constraint(equalTo: copiableViewParent!.centerYAnchor).isActive = true

        greenView.translatesAutoresizingMaskIntoConstraints = false

        greenView.widthAnchor.constraint(equalTo: copiedView.widthAnchor, multiplier: 1.0).isActive = true
        greenView.heightAnchor.constraint(equalTo: copiedView.heightAnchor, multiplier: 1.0).isActive = true
        greenView.centerXAnchor.constraint(equalTo: copiedView.centerXAnchor).isActive = true
        greenView.centerYAnchor.constraint(equalTo: copiedView.centerYAnchor).isActive = true

        copiedLabel.translatesAutoresizingMaskIntoConstraints = false
        copiedLabel.centerXAnchor.constraint(equalTo: copiedView.centerXAnchor).isActive = true
        copiedLabel.centerYAnchor.constraint(equalTo: copiedView.centerYAnchor).isActive = true

    }
}
