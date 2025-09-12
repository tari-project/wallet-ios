//  Send+Actions.swift
	
/*
	Package MobileWallet
	Created by Tomas Hakel on 25.08.2025
	Using Swift 6.0
	Running on macOS 15.5

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

import SwiftUI

extension Send {
    var isContinueEnabled: Bool {
        isAddressValid && amountError == nil && !amount.isEmpty
    }
    
    var isAddressValid: Bool {
        contact != nil || (try? TariAddress(base58: address)) != nil
    }
    
    func update(walletBalance: WalletBalance) {
        availableBalance = MicroTari(walletBalance.available)
    }
    
    func scanQR() {
        hideKeyboard()
        AppRouter.presentQrCodeScanner(expectedDataTypes: [.base64Address, .deeplink(.transactionSend), .deeplink(.profile)], disabledDataTypes: []) { qrData in
            switch qrData {
            case let .base64Address(encodedAddress):
                decodeAddress(base58: encodedAddress)
            case let .deeplink(link):
                if let link = link as? TransactionsSendDeeplink {
                    decodeAddress(base58: link.receiverAddress)
                    if let linkAmount = link.amount {
                        amount = "\(linkAmount)"
                    }
                } else if let link = link as? UserProfileDeeplink {
                    decodeAddress(base58: link.tariAddress)
                }
            default: ()
            }
        }
    }
    
    func selectContact() {
        hideKeyboard()
        isSelectingContact = true
    }
    
    func updateAmount() {
        withAnimation {
            do {
                if amount.isEmpty {
                    fee = nil
                    amountError = nil
                } else {
                    let microTariAmount = try MicroTari(tariValue: amount)
                    if let availableBalance, microTariAmount < availableBalance {
                        feeManager.amount = microTariAmount
                        if let feeData = feeManager.feeData {
                            feePerGram = feeData.feePerGram
                            fee = feeData.fee
                            amountError = nil
                        } else {
                            amountError = "Failed to load transaction fee"
                        }
                    } else {
                        amountError = "Amount must be less than Available amount"
                    }
                }
            } catch {
                amountError = "Error parsing amount"
            }
        }
    }
    
    func updateAddress() {
        if contact?.name != address {
            contact = nil
        }
        withAnimation {
            addressError = !address.isEmpty && !isAddressValid  ? "Invalid address" : nil
        }
    }
    
    func confirmSend() {
        hideKeyboard()
        do {
            presentedConfirmation = try SendConfirmation(
                amount: MicroTari(tariValue: amount),
                fee: fee ?? .zero,
                feePerGram: feePerGram ?? .zero,
                address: contact?.address ?? TariAddress(base58: address).components,
                note: note.isEmpty ? nil : note,
                contact: contact
            )
        } catch {
            PopUpPresenter.show(message: MessageModel(
                title: localized("sending_tari.error.no_connection.title"),
                message: localized("sending_tari.error.no_connection.description"),
                type: .error
            ))
        }
    }

    func hideKeyboard() {
        UIApplication.shared.hideKeyboard()
    }
}

private extension Send {
    func decodeAddress(base58 encodedAddress: String) {
        guard let addressComponents = try? TariAddress(base58: encodedAddress).components else { return }
        address = addressComponents.fullRaw
    }
}
