import UIKit
import TariCommon
import TariLib

enum NetworkStatus {
    case connected
    case connectedWithIssues
    case disconnected

    var color: UIColor {
        switch self {
        case .connected:
            return .System.Green
        case .connectedWithIssues:
            return .System.Yellow
        case .disconnected:
            return .System.Red
        }
    }
}

class VersionBadgeView: UIView {

    private var networkStatus: NetworkStatus = .disconnected {
        didSet {
            statusCircle.backgroundColor = networkStatus.color
        }
    }

    @View private var statusCircle: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: 0xFF3B30) // Default to red
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
            attributedString.append(NSAttributedString(string: String(NetworkManager.shared.network.version), attributes: versionAttributes))

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
            statusCircle.leftAnchor.constraint(equalTo: leftAnchor, constant: 5),
            statusCircle.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusCircle.widthAnchor.constraint(equalToConstant: 8),
            statusCircle.heightAnchor.constraint(equalToConstant: 8),

            verticalSeparator.leftAnchor.constraint(equalTo: statusCircle.rightAnchor, constant: 5),
            verticalSeparator.centerYAnchor.constraint(equalTo: centerYAnchor),
            verticalSeparator.widthAnchor.constraint(equalToConstant: 3),
            verticalSeparator.heightAnchor.constraint(equalToConstant: 8),

            versionLabel.leftAnchor.constraint(equalTo: verticalSeparator.rightAnchor, constant: 5),
            versionLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            versionLabel.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    func updateNetworkStatus(
        networkConnection: NetworkMonitor.Status,
        torStatus: TorConnectionStatus,
        baseNodeStatus: BaseNodeConnectivityStatus,
        syncStatus: TariValidationService.SyncStatus
    ) {
        // Check network connection first
        if networkConnection == .unknown || networkConnection == .disconnected {
            networkStatus = .disconnected
            return
        }

        // Check Tor status
        if torStatus == .failed || torStatus == .initializing || torStatus == .notReady {
            networkStatus = .disconnected
            return
        }

        // Check base node status
        switch baseNodeStatus {
        case .online, .syncing:
            // Check sync status
            if syncStatus == .online || syncStatus == .syncing {
                networkStatus = .connected
            } else {
                networkStatus = .connectedWithIssues
            }
        case .offline:
            networkStatus = .disconnected
        }
    }
}
