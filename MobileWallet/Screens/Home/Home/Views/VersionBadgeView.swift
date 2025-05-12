import TariCommon

class VersionBadgeView: UIView {

    @View private var statusCircle: UIView = {
        let view = UIView()
        view.backgroundColor = .System.green
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    @View private var verticalSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = .divider
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    @View private var versionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false

        if let version = AppVersionFormatter.version {
            let components = version.split(separator: " ", maxSplits: 2)
            let attributedString = NSMutableAttributedString()

            // First part (network name)
            if let networkName = components.first {
                let networkAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.Poppins.SemiBold.withSize(11),
                    .foregroundColor: UIColor.Text.primary
                ]
                attributedString.append(NSAttributedString(string: String(networkName), attributes: networkAttributes))
            }

            // Add space
            attributedString.append(NSAttributedString(string: " "))

            let versionAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.Poppins.SemiBold.withSize(11),
                .foregroundColor: UIColor.Text.secondary
            ]
            attributedString.append(NSAttributedString(string: String(NetworkManager.shared.selectedNetwork.version), attributes: versionAttributes))

            label.attributedText = attributedString
        }

        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupConstraints()
    }

    private func setupView() {
        backgroundColor = .Background.primary
        layer.cornerRadius = 10
        layer.borderWidth = 1
        layer.borderColor = UIColor.Elevation.outlined.cgColor

        [statusCircle, verticalSeparator, versionLabel].forEach(addSubview)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            statusCircle.leftAnchor.constraint(equalTo: leftAnchor, constant: 8),
            statusCircle.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusCircle.widthAnchor.constraint(equalToConstant: 8),
            statusCircle.heightAnchor.constraint(equalToConstant: 8),

            verticalSeparator.leftAnchor.constraint(equalTo: statusCircle.rightAnchor, constant: 5),
            verticalSeparator.centerYAnchor.constraint(equalTo: centerYAnchor),
            verticalSeparator.widthAnchor.constraint(equalToConstant: 2),
            verticalSeparator.heightAnchor.constraint(equalToConstant: 8),

            versionLabel.leftAnchor.constraint(equalTo: verticalSeparator.rightAnchor, constant: 8),
            versionLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -2),
            versionLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -8)
        ])
    }
}
