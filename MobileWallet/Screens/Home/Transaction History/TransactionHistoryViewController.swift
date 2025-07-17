//  TransactionHistoryViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 05/07/2023
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

final class TransactionHistoryViewController: SecureViewController<TransactionHistoryView> {

    // MARK: - Properties

    private let model: TransactionHistoryModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(model: TransactionHistoryModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.updateData()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        model.$transactions
            .compactMap { [weak self] in self?.map(transactionsSection: $0) }
            .sink { [weak self] in self?.mainView.update(transactions: $0) }
            .store(in: &cancellables)

        model.$selectedTransaction
            .compactMap { $0 }
            .sink { [weak self] in self?.moveToTransactionDetails(transaction: $0) }
            .store(in: &cancellables)

        mainView.searchText
            .sink { [weak self] in self?.model.searchText = $0 }
            .store(in: &cancellables)

        mainView.onCellTap = { [weak self] in
            self?.model.select(transactionID: $0)
        }
    }

    private func map(transactionsSection: [TransactionHistoryModel.TransactionsSection]) -> [TransactionHistoryView.ViewModel] {
        transactionsSection.map {
            TransactionHistoryView.ViewModel(
                sectionTitle: $0.title,
                items: $0.transactions.map {
                    TransactionHistoryCell.ViewModel(
                        id: $0.id,
                        title: $0.titleComponents,
                        timestamp: $0.timestamp,
                        info: $0.status,
                        note: $0.note,
                        giphyID: nil,
                        amount: $0.amount
                    )
                }
            )

        }
    }

    // MARK: - Actions

    private func moveToTransactionDetails(transaction: Transaction) {
        let controller = TransactionDetailsConstructor.buildScene(transaction: transaction)
        navigationController?.pushViewController(controller, animated: true)
    }
}
