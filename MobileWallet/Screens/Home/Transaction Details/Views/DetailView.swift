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

    var onAddContactTap: (() -> Void)? {
        didSet {
            addContactButton.removeTarget(nil, action: nil, for: .touchUpInside)
            if let action = onAddContactTap {
                addContactButton.addAction(UIAction(handler: { _ in action() }), for: .touchUpInside)
            }
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

    var showAddContactButton: Bool = false {
        didSet {
            addContactButton.isHidden = !showAddContactButton
            copyButton.isHidden = showAddContactButton
        }
    }

    private var buttonAction: UIAction?

    public var isAddressCell: Bool = false {
        didSet {
            addressTypeButton.isHidden = !isAddressCell
            copyButton.isHidden = false

            // Remove existing action if any
            if let action = buttonAction {
                addressTypeButton.removeAction(action, for: .touchUpInside)
                buttonAction = nil
            }

            // Add new action if it's an address cell
            if isAddressCell {
                let action = UIAction(handler: { [weak self] _ in
                    guard let self else { return }
                    self.isEmojiFormat.toggle()
                    self.onAddressFormatToggle?(self.isEmojiFormat)
                })
                addressTypeButton.addAction(action, for: .touchUpInside)
                buttonAction = action
            }
        }
    }

    var isEmojiFormat: Bool = true {
        didSet {
            addressTypeButton.setImage(isEmojiFormat ? .emojiAddress : .textAddress, for: .normal)
        }
    }

    var onAddressFormatToggle: ((_ isEmojiFormat: Bool) -> Void)?

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

    @View private var addressTypeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(.emojiAddress.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .Text.primary
        button.backgroundColor = .clear
        return button
    }()

    @View private var addContactButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(.editContact.withRenderingMode(.alwaysTemplate), for: .normal)
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
        [titleLabel, valueLabel, separatorView, copyButton, addressTypeButton, addContactButton].forEach(addSubview)

        let constraints = [
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: addressTypeButton.leadingAnchor, constant: -8),

            copyButton.centerYAnchor.constraint(equalTo: valueLabel.centerYAnchor),
            copyButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            copyButton.heightAnchor.constraint(equalToConstant: 22),
            copyButton.widthAnchor.constraint(equalToConstant: 22),

            addContactButton.centerYAnchor.constraint(equalTo: valueLabel.centerYAnchor),
            addContactButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            addContactButton.heightAnchor.constraint(equalToConstant: 22),
            addContactButton.widthAnchor.constraint(equalToConstant: 22),

            addressTypeButton.centerYAnchor.constraint(equalTo: valueLabel.centerYAnchor),
            addressTypeButton.trailingAnchor.constraint(equalTo: copyButton.leadingAnchor, constant: -7),
            addressTypeButton.heightAnchor.constraint(equalToConstant: 22),
            addressTypeButton.widthAnchor.constraint(equalToConstant: 22),

            separatorView.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 8),
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
        addressTypeButton.isHidden = true
        addContactButton.isHidden = true
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
