//  ChatCallbackManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 27/09/2023
	Using Swift 5.0
	Running on macOS 13.5

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

final class ChatCallbackManager {

    var contactStatusChange: AnyPublisher<Notification, Never> {
        NotificationCenter.default
            .publisher(for: .contactStatusChange)
            .share()
            .eraseToAnyPublisher()
    }

    var messageReceived: AnyPublisher<ChatMessage, Never> {
        NotificationCenter.default
            .publisher(for: .messageReceived)
            .compactMap { $0.object as? ChatMessage }
            .share()
            .eraseToAnyPublisher()
    }

    // MARK: - Properties

    static let shared = ChatCallbackManager()
    private let queue = DispatchQueue(label: "com.tari.events.chat", attributes: [])

    // MARK: - Initialisers

    private init() {}

    // MARK: - Actions

    func post(name: Notification.Name, object: Any?) {
        queue.async {
            NotificationCenter.default.post(name: name, object: object)
        }
    }
}

extension Notification.Name {
    static let contactStatusChange = Self(rawValue: "com.tari.wallet.chat.contact_status_change")
    static let messageReceived = Self(rawValue: "com.tari.wallet.chat.message_received")
}
