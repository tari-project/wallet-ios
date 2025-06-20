import TariCommon

class MinersGradientView: UIView {
    private let gradientLayer = CAGradientLayer()

    @TariView private var startMiningButton: StylisedButton = {
        let startMiningButton = StylisedButton(withStyle: .mining, withSize: .xsmall)
        startMiningButton.setTitle("Start mining", for: .normal)
        return startMiningButton
    }()

    @TariView private var miningStatusLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.SemiBold.withSize(12)
        label.textColor = UIColor(hex: 0x02FE63)
        label.text = "You're mining"
        label.isHidden = true
        return label
    }()

    @TariView private var notMiningLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.SemiBold.withSize(12)
        label.textColor = .System.red
        label.text = "You're not mining"
        label.isHidden = true
        return label
    }()

    private func isSyncedToDesktop() -> Bool {
        return NotificationManager.shared.appId != nil
    }

    public func setActiveMiners(activeMiners: String) {
        minersLabel.text = activeMiners
    }

    public func setMiningActive(_ isActive: Bool) {
        if isSyncedToDesktop() {
            startMiningButton.isHidden = true
            miningStatusLabel.isHidden = !isActive
            notMiningLabel.isHidden = isActive
        } else {
            startMiningButton.isHidden = false
            miningStatusLabel.isHidden = true
            notMiningLabel.isHidden = true
        }
    }

    var onStartMiningTap: (() -> Void)? {
        didSet {
            startMiningButton.onTap = onStartMiningTap
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
        setupSubviews()
    }

    @TariView private var minersLabel: UILabel = {
        let minersLabel = UILabel()
        minersLabel.font = .Poppins.SemiBold.withSize(24)
        minersLabel.textColor = .white
        minersLabel.translatesAutoresizingMaskIntoConstraints = false
        return minersLabel
    }()

    private func setupSubviews() {
        let label = UILabel()

        label.font = .Poppins.Medium.withSize(12)
        label.textColor = .white
        label.alpha = 0.5
        label.text = "Active Miners"
        label.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView(image: .minersIcon)
        iconView.translatesAutoresizingMaskIntoConstraints = false

        [label, iconView, minersLabel, startMiningButton, miningStatusLabel, notMiningLabel].forEach(addSubview)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            label.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
            iconView.leftAnchor.constraint(equalTo: label.leftAnchor, constant: 0),
            iconView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),
            minersLabel.leftAnchor.constraint(equalTo: iconView.rightAnchor, constant: 6),
            minersLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor, constant: 0),
            startMiningButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
            startMiningButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -20),
            miningStatusLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
            miningStatusLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -20),
            notMiningLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
            notMiningLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -20)
        ])
    }

    private func setupGradient() {
        gradientLayer.colors = [
            UIColor(hex: 0x0E1510).cgColor,
            UIColor(hex: 0x07160B).cgColor
        ]
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.25, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 0.75, y: 0.5)
        layer.insertSublayer(gradientLayer, at: 0)
        layer.cornerRadius = 16
        clipsToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
