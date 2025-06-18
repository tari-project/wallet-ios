//  NewProfileView.swift

/*
	Package MobileWallet
	Created by Konrad Faltyn on 19/03/2025
	Using Swift 6.0
	Running on macOS 15.3

	Copyright 2019 The Tari Project

	Redistribution and use in source and binary forms, with or
	without modification, are permitted provided that the
	following conditions are met:

	1. Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.

	2. Redistributions in binary form must reproduce the above
	copyright notice, this list of conditions and the following disclaimer in the
	documentation and/or other materials provided with the distribution.

	3. Neither the name of the copyright holder nor the names of
	its contributors may be used to endorse or promote products
	derived from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
	CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
	INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
	OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
	SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
	NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
	HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
	OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import TariCommon

final class InviteView: DynamicThemeView {

    public var onShareButtonTap: (() -> Void)? {
        didSet {
            let action = UIAction { _ in
                self.onShareButtonTap?()
            }
            shareButton.addAction(action, for: .touchUpInside)
        }
    }

    var gradientLayer: CAGradientLayer?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    override init() {
        super.init()
        setupViews()
    }

    @TariView private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(20)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textAlignment = .center
        label.text = "Invite Friends, Earn 5000 Gems"
        return label
    }()

    @TariView private var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Regular.withSize(14)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Earn gems by mining and referring friends to increase your airdrop reward during testnet! "
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    @TariView private var outlineView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 25
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    @TariView public var linkLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.SemiBold.withSize(14)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()

    @TariView public var shareButton: UIButton = {
        let button = UIButton()
        button.setTitle("SHARE", for: .normal)
        button.setImage(.copy, for: .normal)
        button.setTitleColor(.black, for: .normal)

        button.backgroundColor = UIColor(red: 0.79, green: 0.92, blue: 0, alpha: 1)
        button.titleLabel?.font = .Poppins.SemiBold.withSize(12)
        button.layer.cornerRadius = 13
        return button
    }()

    func setupViews() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(hex: 0xCAEB01).cgColor,
            UIColor(hex: 0xCAEB01).withAlphaComponent(0.05).cgColor
        ]
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.25)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.frame = bounds
        layer.insertSublayer(gradientLayer, at: 0)

        self.gradientLayer = gradientLayer

        gradientLayer.cornerRadius = 20
        layer.cornerRadius = 20
        backgroundColor = .clear

        [titleLabel, descriptionLabel, outlineView, linkLabel, shareButton].forEach(addSubview)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            descriptionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            descriptionLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 15),
            descriptionLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -15),
            outlineView.heightAnchor.constraint(equalToConstant: 50),
            outlineView.widthAnchor.constraint(equalToConstant: 318),
            outlineView.centerXAnchor.constraint(equalTo: centerXAnchor),
            outlineView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -32.5),
            linkLabel.leftAnchor.constraint(equalTo: outlineView.leftAnchor, constant: 26),
            linkLabel.centerYAnchor.constraint(equalTo: outlineView.centerYAnchor),
            shareButton.centerYAnchor.constraint(equalTo: outlineView.centerYAnchor),
            shareButton.heightAnchor.constraint(equalToConstant: 27),
            shareButton.widthAnchor.constraint(equalToConstant: 78),
            shareButton.rightAnchor.constraint(equalTo: outlineView.rightAnchor, constant: -14)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = bounds
    }

    override func update(theme: AppTheme) {
        super.update(theme: theme)

        titleLabel.textColor = .black
        descriptionLabel.textColor = .black
        linkLabel.textColor = .white
    }
}

final class GaugeView: DynamicThemeView {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    override init() {
        super.init()
        setupViews()
    }

    @TariView private var minedIconView: UIImageView = {
        let view = UIImageView()
        return view
    }()

    @TariView private var amountLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(22)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        return label
    }()

    @TariView private var unitLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(15)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        return label
    }()

    @TariView private var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(12)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        return label
    }()

    override func update(theme: AppTheme) {
        super.update(theme: theme)

        amountLabel.textColor = .Text.primary
        unitLabel.textColor = .Text.primary
        descriptionLabel.textColor = .Text.secondary
        backgroundColor = .Background.primary
    }

    func setAmount(amount: String) {
        amountLabel.text = amount
    }

    func setUnit(unit: String) {
        unitLabel.text = unit
    }

    func setDescription(description: String) {
        descriptionLabel.text = description
    }

    func setIcon(image: UIImage) {
        minedIconView.image = image
    }

    func setupViews() {
        layer.cornerRadius = 16

        [minedIconView, amountLabel, unitLabel, descriptionLabel].forEach(addSubview)

        NSLayoutConstraint.activate([
            minedIconView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            minedIconView.leftAnchor.constraint(equalTo: leftAnchor, constant: 10),
            minedIconView.widthAnchor.constraint(equalToConstant: 33),
            minedIconView.heightAnchor.constraint(equalToConstant: 33),
            amountLabel.leftAnchor.constraint(equalTo: minedIconView.leftAnchor),
            amountLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -26),
            unitLabel.leftAnchor.constraint(equalTo: amountLabel.rightAnchor),
            unitLabel.bottomAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: -4),
            descriptionLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            descriptionLabel.leftAnchor.constraint(equalTo: minedIconView.leftAnchor)
        ])
    }
}

final class NewProfileView: DynamicThemeView {

    public var onLoginButtonTap: (() -> Void)? {
        didSet {
            let action = UIAction { _ in
                self.onLoginButtonTap?()
            }
            loginButton.addAction(action, for: .touchUpInside)
        }
    }

    public var onLogoutButtonTap: (() -> Void)? {
        didSet {
            let action = UIAction { _ in
                self.onLogoutButtonTap?()
            }
            logoutButton.addAction(action, for: .touchUpInside)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupConstraints()
        update(theme: theme)
    }

    override init() {
        super.init()
        setupViews()
        setupConstraints()
        update(theme: theme)
    }

    @TariView public var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    @TariView public var loginView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    @TariView private var usernameLabel: UILabel = {
        let view = UILabel()
        view.font = .Poppins.SemiBold.withSize(24)
        view.textAlignment = .center
        view.numberOfLines = 1
        view.adjustsFontSizeToFitWidth = true
        return view
    }()

    @TariView private var gaugesContainerView: UIView = {
        let view = UIView()
        return view
    }()

    @TariView private var minedGaugeView: GaugeView = {
        let view = GaugeView()
        view.setIcon(image: .mined)
        return view
    }()

    @TariView private var gemsGaugeView: GaugeView = {
        let view = GaugeView()
        view.setIcon(image: .gems)
        return view
    }()

    @TariView public var inviteView: InviteView = {
        let view = InviteView()
        return view
    }()

    @TariView private var invitedLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.SemiBold.withSize(18)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        return label
    }()

    @TariView private var noInvitesImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = .turtle
        return imageView
    }()

    @TariView private var noInvitesTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.SemiBold.withSize(16)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        return label
    }()

    @TariView private var noInvitesDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(12)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    @TariView private var noInvitesView: UIView = {
        let view = UIView()
        return view
    }()

    @TariView public var loginBanner: UIImageView = {
        let view = UIImageView(image: .loginBanner)
        return view
    }()

    @TariView private var loginTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.SemiBold.withSize(24)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1

        label.text = "Log in to Tari Universe"
        return label
    }()

    @TariView private var loginDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(14)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0

        label.text = "Log in and link your Tari Airdrop account to view your mining stats and track airdrop rewards."
        return label
    }()

    @TariView private var logoutButton: StylisedButton = {
        let button = StylisedButton(withStyle: .outlinedInverted, withSize: .large)
        button.setTitle("Disconnect Airdrop Account", for: .normal)
        return button
    }()

    @TariView public var loginButton: StylisedButton = {
        let button = StylisedButton(withStyle: .primary, withSize: .large)
        button.setTitle("Connect my airdrop account", for: .normal)
        return button
    }()

    @TariView private var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    @TariView private var loadingLabel: UILabel = {
        let label = UILabel()
        label.font = .Poppins.Medium.withSize(14)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.text = "Loading your profile..."
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    func setupViews() {
        backgroundColor = .Background.secondary
        gaugesContainerView.backgroundColor = .clear

        minedGaugeView.setUnit(unit: "XTM")
        minedGaugeView.setDescription(description: "Tari Mined")
        gemsGaugeView.setDescription(description: "Gems Earned")

        noInvitesTitleLabel.text = "Miners are true friends"
        noInvitesDescriptionLabel.text = "Your friends must use download the Tari Universe desktop app with YOUR referral code AND start mining for you to earn gem rewards."
        noInvitesView.backgroundColor = .clear
    }

    func setupConstraints() {

        [containerView, loginView].forEach(addSubview)
        [minedGaugeView, gemsGaugeView].forEach(gaugesContainerView.addSubview)
        [usernameLabel, gaugesContainerView, inviteView, noInvitesView, logoutButton].forEach(containerView.addSubview)
        [loginBanner, loginTitleLabel, loginDescriptionLabel, loginButton, loadingIndicator, loadingLabel].forEach(loginView.addSubview)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            loginView.leadingAnchor.constraint(equalTo: leadingAnchor),
            loginView.trailingAnchor.constraint(equalTo: trailingAnchor),
            loginView.bottomAnchor.constraint(equalTo: bottomAnchor),
            loginView.topAnchor.constraint(equalTo: topAnchor),

            // loginBanner.topAnchor.constraint(equalTo: topAnchor, constant: 170),
            loginBanner.widthAnchor.constraint(equalToConstant: 362),
            loginBanner.heightAnchor.constraint(equalToConstant: 275),
            loginBanner.centerXAnchor.constraint(equalTo: centerXAnchor),
            loginBanner.bottomAnchor.constraint(equalTo: centerYAnchor, constant: 40),

            loginTitleLabel.topAnchor.constraint(equalTo: loginBanner.bottomAnchor, constant: 25),
            loginTitleLabel.leftAnchor.constraint(equalTo: loginBanner.leftAnchor),

            loginDescriptionLabel.topAnchor.constraint(equalTo: loginTitleLabel.bottomAnchor, constant: 30),
            loginDescriptionLabel.leftAnchor.constraint(equalTo: loginBanner.leftAnchor),
            loginDescriptionLabel.rightAnchor.constraint(equalTo: loginBanner.rightAnchor),

            loginButton.centerXAnchor.constraint(equalTo: loginView.centerXAnchor),
            loginButton.widthAnchor.constraint(equalToConstant: 362),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            loginButton.bottomAnchor.constraint(equalTo: loginView.bottomAnchor, constant: -50),

            // usernameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 124),
            usernameLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            usernameLabel.bottomAnchor.constraint(equalTo: gaugesContainerView.topAnchor, constant: -40),
            gaugesContainerView.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 21),
            gaugesContainerView.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -21),
            gaugesContainerView.widthAnchor.constraint(lessThanOrEqualToConstant: 370),
            minedGaugeView.topAnchor.constraint(equalTo: gaugesContainerView.topAnchor),
            minedGaugeView.leadingAnchor.constraint(equalTo: gaugesContainerView.leadingAnchor),
            minedGaugeView.bottomAnchor.constraint(equalTo: gaugesContainerView.bottomAnchor),
            minedGaugeView.widthAnchor.constraint(equalToConstant: 164),
            minedGaugeView.heightAnchor.constraint(equalToConstant: 120),
            gemsGaugeView.topAnchor.constraint(equalTo: gaugesContainerView.topAnchor),
            gemsGaugeView.rightAnchor.constraint(equalTo: gaugesContainerView.rightAnchor),
            gemsGaugeView.widthAnchor.constraint(equalToConstant: 164),
            gemsGaugeView.heightAnchor.constraint(equalToConstant: 120),

            gaugesContainerView.bottomAnchor.constraint(equalTo: inviteView.topAnchor, constant: -30),
            inviteView.topAnchor.constraint(equalTo: centerYAnchor, constant: -30),
            inviteView.leftAnchor.constraint(equalTo: gaugesContainerView.leftAnchor),
            inviteView.rightAnchor.constraint(equalTo: gaugesContainerView.rightAnchor),
            inviteView.heightAnchor.constraint(equalToConstant: 220),
            inviteView.widthAnchor.constraint(lessThanOrEqualToConstant: 370),

            logoutButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            logoutButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -50),
            logoutButton.widthAnchor.constraint(equalToConstant: 362),
            logoutButton.heightAnchor.constraint(equalToConstant: 50),

            loadingIndicator.centerXAnchor.constraint(equalTo: loginView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: loginView.centerYAnchor),

            loadingLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 16),
            loadingLabel.centerXAnchor.constraint(equalTo: loginView.centerXAnchor),
            loadingLabel.widthAnchor.constraint(equalToConstant: 362)
        ])
    }

    override func update(theme: AppTheme) {
        usernameLabel.textColor = .Text.primary
        invitedLabel.textColor = .Text.primary
        noInvitesTitleLabel.textColor = .Text.primary
        noInvitesDescriptionLabel.textColor = .Text.primary
        loginTitleLabel.textColor = .Text.primary
        loginDescriptionLabel.textColor = .Text.body
        loadingLabel.textColor = .Text.body
    }

    func update(profile: UserDetails) {
        usernameLabel.text = "@" + profile.displayName
        gemsGaugeView.setAmount(amount: String(profile.rank.gems))
        inviteView.linkLabel.text = "tari-universe/" + profile.referralCode
        invitedLabel.text = "Invited Friends " + "(0)"
    }

    func update(mined: String) {
        minedGaugeView.setAmount(amount: mined)
    }

    func showLoading() {
        loadingIndicator.startAnimating()
        loadingLabel.isHidden = false
        loginButton.isHidden = true
        loginTitleLabel.isHidden = true
        loginDescriptionLabel.isHidden = true
        loginBanner.isHidden = true
    }

    func hideLoading() {
        loadingIndicator.stopAnimating()
        loadingLabel.isHidden = true
        loginButton.isHidden = false
        loginTitleLabel.isHidden = false
        loginDescriptionLabel.isHidden = false
        loginBanner.isHidden = false
    }
}
