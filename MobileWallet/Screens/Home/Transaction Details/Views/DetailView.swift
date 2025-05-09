//  DetailView.swift

import TariCommon
import UIKit

class DetailView: DynamicThemeView {

    // MARK: - Properties

    var onCopyButonTap: ((_ value: String?) -> Void)? {
        didSet {
            copyButton.removeTarget(nil, action: nil, for: .touchUpInside)
            if let action = onCopyButonTap {
                copyButton.addTarget(self, action: #selector(handleCopyButtonTap(_:)), for: .touchUpInside)
            }
        }
    }

    var onAddContactTap: (() -> Void)? {
        didSet {
            addContactButton.removeTarget(nil, action: nil, for: .touchUpInside)
            if let action = onAddContactTap {
                addContactButton.addTarget(self, action: #selector(handleAddContactTap(_:)), for: .touchUpInside)
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
                addressTypeButton.addTarget(self, action: #selector(handleAddressTypeButtonTap(_:)), for: .touchUpInside)
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
        button.isUserInteractionEnabled = true
        button.imageEdgeInsets = UIEdgeInsets(top: 11, left: 11, bottom: 11, right: 11)
        button.addTarget(self, action: #selector(handleCopyButtonTap(_:)), for: .touchUpInside)
        return button
    }()

    @View private var addressTypeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(.emojiAddress.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .Text.primary
        button.backgroundColor = .clear
        button.imageEdgeInsets = UIEdgeInsets(top: 11, left: 11, bottom: 11, right: 11)
        button.addTarget(self, action: #selector(handleAddressTypeButtonTap(_:)), for: .touchUpInside)
        return button
    }()

    @View private var addContactButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(.editContact.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .Text.primary
        button.backgroundColor = .clear
        button.imageEdgeInsets = UIEdgeInsets(top: 11, left: 11, bottom: 11, right: 11)
        button.addTarget(self, action: #selector(handleAddContactTap(_:)), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialisers

    override init() {
        super.init()
        setupViews()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        backgroundColor = .clear
        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(separatorView)
        addSubview(copyButton)
        addSubview(addressTypeButton)
        addSubview(addContactButton)
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
            copyButton.heightAnchor.constraint(equalToConstant: 44),
            copyButton.widthAnchor.constraint(equalToConstant: 44),

            addContactButton.centerYAnchor.constraint(equalTo: valueLabel.centerYAnchor),
            addContactButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            addContactButton.heightAnchor.constraint(equalToConstant: 44),
            addContactButton.widthAnchor.constraint(equalToConstant: 44),

            addressTypeButton.centerYAnchor.constraint(equalTo: valueLabel.centerYAnchor),
            addressTypeButton.rightAnchor.constraint(equalTo: copyButton.leftAnchor, constant: -7),
            addressTypeButton.heightAnchor.constraint(equalToConstant: 44),
            addressTypeButton.widthAnchor.constraint(equalToConstant: 44),

            separatorView.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 10),
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
        addressTypeButton.isHidden = true
        addContactButton.isHidden = true
    }

    private func setupCallbacks() {
        copyButton.addTarget(self, action: #selector(handleCopyButtonTap(_:)), for: .touchUpInside)
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

    // MARK: - Actions

    @objc private func handleCopyButtonTap(_ sender: UIButton) {
        onCopyButonTap?(valueText)
    }

    @objc private func handleAddContactTap(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                sender.transform = .identity
            }
        }
        onAddContactTap?()
    }

    @objc private func handleAddressTypeButtonTap(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                sender.transform = .identity
            }
        }
        isEmojiFormat.toggle()
        onAddressFormatToggle?(isEmojiFormat)
    }

    // MARK: - Cleanup

    func cleanup() {
        // Remove all targets from all buttons
        copyButton.removeTarget(nil, action: nil, for: .allEvents)
        addContactButton.removeTarget(nil, action: nil, for: .allEvents)
        addressTypeButton.removeTarget(nil, action: nil, for: .allEvents)

        // Reset all callbacks
        onCopyButonTap = nil
        onAddContactTap = nil
        onAddressFormatToggle = nil
    }
}
