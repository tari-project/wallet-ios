//  TransactionTotalCell.swift

import TariCommon
import UIKit

final class TransactionTotalCell: DynamicThemeCell {

    // MARK: - Subviews

    @View private var totalLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.SemiBold.withSize(16)
        label.text = "Total"
        return label
    }()

    @View private var totalValueLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.SemiBold.withSize(16)
        return label
    }()

    // MARK: - Properties

    var totalText: String? {
        didSet {
            totalValueLabel.text = totalText
        }
    }

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
        contentView.addSubview(totalLabel)
        contentView.addSubview(totalValueLabel)
    }

    private func setupConstraints() {
        let constraints = [
            totalLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            totalLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22),
            totalLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            totalValueLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            totalValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22),
            totalValueLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            contentView.heightAnchor.constraint(equalToConstant: 48)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        totalLabel.textColor = theme.text.heading
        totalValueLabel.textColor = theme.text.heading
    }
}
