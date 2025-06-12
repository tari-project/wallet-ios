//  ProfileModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 12/01/2022
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

import UIKit
import Combine
import YatLib

final class NewProfileModel {

    enum State {
        case Initial
        case Loading
        case LoggedOut
        case Profile(UserDetails)
        case Error
    }

    // MARK: - View Model
    @Published private(set) var errorMessage: MessageModel?

    @Published private(set) var state: State = .Initial

    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        setupCallbacks()
        checkUserState()
    }

    // MARK: - Setups
    private func setupCallbacks() {
        // Observe user state changes
        UserManager.shared.$user
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handleUpdate(status: status)
            }
            .store(in: &cancellables)

        // Add observer for deeplink handling failures
        NotificationCenter.default.publisher(for: .deeplinkHandlingFailed)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleError(errorMessage: "Failed to process login. Please try again.")
            }
            .store(in: &cancellables)

        // Add observer for logout
        NotificationCenter.default.publisher(for: .userDidLogout)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleLoggedOutState()
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func update(name: String?) {
        guard let name, !name.isEmpty else {
            handleError(errorMessage: MessageModel(
                title: localized("profile_view.error.no_name.title"),
                message: localized("profile_view.error.no_name.description"),
                closeButtonTitle: localized("profile_view.error.no_name.button"),
                type: .normal
            ))
            return
        }
    }

    func updateData() {
        startLoading()
        UserManager.shared.getUserInfo()
    }

    func checkUserState() {
        startLoading()
        UserManager.shared.getUserInfo()
    }

    private func handleUpdate(status: UserInfoStatus) {
        print("NewProfileModel: handleUpdate called with status: \(status)")
        switch status {
        case .Error(let message):
            print("NewProfileModel: Setting state to Error")
            state = .Error
            handleError(errorMessage: MessageModel(
                title: localized("profile_view.error.title"),
                message: message,
                closeButtonTitle: localized("common.buttons.ok"),
                type: .normal
            ))
        case .LoggedOut:
            print("NewProfileModel: Setting state to LoggedOut")
            state = .LoggedOut
        case .Ok(let userDetails):
            print("NewProfileModel: Setting state to Profile with userDetails")
            state = .Profile(userDetails)
        }
        print("NewProfileModel: State after update: \(state)")
    }

    private func startLoading() {
        state = .Loading
        errorMessage = nil
    }

    private func handleError(errorMessage: MessageModel) {
        self.errorMessage = errorMessage
        state = .Error
    }

    private func handleError(errorMessage: String) {
        handleError(errorMessage: MessageModel(
            title: localized("profile_view.error.title"),
            message: errorMessage,
            closeButtonTitle: localized("common.buttons.ok"),
            type: .normal
        ))
    }

    private func handleLoggedOutState() {
        state = .LoggedOut
        errorMessage = nil
    }

    private func handleUserDetails(userDetails: UserDetails) {
        DispatchQueue.main.async { [weak self] in
            self?.state = .Profile(userDetails)
        }
    }

    private func show(error: Error?) {
        self.errorMessage = ErrorMessageManager.errorModel(forError: error)
    }
}
