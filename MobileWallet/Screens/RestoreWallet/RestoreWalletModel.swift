//  RestoreWalletModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 02/10/2024
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

import Combine

final class RestoreWalletModel {

    enum Action {
        case showPaperWalletConfirmation
        case showPaperWalletRecoveryProgress
        case showPaperWalletPasswordForm
    }

    // MARK: - Properties

    @Published private(set) var action: Action?
    @Published private(set) var error: MessageModel?

    private let recoveryModel = SeedWordsWalletRecoveryManager()
    private var unconfirmedCipher: String?
    private var cancellable = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        recoveryModel.$isEmptyWalletCreated
            .filter { $0 }
            .sink { [weak self] _ in self?.action = .showPaperWalletRecoveryProgress }
            .store(in: &cancellable)

        recoveryModel.$error
            .assign(to: &$error)
    }

    // MARK: - Actions

    func requestWalletRecovery(paperWalletDeeplink: PaperWalletDeeplink) {
        unconfirmedCipher = paperWalletDeeplink.privateKey

        NotificationManager.shared.appId = paperWalletDeeplink.appId
        action = .showPaperWalletConfirmation
    }

    func removeWallet() {
        recoveryModel.deleteWallet(wallet: .main)
    }

    func confirmWalletRecovery() {
        action = .showPaperWalletPasswordForm
    }

    func cancelWalletRecovery() {
        unconfirmedCipher = nil
    }

    func enter(paperWalletPassword: String) {
        guard let unconfirmedCipher else { return }
        recoveryModel.recover(wallet: .main, cipher: unconfirmedCipher, passphrase: paperWalletPassword, customBaseNodeHex: nil, customBaseNodeAddress: nil)
        self.unconfirmedCipher = nil
    }
}
