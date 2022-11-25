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
    
    enum MigrationError: Error {
        case noCurrentWalletVersion
    }
    
    // MARK: - Properties
    
    private static let minValidVersion = "0.41.0"
    
    private static var currentWalletVersion: String {
        
        get throws {
            guard
                let path = Bundle.main.path(forResource: "Constants", ofType: "plist"),
                let data = FileManager.default.contents(atPath: path),
                let dictionary = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
                let value = dictionary["FFI Version"]
            else {
                throw MigrationError.noCurrentWalletVersion
            }
            return value
        }
    }
    
    // MARK: - Actions
    
    static func validateWalletVersion(completion: @escaping (Bool) -> Void) {
        
        guard !isWalletHasValidVersion() else {
            completion(true)
            return
        }
        
        DispatchQueue.main.async {
            showPopUp { completion($0) }
        }
    }
    
    static func updateWalletVersion() throws {
        try Tari.shared.keyValues.set(key: .version, value: currentWalletVersion)
    }
    
    private static func isWalletHasValidVersion() -> Bool {
        
        let walletVersion: String
        
        do {
            walletVersion = try Tari.shared.keyValues.value(key: .version)
        } catch {
            return false
        }
        
        return VersionValidator.compare(walletVersion, isHigherOrEqualTo: minValidVersion)
    }
    
    private static func showPopUp(completion: @escaping (Bool) -> Void) {
        
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
