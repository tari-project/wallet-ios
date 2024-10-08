//  AddressViewDefaultActions.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 10/07/2024
	Using Swift 5.0
	Running on macOS 14.4

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

enum AddressViewDefaultActions {

    static func showDetailsAction(addressComponents: TariAddressComponents) -> () -> Void {
        {
            Task {
                await showDetailsPopup(
                    viewModel: PopUpAddressDetailsContentView.ViewModel(
                        network: addressComponents.network,
                        networkDescription: addressComponents.networkName,
                        features: addressComponents.features,
                        featuresDescription: addressComponents.featuresNames,
                        viewKey: addressComponents.viewKey,
                        coreAddress: addressComponents.spendKey,
                        checksum: addressComponents.checksum
                    ),
                    rawAddress: addressComponents.fullRaw,
                    emojiAddress: addressComponents.fullEmoji
                )
            }
        }
    }

    @MainActor private static func showDetailsPopup(viewModel: PopUpAddressDetailsContentView.ViewModel, rawAddress: String, emojiAddress: String) async {

        let headerSection = PopUpHeaderView()
        headerSection.label.text = localized("address_view.details.label.title")

        let contentSection = PopUpAddressDetailsContentView()
        contentSection.update(viewModel: viewModel)
        contentSection.onCopyRawAddressButtonTap = { handleCopyAction(address: rawAddress) }
        contentSection.onCopyEmojiAddressButtonTap = { handleCopyAction(address: emojiAddress) }

        let buttonsSection = PopUpButtonsView()
        buttonsSection.addButton(model: PopUpDialogButtonModel(title: localized("common.close"), type: .text, callback: { PopUpPresenter.dismissPopup() }))

        let popUp = TariPopUp(headerSection: headerSection, contentSection: contentSection, buttonsSection: buttonsSection)
        PopUpPresenter.show(popUp: popUp)
    }

    private static func handleCopyAction(address: String) {
        UIPasteboard.general.string = address
        PopUpPresenter.dismissPopup()
    }
}
