//  ChatConversationViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 14/09/2023
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

final class ChatConversationViewController: UIViewController {

    // MARK: - Properties

    let model: ChatConversationModel
    let mainView = ChatConversationView()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(model: ChatConversationModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
        mainView.interactableViews.forEach { hideKeyboardWhenTappedAroundOrSwipedDown(view: $0) }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.updateUserData()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        model.$userData
            .compactMap { $0 }
            .map { ChatConversationView.Model(avatar: .avatar(text: $0.avatarText, image: $0.avatarImage), isOnline: $0.isOnline, name: $0.name) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.update(model: $0) }
            .store(in: &cancellables)

        model.$messages
            .compactMap { [weak self] in self?.sectionViewModels(sectionModels: $0) }
            .sink { [weak self] in self?.mainView.update(sections: $0) }
            .store(in: &cancellables)

        model.$messages
            .map(\.isEmpty)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.isPlaceholderVisible = $0 }
            .store(in: &cancellables)

        model.$action
            .compactMap { $0 }
            .sink { [weak self] in self?.handle(action: $0) }
            .store(in: &cancellables)

        model.$errorModel
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { PopUpPresenter.show(message: $0) }
            .store(in: &cancellables)

        mainView.onNavigationBarTap = { [weak self] in
            self?.model.requestContactDetails()
        }

        mainView.onSendButtonTap = { [weak self] in
            self?.model.send(message: $0 ?? "")
        }
    }

    // MARK: - Handlers

    private func sectionViewModels(sectionModels: [ChatConversationModel.MessageSection]) -> [ChatConversationView.Section] {
        sectionModels.map {
            let messages = $0.messages.map {
                ChatConversationCell.Model(id: $0.id, isIncoming: $0.isIncomming, isLastInContext: $0.isLastInContext, notificationTextComponents: $0.notificationParts, message: $0.message, timestamp: $0.timestamp)
            }
            return ChatConversationView.Section(title: $0.relativeDay, messages: messages)
        }
    }

    // MARK: - Actions

    private func handle(action: ChatConversationModel.Action) {
        switch action {
        case let .openContactDetails(contact):
            let controller = ContactDetailsConstructor.buildScene(model: contact)
            navigationController?.pushViewController(controller, animated: true)
        }
    }
}
