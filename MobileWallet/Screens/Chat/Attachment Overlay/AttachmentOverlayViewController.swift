//  AttachmentOverlayViewController.swift

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

import Combine

final class AttachmentOverlayViewController: SecureViewController<AttachmentOverlayView> {

    // MARK: - Properties

    var onClose: ((_ message: String?, _ isSendRequested: Bool) -> Void)?

    private let model: AttachmentOverlayModel
    private var wasSendButtonTapped: Bool = false
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(model: AttachmentOverlayModel, initialMessage: String?) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
        mainView.messageText = initialMessage
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard !wasSendButtonTapped else { return }
        onClose?(mainView.messageText, false)
    }

    // MARK: - Setups

    private func setupCallbacks() {

        model.$attachment
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(attachment: $0) }
            .store(in: &cancellables)

        mainView.onSendButtonTap = { [weak self] in
            self?.wasSendButtonTapped = true
            self?.onClose?($0, true)
            self?.dismiss(animated: true)
        }
    }

    private func handle(attachment: AttachmentOverlayModel.Attachment) {
        switch attachment {
        case let .request(value):
            mainView.update(requestedValue: value)
        case let .gif(state):
            mainView.update(gifState: state)
        }
    }
}
