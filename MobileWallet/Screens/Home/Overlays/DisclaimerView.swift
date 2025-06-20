import UIKit
import TariCommon

class DisclaimerView: UIView {

    @TariView private var containerView: UIView = {
        let view = UIView()
        return view
    }()

    @TariView private var balanceContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    @TariView private var balanceLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.SemiBold.withSize(32)
        label.textColor = .Text.primary
        label.text = "0"
        return label
    }()

    @TariView private var unitLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.SemiBold.withSize(32)
        label.textColor = .Text.primary
        label.text = NetworkManager.shared.currencySymbol
        return label
    }()

    @TariView private var separator1: UIView = {
        let view = UIView()
        view.backgroundColor = .Text.primary.withAlphaComponent(0.1)
        return view
    }()

    @TariView private var totalBalanceTitle: UILabel = {
        let label = UILabel()
        label.font = .Poppins.SemiBold.withSize(16)
        label.textColor = .Text.primary
        label.text = "Total Balance"
        return label
    }()

    @TariView private var totalBalanceDescription: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(14)
        label.textColor = .Text.secondary
        label.textAlignment = .left
        label.numberOfLines = 0
        label.text = "This is everything you've earned or received, including rewards that are still locked or pending."
        return label
    }()

    @TariView private var separator2: UIView = {
        let view = UIView()
        view.backgroundColor = .Text.primary.withAlphaComponent(0.1)
        return view
    }()

    @TariView private var availableToSpendTitle: UILabel = {
        let label = UILabel()
        label.font = .Poppins.SemiBold.withSize(16)
        label.textColor = .Text.primary
        label.text = "Available to spend"
        return label
    }()

    @TariView private var availableToSpendDescription: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(14)
        label.textColor = .Text.secondary
        label.textAlignment = .left
        label.numberOfLines = 0
        label.text = "This is the amount you can use right now. Some rewards take time to unlock or confirm."
        return label
    }()

    @TariView private var totalBalanceValue: UILabel = {
        let label = UILabel()
        label.font = .Poppins.SemiBold.withSize(16)
        label.textColor = .Text.primary
        label.text = "0 " + NetworkManager.shared.currencySymbol
        return label
    }()

    @TariView private var availableBalanceValue: UILabel = {
        let label = UILabel()
        label.font = .Poppins.SemiBold.withSize(16)
        label.textColor = .Text.primary
        label.text = "0 " + NetworkManager.shared.currencySymbol
        return label
    }()

    var totalBalance: String = "" {
        didSet {
            balanceLabel.text = totalBalance
            totalBalanceValue.text = "\(totalBalance) " + NetworkManager.shared.currencySymbol
        }
    }

    var availableBalance: String = "" {
        didSet {
            availableBalanceValue.text = "\(availableBalance) " + NetworkManager.shared.currencySymbol
        }
    }

    @TariView private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(24)
        label.textColor = .Text.primary
        label.text = "Disclaimer"
        return label
    }()

    @TariView private var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Regular.withSize(16)
        label.textColor = .Text.primary
        label.textAlignment = .left
        label.numberOfLines = 0
        label.text = "Lorem ipsum dolor sit amet"
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    var onCloseButtonTap: (() -> Void)? {
        didSet {
            // No longer needed since we removed the close button
        }
    }

    func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false

        containerView.clipsToBounds = true
        containerView.layer.cornerRadius = 30
        containerView.layer.borderWidth = 1 / UIScreen.main.scale

        setupConstraints()
        updateTheme()
    }

    private func setupConstraints() {
        let subviews = [
            containerView, balanceContainer,
            separator1, totalBalanceTitle, totalBalanceDescription,
            separator2, availableToSpendTitle, availableToSpendDescription,
            totalBalanceValue, availableBalanceValue
        ]
        subviews.forEach(addSubview)
        [balanceLabel, unitLabel].forEach(balanceContainer.addSubview)

        let constraints = [
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.leftAnchor.constraint(equalTo: leftAnchor),
            containerView.rightAnchor.constraint(equalTo: rightAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 400),

            balanceContainer.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            balanceContainer.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 20),
            balanceContainer.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -20),
            balanceContainer.heightAnchor.constraint(equalToConstant: 60),

            balanceLabel.centerYAnchor.constraint(equalTo: balanceContainer.centerYAnchor),
            balanceLabel.leftAnchor.constraint(equalTo: balanceContainer.leftAnchor),

            unitLabel.centerYAnchor.constraint(equalTo: balanceLabel.centerYAnchor),
            unitLabel.leftAnchor.constraint(equalTo: balanceLabel.rightAnchor, constant: 4),

            separator1.topAnchor.constraint(equalTo: balanceContainer.bottomAnchor, constant: 15),
            separator1.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 20),
            separator1.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -20),
            separator1.heightAnchor.constraint(equalToConstant: 1),

            totalBalanceTitle.topAnchor.constraint(equalTo: separator1.bottomAnchor, constant: 15),
            totalBalanceTitle.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 20),
            totalBalanceTitle.rightAnchor.constraint(lessThanOrEqualTo: totalBalanceValue.leftAnchor, constant: -8),

            totalBalanceValue.centerYAnchor.constraint(equalTo: totalBalanceTitle.centerYAnchor),
            totalBalanceValue.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -20),

            totalBalanceDescription.topAnchor.constraint(equalTo: totalBalanceTitle.bottomAnchor, constant: 6),
            totalBalanceDescription.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 20),
            totalBalanceDescription.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -20),

            separator2.topAnchor.constraint(equalTo: totalBalanceDescription.bottomAnchor, constant: 15),
            separator2.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 20),
            separator2.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -20),
            separator2.heightAnchor.constraint(equalToConstant: 1),

            availableToSpendTitle.topAnchor.constraint(equalTo: separator2.bottomAnchor, constant: 15),
            availableToSpendTitle.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 20),
            availableToSpendTitle.rightAnchor.constraint(lessThanOrEqualTo: availableBalanceValue.leftAnchor, constant: -8),

            availableBalanceValue.centerYAnchor.constraint(equalTo: availableToSpendTitle.centerYAnchor),
            availableBalanceValue.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -20),

            availableToSpendDescription.topAnchor.constraint(equalTo: availableToSpendTitle.bottomAnchor, constant: 6),
            availableToSpendDescription.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 20),
            availableToSpendDescription.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -20),
            availableToSpendDescription.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -20)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func updateTheme() {
        containerView.backgroundColor = .Background.popup
        containerView.layer.borderColor = UIColor.Elevation.outlined.cgColor
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        // Allow closing by tapping anywhere
        onCloseButtonTap?()
    }
}
