//  ChatRequestTokensViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 28/03/2024
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

final class ChatRequestTokensViewController: SecureViewController<ChatRequestTokensView> {

    // MARK: - Properties

    var onSelection: ((Double) -> Void)?

    private let model: ChatRequestTokensModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(model: ChatRequestTokensModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        model.$amount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.amount = $0 }
            .store(in: &cancellables)

        model.$isValidAmount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.isContinueButtonEnabled = $0 }
            .store(in: &cancellables)

        model.$action
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(action: $0) }
            .store(in: &cancellables)

        mainView.onKeyTap = { [weak self] in
            switch $0 {
            case let .key(character):
                self?.model.updateAmount(key: character)
            case .delete:
                self?.model.deleteLastCharacter()
            }
        }

        mainView.onContinueButtonTap = { [weak self] in
            self?.model.confirmValue()
        }
    }

    // MARK: Handlers

    private func handle(action: ChatRequestTokensModel.Action) {
        switch action {
        case let .endFlow(value):
            onSelection?(value)
            navigationController?.popViewController(animated: true)
        }
    }
}
