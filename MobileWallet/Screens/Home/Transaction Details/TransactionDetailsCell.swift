//  TransactionDetailsCell.swift

import TariCommon
import UIKit

final class TransactionDetailsCell: DynamicThemeCell {

    // MARK: - Subviews

    @View private var detailView: DetailView = {
        let view = DetailView()
        return view
    }()

    // MARK: - Properties

    var onCopyButtonTap: ((_ value: String?) -> Void)? {
        didSet {
            detailView.onCopyButonTap = onCopyButtonTap
        }
    }

    var titleText: String? {
        didSet {
            detailView.titleText = titleText
        }
    }

    var valueText: String? {
        didSet {
            detailView.valueText = valueText
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
        contentView.addSubview(detailView)
    }

    private func setupConstraints() {
        let constraints = [
            detailView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            detailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22),
            detailView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22),
            detailView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            contentView.heightAnchor.constraint(equalToConstant: 48)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        detailView.update(theme: theme)
    }
}
