//  ContactTransactionListViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 18/04/2023
	Using Swift 5.0
	Running on macOS 13.0

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

final class ContactTransactionListViewController: UIViewController {

    // MARK: - Properties

    private let model: ContactTransactionListModel
    private let mainView = ContactTransactionListView()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(model: ContactTransactionListModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
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
    }

    // MARK: - Setups

    private func setupCallbacks() {

        model.$name
            .sink { [weak self] in self?.mainView.name = $0 }
            .store(in: &cancellables)

        model.$viewModels
            .sink { [weak self] in self?.mainView.update(models: $0) }
            .store(in: &cancellables)

        model.$action
            .compactMap { $0 }
            .sink { [weak self] in self?.handle(action: $0) }
            .store(in: &cancellables)

        mainView.onSelectRow = { [weak self] in
            self?.model.select(index: $0.row)
        }

        mainView.onSendButtonTap = { [weak self] in
            self?.model.transactionSendRequest()
        }
    }

    // MARK: - Actions

    private func moveToTransactionDetails(transaction: Transaction) {
        let controller = TransactionDetailsConstructor.buildScene(transaction: transaction)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func moveToTransactionSendScene(paymentInfo: PaymentInfo) {
        AppRouter.presentSendTransaction(paymentInfo: paymentInfo)
    }

    // MARK: - Handlers

    private func handle(action: ContactTransactionListModel.Action) {
        switch action {
        case let .moveToTransaction(transaction):
            moveToTransactionDetails(transaction: transaction)
        case let .moveToTransactionSend(paymentInfo):
            moveToTransactionSendScene(paymentInfo: paymentInfo)
        }
    }
}
