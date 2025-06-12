//  AddressPoisoningDataHandler.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 18/01/2024
	Using Swift 5.0
	Running on macOS 14.2

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

enum AddressPoisoningDataHandler {

    // MARK: - Actions

    static func handleAddressSelection(paymentInfo: PaymentInfo, onContinue: ((PaymentInfo) -> Void)?) {

        let addressComponents = paymentInfo.addressComponents

        guard !isAddressTrusted(addressIdentifier: addressComponents.uniqueIdentifier) else {
            onContinue?(paymentInfo)
            return
        }

        Task { @MainActor in
            do {
                let address = try TariAddress(base58: addressComponents.fullRaw)
                let similarAddresses = try await AddressPoisoningManager.shared.similarAddresses(address: address, includeInputAddress: true)
                    .map { similarAddress in
                        return PopUpAddressPoisoningContentCell.ViewModel(
                            id: UUID(),
                            emojiID: similarAddress.emojiID,
                            name: similarAddress.alias,
                            transactionsCount: similarAddress.transactionsCount,
                            lastTransaction: similarAddress.lastTransaction,
                            isTrusted: isAddressTrusted(addressIdentifier: similarAddress.address)
                        )
                    }

                if similarAddresses.count > 1 {
                    showAddressPoisoningDialog(options: similarAddresses, originalPaymentInfo: paymentInfo, onContinue: onContinue)
                } else {
                    onContinue?(paymentInfo)
                }
            } catch {
                showErrorPopUp(error: error)
            }
        }
    }

    private static func confirmAddressSelection(emojiID: String, originalPaymentInfo: PaymentInfo, isTrusted: Bool, onContinue: ((PaymentInfo) -> Void)?) {
        do {
            let addressComponents = try TariAddress(emojiID: emojiID).components
            updateSettings(uniqueIdentifier: addressComponents.uniqueIdentifier, isTrusted: isTrusted)

            if addressComponents == originalPaymentInfo.addressComponents {
                onContinue?(originalPaymentInfo)
            } else {
                onContinue?(PaymentInfo(addressComponents: addressComponents, alias: nil, yatID: nil, amount: nil, feePerGram: nil, note: nil))
            }
        } catch {
            showErrorPopUp(error: error)
        }
    }

    // MARK: - PopUps

    private static func showAddressPoisoningDialog(options: [PopUpAddressPoisoningContentCell.ViewModel], originalPaymentInfo: PaymentInfo, onContinue: ((PaymentInfo) -> Void)?) {
        Task { @MainActor in
            PopUpPresenter.showAddressPoisoningPopUp(options: options) {
                confirmAddressSelection(emojiID: $0.emojiID, originalPaymentInfo: originalPaymentInfo, isTrusted: $1, onContinue: onContinue)
            }
        }
    }

    private static func showErrorPopUp(error: Error) {
        let message = ErrorMessageManager.errorModel(forError: error)
        Task { @MainActor in
            PopUpPresenter.show(message: message)
        }
    }

    // MARK: - Helpers

    private static func updateSettings(uniqueIdentifier: String, isTrusted: Bool) {

        if GroupUserDefaults.trustedAddresses == nil {
            GroupUserDefaults.trustedAddresses = Set<String>()
        }

        guard isTrusted else {
            GroupUserDefaults.trustedAddresses?.remove(uniqueIdentifier)
            return
        }

        GroupUserDefaults.trustedAddresses?.insert(uniqueIdentifier)
    }

    private static func isAddressTrusted(addressIdentifier: String) -> Bool {
        GroupUserDefaults.trustedAddresses?.contains { $0 == addressIdentifier } ?? false
    }
}
