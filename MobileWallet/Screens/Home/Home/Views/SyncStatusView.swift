import UIKit
import TariCommon

final class SyncStatusView: DynamicThemeView {

    // MARK: - Subviews

    @TariView private var containerView: UIView = {
        let view = UIView()
        return view
    }()

    @TariView private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(12)
        label.text = "Sync in progress ⌛️"
        return label
    }()

    @TariView private var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(12)
        label.text = "Some actions may be disabled until the sync is complete."
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Initialisers

    override init() {
        super.init()
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Setups

    private func setupViews() {
        clipsToBounds = true
        layer.cornerRadius = 16
        translatesAutoresizingMaskIntoConstraints = false

        [containerView].forEach(addSubview)
        [titleLabel, descriptionLabel].forEach(containerView.addSubview)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            descriptionLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }

    override func update(theme: AppTheme) {
        super.update(theme: theme)

        titleLabel.textColor = .Components.ratingActiveFill
        descriptionLabel.textColor = UIColor(hex: 0xFFFFFF)
        backgroundColor = UIColor(hex: 0x08150D)
    }
}
