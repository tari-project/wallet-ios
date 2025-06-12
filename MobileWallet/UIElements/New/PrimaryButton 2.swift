//  PrimaryButton.swift

/*
    Package MobileWallet
    Created by Konrad Faltyn on 2024/12/28
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
import Lottie

final class PrimaryButton: DynamicThemeBaseButton {

    enum Style {
        case primary
        case secondary
        case destructive
    }

    enum Size {
        case large
        case medium
        case small
    }

    // MARK: - Subviews

    // MARK: - Properties

    var isAnimated: Bool = true

    var style: Style = .primary {
        didSet { update(style: style, size: .medium, disabled: false, theme: theme) }
    }

    var size: Size = .medium {
        didSet { update(style: style, size: .medium, disabled: false, theme: theme) }
    }

    // MARK: - Initialisers

    init(withStyle: PrimaryButton.Style, withSize: PrimaryButton.Size) {
        super.init()

        style = withStyle
        size = withSize
        setupViews()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        configuration = .filled()

        var fontSize = 0.0
        switch size {
        case .large:
            layer.cornerRadius = 25
            fontSize = 16
            configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0.0, leading: 11.0, bottom: 0.0, trailing: 11.0)
        case .medium:
            layer.cornerRadius = 18
            fontSize = 14
            configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0.0, leading: 8.0, bottom: 0.0, trailing: 8.0)
        case .small:
            layer.cornerRadius = 15
            fontSize = 12
            configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0.0, leading: 5.0, bottom: 0.0, trailing: 5.0)
        }

        titleLabel?.adjustsFontSizeToFitWidth = true
        clipsToBounds = true

        configuration?.titleLineBreakMode = .byTruncatingTail
        configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
            var attributes = $0
            attributes.font = .Poppins.SemiBold.withSize(fontSize)
            attributes.kern = 0.46
            return attributes
        }

        configurationUpdateHandler = { [weak self] in
            self?.update(state: $0.state)
        }
    }

    private func setupConstraints() {
        switch size {
        case .large:
            NSLayoutConstraint.activate([
                widthAnchor.constraint(equalToConstant: 356),
                heightAnchor.constraint(equalToConstant: 50)
            ])
        case .medium:
            NSLayoutConstraint.activate([
                widthAnchor.constraint(equalToConstant: 200),
                heightAnchor.constraint(equalToConstant: 36)
            ])
        case .small:
            NSLayoutConstraint.activate([
                widthAnchor.constraint(equalToConstant: 160),
                heightAnchor.constraint(equalToConstant: 30)
            ])
        }
    }

    private func setupCallbacks() {
        addTarget(self, action: #selector(onTapCallback), for: .touchUpInside)
    }

    private func update(state: UIButton.State) {
        update(style: style, size: size, disabled: state == .disabled, theme: theme)
        guard isAnimated else { return }

        if state == .highlighted {
            Task { await animateIn() }
        } else {
            animateOut()
        }
    }

    private func update(style: Style, size: Size, disabled: Bool, theme: AppTheme) {
        switch style {
        case .primary:
            titleLabel?.isHidden = false
            if disabled {
                configuration?.background.backgroundColor = .Action.disabledBackground
                configuration?.baseForegroundColor = .Action.disabled
            } else {
                configuration?.background.backgroundColor = .Button.primaryBg
                configuration?.baseForegroundColor = .Button.primaryText
            }
        case .secondary:
            titleLabel?.isHidden = false
            if disabled {
                configuration?.background.backgroundColor = .Action.disabledBackground
                configuration?.baseForegroundColor = .Action.disabled
            } else {
                configuration?.background.backgroundColor = .Primary.main
                configuration?.baseForegroundColor = .Common.blackmain
            }
        case .destructive:
            titleLabel?.isHidden = false
            configuration?.background.backgroundColor = .System.red
            configuration?.baseForegroundColor = .Button.primaryText
        }
    }

    // MARK: - Callbacks

    @objc private func onTapCallback() {
        guard isAnimated else { return }
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
