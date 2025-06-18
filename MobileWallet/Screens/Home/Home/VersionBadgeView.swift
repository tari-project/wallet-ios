import UIKit
import TariCommon

enum NetworkStatus {
    case connected
    case connectedWithIssues
    case disconnected

    var color: UIColor {
        switch self {
        case .connected:
            return .System.green
        case .connectedWithIssues:
            return .System.yellow
        case .disconnected:
            return .System.red
        }
    }
}

class VersionBadgeView: DynamicThemeView {

    private var networkStatus: NetworkStatus = .disconnected {
        didSet {
            statusCircle.backgroundColor = networkStatus.color
        }
    }

    @TariView private var statusCircle: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: 0xFF3B30) // Default to red
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    @TariView private var verticalSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = .divider
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    @TariView private var versionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false

        if let version = AppVersionFormatter.version {
            let components = version.split(separator: " ", maxSplits: 1)
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

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupConstraints()
        setupGestures()
    }

    override init() {
        super.init()
        setupView()
        setupConstraints()
        setupGestures()
    }

    private func setupView() {
        backgroundColor = .Background.primary
        layer.cornerRadius = 10
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.Elevation.outlined.cgColor

        [statusCircle, verticalSeparator, versionLabel].forEach(addSubview)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            statusCircle.leftAnchor.constraint(equalTo: leftAnchor, constant: 5),
            statusCircle.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusCircle.widthAnchor.constraint(equalToConstant: 8),
            statusCircle.heightAnchor.constraint(equalToConstant: 8),

            verticalSeparator.leftAnchor.constraint(equalTo: statusCircle.rightAnchor, constant: 5),
            verticalSeparator.centerYAnchor.constraint(equalTo: centerYAnchor),
            verticalSeparator.widthAnchor.constraint(equalToConstant: 2),
            verticalSeparator.heightAnchor.constraint(equalToConstant: 8),

            versionLabel.leftAnchor.constraint(equalTo: verticalSeparator.rightAnchor, constant: 5),
            versionLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -5),
            versionLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -2),
            versionLabel.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }

    @objc private func handleTap() {
        AppConnectionHandler.shared.connectionMonitor.showDetailsPopup()
    }

    func updateNetworkStatus(
        networkConnection: NetworkMonitor.Status,
        torStatus: TorConnectionStatus,
        baseNodeStatus: BaseNodeConnectivityStatus,
        syncStatus: TariValidationService.SyncStatus
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Check network connection first
            if case .disconnected = networkConnection {
                self.networkStatus = .disconnected
                return
            }

            // Check Tor status
            if case .disconnected = torStatus, case .disconnecting = torStatus {
                self.networkStatus = .disconnected
                return
            }

            // Check base node status
            switch baseNodeStatus {
            case .online:
                // Check sync status
                if case .synced = syncStatus {
                    self.networkStatus = .connected
                } else {
                    self.networkStatus = .connectedWithIssues
                }
            case .connecting:
                self.networkStatus = .connectedWithIssues
            case .offline:
                self.networkStatus = .disconnected
            }
        }
    }

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        backgroundColor = theme.backgrounds.primary
        layer.borderColor = UIColor.Elevation.outlined.cgColor
    }
}
