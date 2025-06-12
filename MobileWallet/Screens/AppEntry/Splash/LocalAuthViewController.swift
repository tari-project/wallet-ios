import UIKit
import LocalAuthentication
import Combine

final class LocalAuthViewController: UIViewController {

    // MARK: - Properties

    private let localAuth = LAContext()
    private var cancellables = Set<AnyCancellable>()
    private let mainView = SplashView()
    private var continueButton: StylisedButton?

    var onAuthenticationSuccess: (() -> Void)?
    var onAuthenticationFailure: (() -> Void)?

    // MARK: - Initialisers

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
        setupContinueButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        authenticateUser()
    }

    // MARK: - Setups

    private func setupCallbacks() {
        // Hide the default buttons and label container
        mainView.importWallet.isHidden = true
        mainView.createWallet.isHidden = true
        mainView.importWalletLabelContainer.isHidden = true
    }

    private func setupContinueButton() {
        let button = StylisedButton(withStyle: .primary, withSize: .large)
        button.setTitle(localized("common.continue"), for: .normal)
        button.onTap = { [weak self] in
            self?.authenticateUser()
        }

        continueButton = button
        mainView.addSubview(button)

        // Position the button at the same position as the importWallet button
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: mainView.importWallet.centerYAnchor),
            button.widthAnchor.constraint(equalTo: mainView.importWallet.widthAnchor),
            button.heightAnchor.constraint(equalTo: mainView.importWallet.heightAnchor)
        ])
    }

    // MARK: - Actions

    private func authenticateUser() {
        // Skip auth on simulator, quicker for development
        guard !AppValues.general.isSimulator else {
            onAuthenticationSuccess?()
            return
        }

        localAuth.authenticateUserWithFailureHandling(
            onSuccess: { [weak self] in
                self?.onAuthenticationSuccess?()
            },
            onFailure: { [weak self] in
                self?.onAuthenticationFailure?()
            }
        )
    }
}
