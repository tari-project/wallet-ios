//  DesignSystemViewController.swift

/*
    Package MobileWallet
    Created by Konrad Faltyn on 27/01/2025
    Using Swift 5.0
    Running on macOS 12.6

    Copyright 2025 The Tari Project

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

import Combine
import TariCommon
import SwiftUI

final class DesignSystemViewController: DynamicThemeViewController {

    // MARK: - Properties

    @TariView private var scrollView: UIScrollView = {
        UIScrollView()
    }()

    @TariView private var contentView: UIView = {
        UIView()
    }()

    @TariView private var largePrimaryButton: StylisedButton = {
        let button = StylisedButton(withStyle: .primary, withSize: .large)
        button.setTitle("Primary button Large", for: .normal)
        return button
    }()

    @TariView private var mediumPrimaryButton: StylisedButton = {
        let button = StylisedButton(withStyle: .primary, withSize: .medium)
        button.setTitle("Primary button medium", for: .normal)
        return button
    }()

    @TariView private var smallPrimaryButton: StylisedButton = {
        let button = StylisedButton(withStyle: .primary, withSize: .small)
        button.setTitle("Primary button small", for: .normal)
        return button
    }()

    @TariView private var disabledPrimaryButton: StylisedButton = {
        let button = StylisedButton(withStyle: .primary, withSize: .medium)

        button.isEnabled = false
        button.setTitle("Primary medium disabled", for: .disabled)
        return button
    }()

    @TariView private var largeSecondaryButton: StylisedButton = {
        let button = StylisedButton(withStyle: .secondary, withSize: .large)

        button.setTitle("Secondary button large", for: .normal)
        return button
    }()

    @TariView private var mediumSecondaryButton: StylisedButton = {
        let button = StylisedButton(withStyle: .secondary, withSize: .medium)

        button.setTitle("Secondary button medium", for: .normal)
        return button
    }()

    @TariView private var smallSecondaryButton: StylisedButton = {
        let button = StylisedButton(withStyle: .secondary, withSize: .small)

        button.setTitle("Secondary button small", for: .normal)
        return button
    }()

    @TariView private var disabledSecondaryButton: StylisedButton = {
        let button = StylisedButton(withStyle: .secondary, withSize: .medium)

        button.isEnabled = false
        button.setTitle("Secondary medium disabled", for: .normal)
        return button
    }()

    @TariView private var largeOutlinedButton: StylisedButton = {
        let button = StylisedButton(withStyle: .outlined, withSize: .large)

        button.setTitle("Outlined button large", for: .normal)
        return button
    }()

    @TariView private var mediumOutlinedButton: StylisedButton = {
        let button = StylisedButton(withStyle: .outlined, withSize: .medium)

        button.setTitle("Outlined button medium", for: .normal)
        return button
    }()

    @TariView private var smallOutlinedButton: StylisedButton = {
        let button = StylisedButton(withStyle: .outlined, withSize: .small)

        button.setTitle("Outlined button small", for: .normal)
        return button
    }()

    @TariView private var disabledOutlinedButton: StylisedButton = {
        let button = StylisedButton(withStyle: .outlined, withSize: .medium)

        button.isEnabled = false
        button.setTitle("Outlined medium disabled", for: .normal)
        return button
    }()

    @TariView private var inheritButton: StylisedButton = {
        let button = StylisedButton(withStyle: .inherit, withSize: .medium)

        button.setTitle("Inherit medium button", for: .normal)
        return button
    }()

    @TariView private var disabledInheritButton: StylisedButton = {
        let button = StylisedButton(withStyle: .inherit, withSize: .medium)

        button.isEnabled = false
        button.setTitle("Inherit medium disabled", for: .normal)
        return button
    }()

    @TariView private var textButton: StylisedButton = {
        let button = StylisedButton(withStyle: .text, withSize: .medium)

        button.setTitle("Text medium button", for: .normal)
        return button
    }()

    @TariView private var disabledTextButton: StylisedButton = {
        let button = StylisedButton(withStyle: .text, withSize: .medium)

        button.isEnabled = false
        button.setTitle("Text medium disabled", for: .normal)
        return button
    }()

    @TariView private var label: StylisedLabel = {
        let label = StylisedLabel(withStyle: .body1)
        label.text = "Body 1"
        return label
    }()

    // MARK: - Initialisers
    init() {
        super.init(nibName: nil, bundle: nil)
        setupViews()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // MARK: - Setups

    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        update(theme: theme)
    }

    private func uiElements() -> [UIView] {
        let elements: [UIView] = [
            largePrimaryButton,
            mediumPrimaryButton,
            smallPrimaryButton,
            disabledPrimaryButton,
            largeSecondaryButton,
            mediumSecondaryButton,
            smallSecondaryButton,
            disabledSecondaryButton,
            largeOutlinedButton,
            mediumOutlinedButton,
            smallOutlinedButton,
            disabledOutlinedButton,
            inheritButton,
            disabledInheritButton,
            textButton,
            disabledTextButton,
            {
                let label = StylisedLabel(withStyle: .body1)
                label.text = "Body 1"
                return label
            }(),
            {
                let label = StylisedLabel(withStyle: .body2)
                label.text = "Body 2"
                return label
            }(),
            {
                let label = StylisedLabel(withStyle: .buttonLarge)
                label.text = "Button large"
                return label
            }(),
            {
                let label = StylisedLabel(withStyle: .buttonMedium)
                label.text = "Button medium"
                return label
            }(),
            {
                let label = StylisedLabel(withStyle: .buttonSmall)
                label.text = "Button small"
                return label
            }(),
            {
                let label = StylisedLabel(withStyle: .headingMG)
                label.text = "Heading MG"
                return label
            }(),
            {
                let label = StylisedLabel(withStyle: .headingSM)
                label.text = "Heading SM"
                return label
            }(),
            {
                let label = StylisedLabel(withStyle: .headingXL)
                label.text = "Heading XL"
                return label
            }(),
            {
                let label = StylisedLabel(withStyle: .headlingLG)
                label.text = "Heading LG"
                return label
            }(),
            {
                let label = StylisedLabel(withStyle: .menuItem)
                label.text = "Menu item"
                return label
            }(),
            {
                let label = StylisedLabel(withStyle: .modalTitle)
                label.text = "Modal title"
                return label
            }(),
            {
                let label = StylisedLabel(withStyle: .modalTitleLG)
                label.text = "Modal title LG"
                return label
            }(),
            {
                let label = StylisedLabel(withStyle: .textBtn)
                label.text = "Text Btn"
                return label
            }()
        ]

        return elements
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
       ])

        let elements = uiElements()

        elements.forEach{contentView.addSubview($0)}

        let spacing = 30.0

        var constraints: [NSLayoutConstraint] = []

        for (index, view) in elements.enumerated() {

            if index == 0 {
                constraints.append(contentsOf: [
                    view.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                    view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: spacing)
                ])
            } else {
                let previousView = elements[index-1]

                constraints.append(contentsOf: [
                    view.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                    view.topAnchor.constraint(equalTo: previousView.bottomAnchor, constant: spacing)
                ])

                if index == elements.count-1 {
                    constraints.append(view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -spacing))
                }
            }
        }

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

    }

    // MARK: - Actions

    override func update(theme: AppTheme) {
        view.backgroundColor = .Background.primary
    }

}
