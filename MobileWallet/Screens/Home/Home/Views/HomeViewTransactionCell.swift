//  HomeViewTransactionCell.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 28/06/2023
	Using Swift 5.0
	Running on macOS 13.4

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
import Combine

final class HomeViewTransactionCell: UITableViewCell {

    struct ViewModel: Identifiable, Hashable {
        let id: UInt64
        let titleComponents: [StylizedLabel.StylizedText]
        let timestamp: TimeInterval
        let amount: AmountBadge.ViewModel

        static func == (lhs: HomeViewTransactionCell.ViewModel, rhs: HomeViewTransactionCell.ViewModel) -> Bool { lhs.id == rhs.id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    // MARK: - Constants

    static let defaultHeight: CGFloat = 70.0

    // MARK: - Subviews

    @View private var glassBackgroundView = HomeGlassView()
    @View private var labelsContentView = UIView()

    @View private var titleLabel: StylizedLabel = {
        let view = StylizedLabel()
        view.textColor = .static.white
        view.normalFont = .Avenir.medium.withSize(12.0)
        view.boldFont = .Avenir.black.withSize(12.0)
        view.separator = " "
        return view
    }()

    @View private var timestampLabel: UILabel = {
        let view = UILabel()
        view.textColor = .static.white
        view.font = .Avenir.light.withSize(11.0)
        return view
    }()

    @View private var amountView: AmountBadge = {
        let view = AmountBadge()
        view.enforcedTheme = .light
        return view
    }()

    // MARK: - Properties

    private(set) var identifier: UInt64?
    private var dynamicModel: TransactionDynamicModel?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none
    }

    private func setupConstraints() {

        contentView.addSubview(glassBackgroundView)
        [titleLabel, timestampLabel].forEach(labelsContentView.addSubview)
        [labelsContentView, amountView].forEach(glassBackgroundView.addSubview)

        let constraints = [
            glassBackgroundView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5.0),
            glassBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            glassBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            glassBackgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5.0),
            labelsContentView.leadingAnchor.constraint(equalTo: glassBackgroundView.leadingAnchor, constant: 10.0),
            labelsContentView.trailingAnchor.constraint(equalTo: amountView.leadingAnchor, constant: -5.0),
            labelsContentView.centerYAnchor.constraint(equalTo: glassBackgroundView.centerYAnchor),
            titleLabel.topAnchor.constraint(equalTo: labelsContentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: labelsContentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: labelsContentView.trailingAnchor),
            timestampLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            timestampLabel.leadingAnchor.constraint(equalTo: labelsContentView.leadingAnchor),
            timestampLabel.trailingAnchor.constraint(equalTo: labelsContentView.trailingAnchor),
            timestampLabel.bottomAnchor.constraint(equalTo: labelsContentView.bottomAnchor),
            amountView.topAnchor.constraint(equalTo: labelsContentView.topAnchor),
            amountView.trailingAnchor.constraint(equalTo: glassBackgroundView.trailingAnchor, constant: -10.0),
            contentView.heightAnchor.constraint(equalToConstant: Self.defaultHeight)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    func update(viewModel: ViewModel) {

        identifier = viewModel.id
        titleLabel.textComponents = viewModel.titleComponents
        amountView.update(viewModel: viewModel.amount)

        dynamicModel = TransactionDynamicModel(timestamp: viewModel.timestamp, giphyID: nil)

        dynamicModel?.$formattedTimestamp
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.timestampLabel.text = $0 }
            .store(in: &cancellables)
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        dynamicModel = nil
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
