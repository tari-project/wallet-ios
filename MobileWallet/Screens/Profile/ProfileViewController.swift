//  ProfileViewController.swift

/*
	Package MobileWallet
	Created by Gabriel Lupu on 04/02/2020
	Using Swift 5.0
	Running on macOS 10.15

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

import UIKit
import Combine
import YatLib
import WebKit

final class ProfileViewController: SecureViewController<NewProfileView>, WKNavigationDelegate {

    // MARK: - Properties
    var webView: WKWebView?

    private let model = NewProfileModel()
    private var cancellables = Set<AnyCancellable>()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        model.checkUserState()
    }

    // MARK: - Setups

    func updateData() {
        model.updateData()
    }

    private func setupCallbacks() {
        // Keep strong reference to self in subscription
        model.$state
            .receive(on: DispatchQueue.main)
            .sink { [self] state in
                self.handleState(state: state)
            }
            .store(in: &cancellables)

        Tari.shared.wallet(.main).walletBalance.$balance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.update(mined: MicroTari($0.total).formatted) }
            .store(in: &cancellables)

        mainView.inviteView.onShareButtonTap = { [weak self] in
            if case .Profile(let userDetails) = self?.model.state {
                self?.shareAction(refId: userDetails.referralCode)
            }
        }

        mainView.onLoginButtonTap = { [weak self] in
            if let url = URL(string: "https://airdrop.tari.com/auth?mobile=nextnet") {
                UIApplication.shared.open(url)
            }
        }

        mainView.onLogoutButtonTap = { [weak self] in
            self?.logout()
        }
    }

    private func shareAction(refId: String?) {
        guard let refererCode = refId else {
            return
        }

        let url = URL(string: "https://airdrop.tari.com/?referralCode="+refererCode)!

        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view

        activityVC.excludedActivityTypes = [.assignToContact, .addToReadingList]

        present(activityVC, animated: true, completion: nil)
    }

    private func logout() {
        // Clear tokens
        UserManager.shared.clearTokens()
        handleState(state: .LoggedOut)
    }

    func handleState(state: NewProfileModel.State) {
        print("Handling state in ProfileViewController: \(state)")
        switch state {
        case .LoggedOut:
            mainView.containerView.isHidden = true
            mainView.loginView.isHidden = false
            mainView.hideLoading()
        case .Error:
            mainView.containerView.isHidden = true
            mainView.loginView.isHidden = false
            mainView.hideLoading()
        case .Initial:
            mainView.containerView.isHidden = true
            mainView.loginView.isHidden = true
            mainView.hideLoading()
        case .Loading:
            mainView.containerView.isHidden = true
            mainView.loginView.isHidden = false
            mainView.showLoading()
        case .Profile(let userDetails):
            mainView.containerView.isHidden = false
            mainView.loginView.isHidden = true
            mainView.hideLoading()
            mainView.update(profile: userDetails)
        }
    }
}
