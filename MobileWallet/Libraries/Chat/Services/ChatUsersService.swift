//  ChatUsersService.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 18/12/2023
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

import Combine

final class ChatUsersService: CoreChatService {

    // MARK: - Properties

    @Published private(set) var onlineStatuses: [String: ChatOnlineStatus] = [:]
    @Published private(set) var error: Error?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    override init(chatManager: ChatManager) {
        super.init(chatManager: chatManager)
        setupCallbacks()
        fetchData()
    }

    // MARK: - Setups

    private func setupCallbacks() {
        ChatCallbackManager.shared.contactStatusChange
            .sink { [weak self] in self?.handle(livenessData: $0) }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    private func fetchData() {
        do {
            onlineStatuses = try chatManager.conversationalists().all
                .reduce(into: [String: ChatOnlineStatus]()) { result, address in
                    let hex = try address.byteVector.hex
                    let onlineStatus = try chatManager.onlineStatus(address: address)
                    result[hex] = onlineStatus
                }
        } catch {
            self.error = error
        }
    }

    // MARK: - Handlers

    private func handle(livenessData: ContactsLivenessData) {
        guard let hex = try? livenessData.address.byteVector.hex, let onlineStatus = try? livenessData.onlineStatus else { return }
        onlineStatuses[hex] = onlineStatus
    }
}
