//  ChatListViewConrtoller.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 11/09/2023
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

import UIKit
import Combine

final class ChatListViewConrtoller: SecureViewController<ChatListView> {

    // MARK: - Properties

    private let model: ChatListModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(model: ChatListModel) {
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.updateData()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        model.$unreadMessagesCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.update(unreadMessagesCount: $0) }
            .store(in: &cancellables)

        model.$previewsSections
            .receive(on: DispatchQueue.main)
            .map {
                $0.map {
                    ChatListView.Section(
                        title: $0.title,
                        rows: $0.previews.map {
                            ChatListCell.Model(
                                id: $0.id,
                                avatar: $0.avatarImage != nil ? .image($0.avatarImage) : .text($0.avatarText),
                                isOnline: $0.isOnline,
                                title: $0.name,
                                message: $0.preview,
                                badgeNumber: $0.unreadMessagesCount,
                                timestamp: $0.timestamp
                            )
                        }
                    )
                }
            }
            .sink { [weak self] in self?.mainView.viewModels = $0 }
            .store(in: &cancellables)

        model.$action
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(action: $0 ) }
            .store(in: &cancellables)

        model.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(errorMessage: $0) }
            .store(in: &cancellables)

        mainView.onStartConversationButtonTap = { [weak self] in
            self?.moveToSelectAddressScene()
        }

        mainView.onSelectRow = { [weak self] in
            self?.model.select(identifier: $0)
        }
    }

    // MARK: - Handlers

    private func handle(action: ChatListModel.Action) {
        switch action {
        case let .openConversation(address):
            moveToConversationScene(address: address)
        }
    }

    private func handle(errorMessage: MessageModel) {
        PopUpPresenter.show(message: errorMessage)
    }

    // MARK: - Actions

    private func moveToSelectAddressScene() {
        let controller = ChatSelectContactConstructor.buildScene()
        navigationController?.pushViewController(controller, animated: true)
    }

    private func moveToConversationScene(address: TariAddress) {
        let controller = ChatConversationConstructor.buildScene(address: address)
        navigationController?.pushViewController(controller, animated: true)
    }
}
