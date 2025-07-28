//  SeedWordsWalletRecoveryManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 03/10/2024
	Using Swift 5.0
	Running on macOS 14.6

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
import Combine

final class SeedWordsWalletRecoveryManager {
    @Published private(set) var isEmptyWalletCreated: Bool = false
    @Published private(set) var error: MessageModel?

    func recover(wallet: WalletTag, cipher: String, passphrase: String) {
        do {
            let seedWords = try SeedWords(cipher: cipher, passphrase: passphrase).all
            recover(wallet: wallet, seedWords: seedWords)
        } catch let error as WalletError {
            handle(walletError: error)
        } catch {
            handleUnknownError()
        }
    }

    func recover(wallet: WalletTag, seedWords: [String]) {
        deleteWallet(wallet: wallet)

        // Set flag to show welcome overlay for recovered wallet
        UserDefaults.standard.set(true, forKey: "ShouldShowWelcomeOverlay")

        do {
            try Tari.shared.restore(wallet: wallet, seedWords: seedWords)
            isEmptyWalletCreated = true
        } catch let error as SeedWords.InternalError {
            handle(seedWordsError: error)
        } catch let error as WalletError {
            handle(walletError: error)
        } catch {
            handleUnknownError()
        }
    }

    func deleteWallet(wallet: WalletTag) {
        Tari.shared.delete(wallet: wallet)
        Tari.shared.canAutomaticalyReconnectWallet = false

        // Set flag to true so welcome screen shows when a new wallet is created after deletion
        UserDefaults.standard.set(true, forKey: "ShouldShowWelcomeOverlay")
    }

    private func handle(seedWordsError: SeedWords.InternalError) {
        error = ErrorMessageManager.errorModel(forError: seedWordsError)
    }

    private func handle(walletError: WalletError) {
        let message = ErrorMessageManager.errorMessage(forError: walletError)
        error = MessageModel(title: localized("restore_from_seed_words.error.title"), message: message, type: .error)
    }

    private func handleUnknownError() {
        error = MessageModel(title: localized("restore_from_seed_words.error.title"), message: localized("restore_from_seed_words.error.description.unknown_error"), type: .error)
    }
}
