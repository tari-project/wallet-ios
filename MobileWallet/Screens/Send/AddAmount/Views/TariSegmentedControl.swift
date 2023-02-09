//  TariSegmentedControl.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 20/05/2022
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
import Combine

final class TariSegmentedControl: DynamicThemeView {

    // MARK: - Constants

    private let elementSize = CGSize(width: 70.0, height: 50.0)
    private let padding: CGFloat = 2.0

    // MARK: - Subviews

    @View private var selectionView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 7.0
        return view
    }()

    @View private var stackView = UIStackView()

    // MARK: - Properties

    @Published var selectedIndex: Int?
    private var cancellables = Set<AnyCancellable>()

    private var selectionViewCenterXConstraint: NSLayoutConstraint?

    // MARK: - Initialisers

    init(icons: [UIImage?]) {
        super.init()
        setupViews(icons: icons)
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews(icons: [UIImage?]) {

        layer.cornerRadius = 9.0

        icons
            .enumerated()
            .compactMap { [weak self] in self?.makeButton(icon: $1, index: $0) }
            .forEach { [weak self] in self?.stackView.addArrangedSubview($0) }

        guard stackView.arrangedSubviews.count > 0 else { return }
        selectedIndex = 0
    }

    private func setupConstraints() {

        [selectionView, stackView].forEach(addSubview)

        let constraints = [
            selectionView.widthAnchor.constraint(equalToConstant: elementSize.width - 2.0 * padding),
            selectionView.heightAnchor.constraint(equalToConstant: elementSize.height - 2.0 * padding),
            selectionView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        $selectedIndex
            .compactMap { $0 }
            .sink { [weak self] in self?.moveSelectionView(toIndex: $0) }
            .store(in: &cancellables)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        backgroundColor = theme.neutral.inactive
        selectionView.backgroundColor = theme.backgrounds.primary
        selectionView.apply(shadow: theme.shadows.box)
        stackView.arrangedSubviews.forEach { $0.tintColor = theme.icons.default }
    }

    // MARK: - Actions

    private func moveSelectionView(toIndex index: Int) {

        guard index < stackView.arrangedSubviews.count else { return }

        let view = stackView.arrangedSubviews[index]
        selectionViewCenterXConstraint?.isActive = false
        selectionViewCenterXConstraint = selectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        selectionViewCenterXConstraint?.isActive = true

        UIView.animate(
            withDuration: 0.3,
            delay: 0.0,
            usingSpringWithDamping: 0.75,
            initialSpringVelocity: 0.0,
            options: [.beginFromCurrentState, .curveEaseInOut],
            animations: { [weak self] in self?.layoutIfNeeded() },
            completion: { _ in }
        )
    }

    // MARK: - Factories

    private func makeButton(icon: UIImage?, index: Int) -> UIButton {

        let button = BaseButton()

        button.setImage(icon, for: .normal)
        button.onTap = { [weak self] in self?.selectedIndex = index }

        let constraints = [
            button.widthAnchor.constraint(equalToConstant: elementSize.width),
            button.heightAnchor.constraint(equalToConstant: elementSize.height)
        ]

        NSLayoutConstraint.activate(constraints)

        return button
    }
}
