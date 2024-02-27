//  TransactionsViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 21/07/2023
	Using Swift 5.0
	Running on macOS 13.4

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

final class TransactionsViewController: SecureViewController<TransactionsView> {

    fileprivate enum Page: Int {
        case send
        case request
    }

    // MARK: - Properties

    private let pagerViewController = TariPagerViewController()
    private let addRecipientViewController = AddRecipientConstructor.buildScene()
    private let requestTariAmountViewController = RequestTariAmountViewController()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupViews() {

        pagerViewController.pages = [
            TariPagerViewController.Page(title: Page.send.pageTabTitle, controller: addRecipientViewController),
            TariPagerViewController.Page(title: Page.request.pageTabTitle, controller: requestTariAmountViewController)
        ]

        mainView.setup(pagerView: pagerViewController.view)
    }

    private func setupCallbacks() {

        addRecipientViewController.onContactSelected = { [weak self] in
            self?.moveToAddAmount(paymentInfo: $0)
        }

        pagerViewController.pageIndex
            .sink { [weak self] in self?.updateTitle(index: $0) }
            .store(in: &cancellables)
    }

    // MARK: - Updates

    private func updateTitle(index: Int) {
        mainView.navigationBar.title = Page(rawValue: index)?.navBarTitle
    }

    // MARK: - Actions

    private func moveToAddAmount(paymentInfo: PaymentInfo) {
        let controller = AddAmountViewController(paymentInfo: paymentInfo)
        navigationController?.pushViewController(controller, animated: true)
    }
}

private extension TransactionsViewController.Page {

    var navBarTitle: String {
        switch self {
        case .send:
            return localized("send.nav_bar.add_recipient.title")
        case .request:
            return localized("send.nav_bar.request.title")
        }
    }

    var pageTabTitle: String {
        switch self {
        case .send:
            return localized("send.page_tab.add_recipient.title")
        case .request:
            return localized("send.page_tab.request.title")
        }
    }
}
