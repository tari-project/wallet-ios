//  ConfirmationViewController.swift

/*
	Package MobileWallet
	Created by Konrad Faltyn on 09/04/2025
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

import Foundation
import TariCommon

class ConfirmationViewController: SecureViewController<ConfirmationView> {

    private let navigationBar = NavigationBar()
    @View private var addressView = AddressView()

    private let paymentInfo: PaymentInfo

    init(paymentInfo: PaymentInfo) {
        self.paymentInfo = paymentInfo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        displayAliasOrEmojiId()
        update()
    }

    private func displayAliasOrEmojiId() {
        do {
            guard let alias = try paymentInfo.alias ?? Tari.shared.wallet(.main).contacts.findContact(uniqueIdentifier: paymentInfo.addressComponents.uniqueIdentifier)?.alias else {
                let addressComponents = paymentInfo.addressComponents

                let viewModel =  AddressView.ViewModel(prefix: addressComponents.networkAndFeatures,
                                                       text: .truncated(prefix: addressComponents.coreAddressPrefix,
                                                                        suffix: addressComponents.coreAddressSuffix),
                                                       isDetailsButtonVisible: false)
                addressView.update(viewModel: viewModel)
                return
            }
            addressView.update(viewModel: AddressView.ViewModel(prefix: nil, text: .single(alias), isDetailsButtonVisible: false))
        } catch {
            PopUpPresenter.show(message: MessageModel(title: localized("navigation_bar.error.show_emoji.title"), message: localized("navigation_bar.error.show_emoji.description"), type: .error))
        }
    }

    private func setup() {
        mainView.onCopyButonTap = { value in
            UIPasteboard.general.string = value
        }

        mainView.onSendButonTap = {
            self.continueButtonTapped()
        }

        mainView.onCancelButonTap = {
            self.dismiss(animated: true, completion: nil)
        }

        navigationBar.isSeparatorVisible = false
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(navigationBar)
        navigationBar.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        navigationBar.addSubview(addressView)

        addressView.centerXAnchor.constraint(equalTo: navigationBar.contentView.centerXAnchor).isActive = true
        addressView.centerYAnchor.constraint(equalTo: navigationBar.contentView.centerYAnchor).isActive = true
    }

    private func update() {
        if let amount = paymentInfo.amount {
            mainView.amountText = amount.formattedPrecise + " " + "tXTM"

            var fee: UInt64 = 0
            do {
                fee = try Tari.shared.wallet(.main).fees.estimateFee(amount: amount.rawValue)
            } catch {

            }
            let tariFeeAmount = MicroTari(fee)
            let feeAmount = tariFeeAmount.formattedPrecise
            mainView.feeText = feeAmount + " " + "tXTM"

            let totalAmount = MicroTari(amount.rawValue + fee)
            mainView.totalAmountText = totalAmount.formattedPrecise + " " + "tXTM"
        } else {
            mainView.feeText = "0" + " " + "tXTM"
            mainView.totalAmountText = "0" + " " + "tXTM"
        }

        let addressComponents = paymentInfo.addressComponents
        mainView.addressText = addressComponents.fullRaw.shortenedMiddle(to: 20)

        mainView.noteText = paymentInfo.note
    }

    @objc private func continueButtonTapped() {
        TransactionProgressPresenter.showTransactionProgress(presenter: self, paymentInfo: paymentInfo, isOneSidedPayment: true)
    }
}
