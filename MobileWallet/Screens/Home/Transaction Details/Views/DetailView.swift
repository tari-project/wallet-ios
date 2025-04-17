//  DetailView.swift

import TariCommon
import UIKit

class DetailView: DynamicThemeView {

    // MARK: - Properties

    var onCopyButonTap: ((_ value: String?) -> Void)? {
        didSet {
            copyButton.addAction(UIAction(handler: { [weak self] _ in
                self?.onCopyButonTap?(self?.valueText)
            }), for: .touchUpInside)
        }
    }

    var titleText: String? {
        didSet {
            titleLabel.text = titleText
        }
    }

    var valueText: String? {
        didSet {
            valueLabel.text = valueText
        }
    }

    // MARK: - Subviews

    @View private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(12)
        return label
    }()

    @View private var valueLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(14)
        return label
    }()

    @View private var separatorView: UIView = {
        let view = UIView()
        return view
    }()

    @View private var copyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(.sendCopy.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .Text.primary
        button.backgroundColor = .clear
        return button
    }()

    // MARK: - Initialisers

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
        backgroundColor = .clear
    }

    private func setupConstraints() {
        [titleLabel, valueLabel, separatorView, copyButton].forEach(addSubview)

        let constraints = [
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: copyButton.leadingAnchor, constant: -8),

            copyButton.centerYAnchor.constraint(equalTo: valueLabel.centerYAnchor),
            copyButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            copyButton.heightAnchor.constraint(equalToConstant: 22),
            copyButton.widthAnchor.constraint(equalToConstant: 22),

            separatorView.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 8),
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        backgroundColor = .clear
        separatorView.backgroundColor = .Token.divider
        titleLabel.textColor = .Text.secondary
        valueLabel.textColor = .Text.primary
        copyButton.tintColor = .Text.primary
    }
}
