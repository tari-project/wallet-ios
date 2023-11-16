//  ErrorMessageManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 31/01/2022
	Using Swift 5.0
	Running on macOS 12.1

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

enum ErrorMessageManager {

    // MARK: - Properties

    private static var genericErrorModel: MessageModel { MessageModel(title: localized("error.generic.title"), message: localized("error.generic.description"), type: .error) }

    // MARK: - Actions

    static func errorModel(forError error: Error?) -> MessageModel {

        guard let error = error else { return genericErrorModel }

        switch error {
        case let error as WalletError:
            return model(walletError: error)
        case let error as FFIWalletManager.GeneralError:
            return model(internalWalletError: error)
        case let error as SeedWords.InternalError:
            return model(seedWordsError: error)
        default:
            return genericErrorModel
        }
    }

    static func errorMessage(forError error: Error?) -> String? { errorModel(forError: error).message }

    // MARK: - Helpers

    private static func model(walletError: WalletError) -> MessageModel {

        let translationKey = "error.wallet.\(walletError.code)"
        var message: String? = localized(translationKey)

        if message == translationKey {
            message = genericErrorModel.message
        }

        return MessageModel(title: genericErrorModel.title, message: message?.appending(signature: walletError.signature), type: .error)
    }

    private static func model(seedWordsError: SeedWords.InternalError) -> MessageModel {

        let message: String

        switch seedWordsError {
        case .invalidSeedPhrase, .invalidSeedWord:
            message = localized("restore_from_seed_words.error.description.invalid_seed_word")
        case .phraseIsTooShort:
            message = localized("restore_from_seed_words.error.description.phrase_too_short")
        case .phraseIsTooLong:
            message = localized("restore_from_seed_words.error.description.phrase_too_long")
        case .unexpectedResult:
            message = localized("restore_from_seed_words.error.description.unknown_error")
        }

        return MessageModel(title: localized("restore_from_seed_words.error.title"), message: message.appending(signature: seedWordsError.signature), type: .error)
    }

    private static func model(internalWalletError: FFIWalletManager.GeneralError) -> MessageModel {

        let message: String

        switch internalWalletError {
        case .unableToCreateWallet:
            message = localized("wallet.error.wallet_not_initialized")
        }

        return MessageModel(title: genericErrorModel.title, message: message, type: .error)
    }
}

private extension String {
    func appending(signature: String) -> String { self + "\n" + localized("error.code.prefix") + " " + signature }
}
