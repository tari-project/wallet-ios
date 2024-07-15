//  PopUpAddressDetailsContentView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 02/07/2024
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

final class PopUpAddressDetailsContentView: DynamicThemeView {

    struct ViewModel {
        let network: String
        let networkDescription: String
        let features: String
        let featuresDescription: String
        let viewKey: String?
        let coreAddress: String
        let checksum: String
    }

    // MARK: - Subviews

    @View private var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 20.0
        return view
    }()

    @View private var networkSection: PopUpAddressDetailsContentSectionView<PopUpAddressViewDoubleLabel> = {
        let view = PopUpAddressDetailsContentSectionView<PopUpAddressViewDoubleLabel>()
        view.title = localized("address_view.details.label.network.title")
        return view
    }()

    @View private var featuresSection: PopUpAddressDetailsContentSectionView<PopUpAddressViewDoubleLabel> = {
        let view = PopUpAddressDetailsContentSectionView<PopUpAddressViewDoubleLabel>()
        view.title = localized("address_view.details.label.features.title")
        return view
    }()

    @View private var viewKeySection: PopUpAddressDetailsContentSectionView<UILabel> = {
        let view = PopUpAddressDetailsContentSectionView<UILabel>()
        view.title = localized("address_view.details.label.view_key.title")
        view.contentView.font = .Avenir.medium.withSize(14.0)
        view.contentView.numberOfLines = 0
        return view
    }()

    @View private var coreAddressSection: PopUpAddressDetailsContentSectionView<UILabel> = {
        let view = PopUpAddressDetailsContentSectionView<UILabel>()
        view.title = localized("address_view.details.label.address.title")
        view.contentView.font = .Avenir.medium.withSize(14.0)
        view.contentView.numberOfLines = 0
        return view
    }()

    @View private var checksumSection: PopUpAddressDetailsContentSectionView<UILabel> = {
        let view = PopUpAddressDetailsContentSectionView<UILabel>()
        view.title = localized("address_view.details.label.checksum.title")
        view.contentView.font = .Avenir.medium.withSize(14.0)
        return view
    }()

    @View private var buttonsSectionStackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 10.0
        view.distribution = .fillEqually
        return view
    }()

    @View private var copyRawAddressButton: ActionButton = {
        let view = ActionButton()
        view.setTitle(localized("address_view.details.button.copy.base58"), for: .normal)
        return view
    }()

    @View private var copyEmojiAddressButton: ActionButton = {
        let view = ActionButton()
        view.setTitle(localized("address_view.details.button.copy.emojis"), for: .normal)
        return view
    }()

    // MARK: - Properties

    var onCopyRawAddressButtonTap: (() -> Void)? {
        get { copyRawAddressButton.onTap }
        set { copyRawAddressButton.onTap = newValue }
    }

    var onCopyEmojiAddressButtonTap: (() -> Void)? {
        get { copyEmojiAddressButton.onTap }
        set { copyEmojiAddressButton.onTap = newValue }
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

        addSubview(stackView)
        [networkSection, featuresSection, viewKeySection, coreAddressSection, checksumSection, buttonsSectionStackView].forEach(stackView.addArrangedSubview)
        [copyRawAddressButton, copyEmojiAddressButton].forEach(buttonsSectionStackView.addArrangedSubview)

        let constraints = [
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        viewKeySection.contentView.textColor = theme.text.body
        coreAddressSection.contentView.textColor = theme.text.body
        checksumSection.contentView.textColor = theme.text.body
    }

    func update(viewModel: ViewModel) {

        networkSection.contentView.update(leadingText: viewModel.network, trailingText: viewModel.networkDescription)
        featuresSection.contentView.update(leadingText: viewModel.features, trailingText: viewModel.featuresDescription)
        viewKeySection.contentView.text = viewModel.viewKey
        coreAddressSection.contentView.text = viewModel.coreAddress
        checksumSection.contentView.text = viewModel.checksum

        viewKeySection.isHidden = viewModel.viewKey == nil
    }
}
