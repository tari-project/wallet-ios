//  AddressView.swift

/*
    Package MobileWallet
    Created by Adrian Truszczyński on 28/06/2024
    Using Swift 5.0
    Running on macOS 14.4

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

final class AddressView: DynamicThemeView {

    enum TextType {
        case truncated(prefix: String, suffix: String)
        case single(_ text: String)
    }

    struct TruncatedText {
        let prefix: String
        let suffix: String
    }

    struct ViewModel {
        let prefix: String?
        let text: TextType
        let isDetailsButtonVisible: Bool
    }

    // MARK: - Subviews

    @View private var barBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10.0
        return view
    }()

    @View private var stackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 8.0
        view.alignment = .center
        return view
    }()

    @View private var prefixLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(17.0)
        return view
    }()

    @View private var firstSeparator = UIView()

    @View private var addressPrefixLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(17.0)
        return view
    }()

    @View private var dotsView: UILabel = {
        let view = UILabel()
        view.text = "•••"
        view.font = .Avenir.medium.withSize(17.0)
        return view
    }()

    @View private var addressSuffixLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(17.0)
        return view
    }()

    @View private var secondSeparator = UIView()

    @View private var viewDetailsButton: BaseButton = {
        let view = BaseButton()
        view.setImage(.Icons.General.open, for: .normal)
        view.showsMenuAsPrimaryAction = true
        return view
    }()

    @View private var singleLabel: UILabel = {
        let view = UILabel()
        view.font = .Avenir.medium.withSize(17.0)
        view.textAlignment = .center
        view.isHidden = true
        return view
    }()

    // MARK: - Properties

    var onViewDetailsButtonTap: (() -> Void)? {
        get { viewDetailsButton.onTap }
        set { viewDetailsButton.onTap = newValue }
    }

    // MARK: - Initializers

    override init() {
        super.init()
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        layer.cornerRadius = 10.0
    }

    private func setupConstraints() {

        addSubview(barBackgroundView)
        barBackgroundView.addSubview(stackView)
        [prefixLabel, firstSeparator, addressPrefixLabel, dotsView, addressSuffixLabel, singleLabel, secondSeparator, viewDetailsButton].forEach(stackView.addArrangedSubview)

        let constraints = [
            barBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            barBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            barBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: barBackgroundView.topAnchor, constant: 10.0),
            stackView.leadingAnchor.constraint(equalTo: barBackgroundView.leadingAnchor, constant: 10.0),
            stackView.trailingAnchor.constraint(equalTo: barBackgroundView.trailingAnchor, constant: -10.0),
            stackView.bottomAnchor.constraint(equalTo: barBackgroundView.bottomAnchor, constant: -10.0),
            firstSeparator.widthAnchor.constraint(equalToConstant: 1.0),
            firstSeparator.heightAnchor.constraint(equalToConstant: 14.0),
            secondSeparator.widthAnchor.constraint(equalToConstant: 1.0),
            secondSeparator.heightAnchor.constraint(equalToConstant: 14.0),
            barBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            viewDetailsButton.heightAnchor.constraint(equalToConstant: 18.0),
            viewDetailsButton.widthAnchor.constraint(equalToConstant: 18.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        barBackgroundView.backgroundColor = theme.backgrounds.primary
        viewDetailsButton.tintColor = theme.icons.active
        firstSeparator.backgroundColor = theme.text.lightText
        secondSeparator.backgroundColor = theme.text.lightText
        dotsView.textColor = theme.text.lightText
        viewDetailsButton.configuration?.baseBackgroundColor = theme.text.links
        viewDetailsButton.tintColor = theme.text.links
    }

    func update(viewModel: ViewModel) {

        prefixLabel.text = viewModel.prefix
        prefixLabel.isHidden = viewModel.prefix == nil
        firstSeparator.isHidden = viewModel.prefix == nil

        switch viewModel.text {
        case let .truncated(prefix, suffix):
            addressPrefixLabel.text = prefix
            addressSuffixLabel.text = suffix
            addressPrefixLabel.isHidden = false
            dotsView.isHidden = false
            addressSuffixLabel.isHidden = false
            singleLabel.isHidden = true
        case let .single(text):
            singleLabel.text = text
            addressPrefixLabel.isHidden = true
            dotsView.isHidden = true
            addressSuffixLabel.isHidden = true
            singleLabel.isHidden = false
        }

        viewDetailsButton.isHidden = !viewModel.isDetailsButtonVisible
        secondSeparator.isHidden = !viewModel.isDetailsButtonVisible
    }
}