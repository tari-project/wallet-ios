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

    // MARK: - Setups

    private func setupCallbacks() {

//        model.$name
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] in self?.mainView.update(username: $0) }
//            .store(in: &cancellables)
//

        model.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.show(error: $0) }
            .store(in: &cancellables)

        model.$state
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handleState(state: $0) }
            .store(in: &cancellables)

        model.$profile
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handleProfile(profile: $0) }
            .store(in: &cancellables)

        mainView.inviteView.onShareButtonTap = { [weak self] in
            self?.shareAction(refId: self?.model.profile?.referralCode)
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

    private func handleState(state: NewProfileModel.State) {
        switch state {
        case .LoggedOut:
            showLogin()
        case .Error:
            break
        case .Initial:
            break
        case .Loading:
            break
        case .Profile:
            break
        }
    }

    private func handleProfile(profile: UserDetails) {
        mainView.update(profile: profile)
    }

    // MARK: - Actions
    private func show(error: MessageModel) {
        PopUpPresenter.show(message: error)
    }

    private func showLogin() {
        if let url = URL(string: "https://airdrop.tari.com/auth?mobileNetwork=nextnet") {
            UIApplication.shared.open(url)
        }
    }
}
