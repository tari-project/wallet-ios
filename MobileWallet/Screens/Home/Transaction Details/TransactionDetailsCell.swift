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

    var onAddContactTap: (() -> Void)? {
        didSet {
            detailView.onAddContactTap = onAddContactTap
        }
    }

    var onEditButtonTap: (() -> Void)? {
        didSet {
            detailView.onEditButtonTap = onEditButtonTap
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

    var isAddressCell: Bool = false {
        didSet {
            detailView.isAddressCell = isAddressCell
        }
    }

    var isEmojiFormat: Bool = true {
        didSet {
            detailView.isEmojiFormat = isEmojiFormat
        }
    }

    var onAddressFormatToggle: ((_ isEmojiFormat: Bool) -> Void)? {
        didSet {
            detailView.onAddressFormatToggle = onAddressFormatToggle
        }
    }

    var showAddContactButton: Bool = false {
        didSet {
            detailView.showAddContactButton = showAddContactButton
        }
    }

    var showEditButton: Bool = false {
        didSet {
            detailView.showEditButton = showEditButton
        }
    }

    var showBlockExplorerButton: Bool = false {
        didSet {
            detailView.showBlockExplorerButton = showBlockExplorerButton
        }
    }

    var onBlockExplorerButtonTap: (() -> Void)? {
        didSet {
            detailView.onBlockExplorerButtonTap = onBlockExplorerButtonTap
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
            contentView.heightAnchor.constraint(equalToConstant: 74)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        detailView.update(theme: theme)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleText = nil
        valueText = nil
        isAddressCell = false
        isEmojiFormat = true
        onCopyButtonTap = nil
        onAddressFormatToggle = nil
        showAddContactButton = false
        showEditButton = false
        showBlockExplorerButton = false
        onEditButtonTap = nil
        onBlockExplorerButtonTap = nil
        detailView.cleanup()
    }
}
