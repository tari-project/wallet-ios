//  MigrationManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 16/11/2022
	Using Swift 5.0
	Running on macOS 12.6

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

enum MigrationManager {

    // MARK: - Properties

    private static let minValidVersion = "1.4.1-rc.0"

    // MARK: - Actions

    static func validateWalletVersion(completion: @escaping (Bool) -> Void) {

        Task {

            guard await !isWalletHasValidVersion() else {
                completion(true)
                return
            }

            DispatchQueue.main.async {
                showPopUp { completion($0) }
            }
        }
    }

    private static func isWalletHasValidVersion(retryCount: Int = 0) async -> Bool {

        let version = await fetchDBVersion()

        if let version {
            let isValid = VersionValidator.compare(version, isHigherOrEqualTo: minValidVersion)
            Logger.log(message: "Min. Valid Wallet Version: \(minValidVersion), Local Wallet Version: \(version), isValid: \(isValid)", domain: .general, level: .info)
            return isValid
        } else {
            Logger.log(message: "Unable to get wallet version", domain: .general, level: .info)
            return false
        }
    }

    private static func fetchDBVersion(retryCount: Int = 0) async -> String? {

        let maxRetryCount = 5

        do {
            return try Tari.shared.walletVersion()
        } catch {
            guard retryCount < maxRetryCount else { return nil }
            Logger.log(message: "Waiting for cookies: Retry Count: \(retryCount)", domain: .general, level: .info)
            try? await Task.sleep(seconds: 1)
            return await fetchDBVersion(retryCount: retryCount + 1)
        }
    }

    @MainActor private static func showPopUp(completion: @escaping (Bool) -> Void) {

        let headerSection = PopUpComponentsFactory.makeHeaderView(title: localized("ffi_validation.error.title"))
        let contentSection = PopUpComponentsFactory.makeContentView(message: localized("ffi_validation.error.message"))
        let buttonsSection = PopUpComponentsFactory.makeButtonsView(models: [
            PopUpDialogButtonModel(title: localized("ffi_validation.error.button.delete"), type: .destructive, callback: { completion(false) }),
            PopUpDialogButtonModel(title: localized("ffi_validation.error.button.cancel"), type: .text, callback: { completion(true) })
        ])

        let popUp = TariPopUp(headerSection: headerSection, contentSection: contentSection, buttonsSection: buttonsSection)
        PopUpPresenter.show(popUp: popUp)
    }
}
