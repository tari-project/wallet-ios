//  TextButton.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/01/28
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

final class TextButton: DynamicThemeBaseButton {

    enum Style {
        case primary
        case secondary
        case warning
    }

    // MARK: - Properties

    var font: UIFont = .Poppins.Medium.withSize(14.0) {
        didSet { setNeedsUpdateConfiguration() }
    }

    var style: Style = .primary {
        didSet { updateTextColor(theme: theme) }
    }

    var image: UIImage? {
        didSet { configuration?.image = image }
    }

    var imageSpacing: CGFloat = 4.0 {
        didSet { updateImageSpacing() }
    }

    // MARK: - Initialisers

    override init() {
        super.init()
        setupConfiguration()
        updateImageSpacing()
        updateTextColor(theme: theme)
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConfiguration() {

        configuration = .plain()
        configuration?.imagePlacement = .trailing

        configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { [weak self] in
            var attributes = $0
            attributes.font = self?.font
            return attributes
        }

        configurationUpdateHandler = { [weak self] in
            self?.update(state: $0.state)
        }
    }

    private func setupCallbacks() {
        addTarget(self, action: #selector(onTapCallback), for: .touchUpInside)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        updateTextColor(theme: theme)
    }

    private func updateTextColor(theme: AppTheme) {
        switch style {
        case .primary:
            configuration?.baseForegroundColor = theme.text.body
        case .secondary:
            configuration?.baseForegroundColor = theme.text.links
        case .warning:
            configuration?.baseForegroundColor = theme.system.red
        }
    }

    private func updateImageSpacing() {
        configuration?.imagePadding = imageSpacing
    }

    private func update(state: UIButton.State) {

        guard self.state != state else { return }

        if state == .highlighted {
            Task { await animateIn() }
        } else {
            animateOut()
        }
    }

    // MARK: - Callbacks

    @objc private func onTapCallback() {
        Task {
            await animateIn()
            animateOut()
        }
    }

    // MARK: - Animations

    private func animateIn() async {
        await withCheckedContinuation { continuation in
            UIView.animate(
                withDuration: 0.1,
                delay: 0.0,
                options: [.curveEaseInOut, .beginFromCurrentState],
                animations: {
                    self.alpha = 0.9
                    self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                },
                completion: { _ in continuation.resume() }
            )
        }
    }

    private func animateOut() {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.curveEaseInOut, .beginFromCurrentState]) {
            self.alpha = 1.0
            self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }
    }
}
