//  AttachmentOverlayModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 15/05/2024
	Using Swift 5.0
	Running on macOS 14.4

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

final class AttachmentOverlayModel {

    struct CallbackData {
        let message: String?
        let isReplyAttached: Bool
        let isSendConfirned: Bool
    }

    enum Payload {
        case request(value: String)
        case gif(identifier: String)
    }

    enum Attachment {
        case request(value: NSAttributedString)
        case gif(gifID: String)
    }

    // MARK: - View Model

    @Published private(set) var attachment: Attachment?
    @Published private(set) var replyViewModel: ChatReplyViewModel?
    @Published private(set) var updateOutputDataAction: CallbackData?
    @Published private(set) var shouldCloseAction: Bool = false

    // MARK: - Properties

    private var message: String?
    private var isSendConfirned: Bool = false

    // MARK: - Initialisers

    init(payload: Payload, replyViewModel: ChatReplyViewModel?) {
        self.replyViewModel = replyViewModel
        handle(payload: payload)
    }

    // MARK: - Actions

    func update(message: String?) {
        self.message = message
    }

    func detachReplyMessage() {
        replyViewModel = nil
    }

    func sendMessage() {
        isSendConfirned = true
        updateOutputData()
        shouldCloseAction = true
    }

    func updateOutputData() {
        updateOutputDataAction = CallbackData(message: message, isReplyAttached: replyViewModel != nil, isSendConfirned: isSendConfirned)
    }

    // MARK: - Handlers

    private func handle(payload: Payload) {
        switch payload {
        case let .request(value):
            attachment = .request(value: NSAttributedString(amount: value))
        case let .gif(identifier):
            attachment = .gif(gifID: identifier)
        }
    }
}
