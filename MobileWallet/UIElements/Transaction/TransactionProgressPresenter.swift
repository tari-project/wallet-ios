//  TransactionProgressPresenter.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 25/03/2022
	Using Swift 5.0
	Running on macOS 12.3

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

enum TransactionProgressPresenter {

    @MainActor static func showTransactionProgress(presenter: UIViewController, paymentInfo: PaymentInfo, isOneSidedPayment: Bool) {

        guard let amount = paymentInfo.amount, let feePerGram = paymentInfo.feePerGram else {
            show(transactionError: .missingInputData)
            return
        }

        let message = paymentInfo.note ?? ""

        let controller: TransactionViewControllable

        if let yatID = paymentInfo.yatID {
            // FIXME: Yat features doesn't support base58 and TariAddressComponent yet.
            let inputData = YatTransactionModel.InputData(address: paymentInfo.addressComponents.fullRaw, amount: amount, feePerGram: feePerGram, message: message, yatID: yatID, isOneSidedPayment: isOneSidedPayment)
            controller = YatTransactionConstructor.buildScene(inputData: inputData)
            presenter.present(controller, animated: false)
        } else {
            let inputData = SendingTariModel.InputData(address: paymentInfo.addressComponents.fullRaw, amount: amount, feePerGram: feePerGram, message: message, isOneSidedPayment: isOneSidedPayment)
            controller = SendingTariConstructor.buildScene(inputData: inputData)
            presenter.navigationController?.pushViewController(controller, animated: false)
        }

        controller.onCompletion = { [weak presenter] error in
            presenter?.navigationController?.dismiss(animated: true) {
                UIApplication.shared.menuTabBarController?.setTab(.home)
                guard let error = error else { return }
                show(transactionError: error)
            }
        }
    }

    @MainActor private static func show(transactionError: WalletTransactionsManager.TransactionError) {
        switch transactionError {
        case .noInternetConnection:
            PopUpPresenter.show(message: MessageModel(title: localized("sending_tari.error.interwebs_connection.title"), message: localized("sending_tari.error.interwebs_connection.description"), type: .error))
        case .timeout, .transactionError, .unsucessfulTransaction, .missingInputData:
            PopUpPresenter.show(message: MessageModel(title: localized("sending_tari.error.no_connection.title"), message: localized("sending_tari.error.no_connection.description"), type: .error))
        }
    }
}
