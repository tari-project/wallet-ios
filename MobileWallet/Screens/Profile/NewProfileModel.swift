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
        case Profile
        case Error
    }

    // MARK: - View Model
    @Published private(set) var errorMessage: MessageModel?

    @Published private(set) var state: State = .Initial
    @Published private(set) var profile: UserDetails?

    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        updateData()
        setupCallbacks()
    }

    // MARK: - Setups
    private func setupCallbacks() {

        UserManager.shared.$user
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handleUpdate(status: $0)}
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func update(name: String?) {
        guard let name, !name.isEmpty else {
            errorMessage = MessageModel(
                title: localized("profile_view.error.no_name.title"),
                message: localized("profile_view.error.no_name.description"),
                closeButtonTitle: localized("profile_view.error.no_name.button"),
                type: .normal
            )
            return
        }
    }

    func updateData() {
        UserManager.shared.getUserInfo()
    }

    private func handleUpdate(status: UserInfoStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch status {
            case .Error(let errorMessage):
                self.state = .Error
                self.profile = nil
                self.errorMessage = MessageModel(
                    title: localized("profile_view.error.title"),
                    message: errorMessage,
                    type: .error
                )
            case .LoggedOut:
                self.state = .LoggedOut
                self.profile = nil
            case .Ok(let userDetails):
                self.state = .Profile
                self.profile = userDetails
            }
        }
    }

    func startLoading() {
        state = .Loading
    }

    private func handleError(errorMessage: String) {
        DispatchQueue.main.async { [weak self] in
            self?.state = .Error
            self?.profile = nil
        }
    }

    private func handleLoggedOutState() {
        DispatchQueue.main.async { [weak self] in
            self?.state = .LoggedOut
            self?.profile = nil
        }
    }

    private func handleUserDetails(userDetails: UserDetails) {
        DispatchQueue.main.async { [weak self] in
            self?.state = .Profile
            self?.profile = userDetails
        }
    }

    private func show(error: Error?) {
        self.errorMessage = ErrorMessageManager.errorModel(forError: error)
    }
}
