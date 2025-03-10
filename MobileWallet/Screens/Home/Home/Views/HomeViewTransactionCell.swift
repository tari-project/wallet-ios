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

final class HomeViewTransactionCell: DynamicThemeCell {

    struct ViewModel: Identifiable, Hashable {
        let id: UInt64
        let titleComponents: [StylizedLabel.StylizedText]
        let timestamp: TimeInterval
        let amount: AmountBadge.ViewModel

        static func == (lhs: HomeViewTransactionCell.ViewModel, rhs: HomeViewTransactionCell.ViewModel) -> Bool {
            lhs.id == rhs.id
            && lhs.titleComponents.map { $0.text } == rhs.titleComponents.map { $0.text }
            && lhs.timestamp == rhs.timestamp
            && lhs.amount == rhs.amount
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(titleComponents.map { $0.text })
            hasher.combine(timestamp)
            hasher.combine(amount)
        }
    }

    var viewModel: ViewModel?

    // MARK: - Constants

    static let defaultHeight: CGFloat = 70.0

    // MARK: - Subviews

    @View private var glassBackgroundView = HomeGlassView()
    @View private var labelsContentView = UIView()

    @View private var iconView: UIImageView = {
        let imageView = UIImageView(image: .gem.withRenderingMode(.alwaysTemplate))
        return imageView
    }()

    @View private var iconViewOutline: UIView = {
        let view = UIView()
        return view
    }()

    @View private var containerView: UIView = {
        let container = UIView()
        container.clipsToBounds = true

        container.backgroundColor = .Background.primary
        container.layer.cornerRadius = 16
        container.layer.borderColor = UIColor.Elevation.outlined.cgColor
        container.layer.borderWidth = 1.0
        container.clipsToBounds = true
        return container
    }()

    @View private var titleLabel: UILabel = {
        let view = UILabel()
        view.textColor = .Text.primary
        view.font = .Poppins.Medium.withSize(13)
        return view
    }()

    @View private var timestampLabel: UILabel = {
        let view = UILabel()
        view.textColor = .Text.secondary
        view.font = .Poppins.Regular.withSize(11.0)
        return view
    }()

    @View private var amountLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.SemiBold.withSize(16)
        label.textColor = .Text.primary
        return label
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

//        layer.cornerRadius = 16
//        layer.borderColor = UIColor.Elevation.outlined.cgColor
//        layer.borderWidth = 1.0
//        clipsToBounds = true
    }

    private func setupConstraints() {

        contentView.addSubview(containerView)
        [titleLabel, timestampLabel].forEach(labelsContentView.addSubview)
        [labelsContentView, amountLabel, iconViewOutline, iconView].forEach(contentView.addSubview)

        let constraints = [
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
            containerView.leftAnchor.constraint(equalTo: leftAnchor),
            containerView.rightAnchor.constraint(equalTo: rightAnchor),
            iconViewOutline.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            iconViewOutline.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            iconViewOutline.widthAnchor.constraint(equalToConstant: 28),
            iconViewOutline.heightAnchor.constraint(equalToConstant: 28),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),
            labelsContentView.leftAnchor.constraint(equalTo: iconView.rightAnchor, constant: 20.0),
            labelsContentView.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.topAnchor.constraint(equalTo: labelsContentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: labelsContentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: labelsContentView.trailingAnchor),
            timestampLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            timestampLabel.leadingAnchor.constraint(equalTo: labelsContentView.leadingAnchor),
            timestampLabel.trailingAnchor.constraint(equalTo: labelsContentView.trailingAnchor),
            timestampLabel.bottomAnchor.constraint(equalTo: labelsContentView.bottomAnchor),
            amountLabel.topAnchor.constraint(equalTo: labelsContentView.topAnchor, constant: 3),
            amountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10.0),
            contentView.heightAnchor.constraint(equalToConstant: Self.defaultHeight)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func layoutSubviews() {
        super.layoutSubviews()

        iconViewOutline.layer.cornerRadius = iconViewOutline.bounds.width / 2
    }

    override func update(theme: AppTheme) {
        super.update(theme: theme)

        if let model = viewModel {
            update(viewModel: model)
        }

        containerView.backgroundColor = .Background.primary
        containerView.layer.borderColor = UIColor.Elevation.outlined.cgColor
        titleLabel.textColor = .Text.primary
        timestampLabel.textColor = .Text.secondary
        iconView.tintColor = .Background.primary
        iconViewOutline.backgroundColor = .Text.primary
    }

    func update(viewModel: ViewModel) {
        self.viewModel = viewModel

        identifier = viewModel.id
        titleLabel.text = "Block #1854"

        var signString: NSAttributedString = NSAttributedString()
        if viewModel.amount.valueType == .positive {
            signString = NSAttributedString(string: "+ ", attributes: [.foregroundColor: UIColor.System.green])
        } else if viewModel.amount.valueType == .negative {
            signString = NSAttributedString(string: "- ", attributes: [.foregroundColor: UIColor.System.red])
        }

        let valueString = viewModel.amount.amount ?? ""
        let amount = NSAttributedString(string: valueString.filter { $0 != "-" && $0 != " " && $0 != "+"} + " tXTM", attributes: [.foregroundColor: UIColor.Text.primary])

        let amountText =  NSMutableAttributedString()
        amountText.append(signString)
        amountText.append(amount)

        amountLabel.attributedText = amountText

//        if viewModel.amount.amount != nil {
//            amount = (viewModel.amount.amount ?? "") + " tXTM"
//        }
//        amountLabel.text = amount
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
