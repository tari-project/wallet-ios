//  ActionButton.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/10/31
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

final class SecondaryActionButton: DynamicThemeBaseButton {

    enum Style {
        case normal
        case destructive
        case loading
    }

    // MARK: - Subviews

    @View private var pendingAnimationView: AnimationView = {
        let view = AnimationView()
        view.animation = .named(.pendingCircleAnimation)
        view.backgroundBehavior = .pauseAndRestore
        view.loopMode = .loop
        return view
    }()

    // MARK: - Properties

    var isAnimated: Bool = true

    var style: Style = .normal {
        didSet { update(style: style, theme: theme) }
    }

    // MARK: - Initialisers

    override init() {
        super.init()
        setupViews()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        layer.cornerRadius = 25
        layer.borderColor = theme.buttons.borderSecondary?.cgColor
        layer.borderWidth = 1 / UIScreen.main.scale
        titleLabel?.adjustsFontSizeToFitWidth = true
        clipsToBounds = true

        configuration = .filled()
        configuration?.contentInsets = NSDirectionalEdgeInsets(top: 0.0, leading: 11.0, bottom: 0.0, trailing: 11.0)
        configuration?.titleLineBreakMode = .byTruncatingTail

        configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
            var attributes = $0
            attributes.font = .Poppins.SemiBold.withSize(16.0)
            attributes.kern = 0.46
            return attributes
        }

        configurationUpdateHandler = { [weak self] in
            self?.update(state: $0.state)
        }
    }

    private func setupConstraints() {

        [pendingAnimationView].forEach(addSubview)

        let constraints = [
            pendingAnimationView.widthAnchor.constraint(equalToConstant: 45.0),
            pendingAnimationView.heightAnchor.constraint(equalToConstant: 45.0),
            pendingAnimationView.centerXAnchor.constraint(equalTo: centerXAnchor),
            pendingAnimationView.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: 50.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {
        addTarget(self, action: #selector(onTapCallback), for: .touchUpInside)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        updateDisabledState(theme: theme)
        layer.borderColor = theme.buttons.borderSecondary?.cgColor
    }

    private func updateDisabledState(theme: AppTheme) {
        setTitleColor(theme.buttons.disabledText, for: .disabled)
    }

    private func update(state: UIButton.State) {

        switch state {
        case .normal:
            update(style: style, theme: theme)
        case .disabled:
            configuration?.background.backgroundColor = theme.buttons.disabled
        default:
            break
        }

        guard isAnimated else { return }

        if state == .highlighted {
            Task { await animateIn() }
        } else {
            animateOut()
        }
    }

    private func update(style: Style, theme: AppTheme) {

        guard isEnabled else { return }

        switch style {
        case .normal:
            titleLabel?.isHidden = false
            pendingAnimationView.isHidden = true
            pendingAnimationView.stop()
            configuration?.background.backgroundColor = theme.buttons.secondaryBackground
            configuration?.baseForegroundColor = theme.buttons.secondaryText
        case .destructive:
            titleLabel?.isHidden = false
            pendingAnimationView.isHidden = true
            pendingAnimationView.stop()
            configuration?.baseForegroundColor = theme.buttons.secondaryText
            configuration?.background.backgroundColor = theme.system.red
        case .loading:
            titleLabel?.isHidden = true
            pendingAnimationView.isHidden = false
            pendingAnimationView.play()
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
