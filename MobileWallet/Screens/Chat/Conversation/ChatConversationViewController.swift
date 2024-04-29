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

final class ChatConversationViewController: SecureViewController<ChatConversationView> {

    private enum AddAction: Int {
        case send
        case request
        case pinThread
    }

    // MARK: - Properties

    let model: ChatConversationModel
    private let gifManager = GifManager()
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
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.update(sections: $0) }
            .store(in: &cancellables)

        model.$messages
            .map(\.isEmpty)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.isPlaceholderVisible = $0 }
            .store(in: &cancellables)

        model.$attachement
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(attachement: $0) }
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

        mainView.onAddButtonTap = { [weak self] in
            self?.showAddDialog()
        }

        mainView.onAddGifButtonTap = { [weak self] in
            guard let self else { return }
            self.gifManager.showGifPicker(controller: self)
        }

        mainView.onRemoveAttachementButtonTap = { [weak self] in
            self?.model.removeAttachment()
        }

        mainView.onSendButtonTap = { [weak self] in
            self?.model.send(message: $0 ?? "")
        }

        gifManager.$selectedGifID
            .compactMap { $0 }
            .sink { [weak self] in self?.model.attach(gifID: $0) }
            .store(in: &cancellables)
    }

    // MARK: - Handlers

    private func sectionViewModels(sectionModels: [ChatConversationModel.MessageSection]) -> [ChatConversationView.Section] {
        sectionModels.map {
            let messages = $0.messages.map { message in
                ChatConversationCell.Model(
                    id: message.id,
                    isIncoming: message.isIncomming,
                    isLastInContext: message.isLastInContext,
                    notificationsTextComponents: message.notifications
                    ,
                    message: message.message,
                    actionButtonTitle: message.action?.title,
                    actionCallback: { [weak self] in
                        guard let action = message.action else { return }
                        self?.model.handle(messageAction: action)
                    },
                    timestamp: message.timestamp,
                    gifIdentifier: message.gifIdentifier
                )
            }
            return ChatConversationView.Section(title: $0.relativeDay, messages: messages)
        }
    }

    private func handle(attachement: ChatConversationModel.Attachment?) {

        guard let attachement else {
            mainView.hideAttachmentsBar()
            mainView.update(attachment: nil)
            return
        }

        switch attachement {
        case let .request(value):
            mainView.update(attachment: .request(amount: value))
        case let .gif(status):
            mainView.update(attachment: .gif(state: status))
        }

        mainView.showAttachmentsBar()
    }

    private func handle(action: ChatConversationModel.Action) {
        switch action {
        case let .moveToContactDetails(contact):
            moveToContactDetailsScene(contact: contact)
        case let .moveToSendTransction(paymentInfo):
            moveToSendTrasactionScene(paymentInfo: paymentInfo)
        case .moveToRequestTokens:
            moveToRequestTokensScene()
        case .showReplaceAttachmentDialog:
            showReplaceAttachmentDialog()
        }
    }

    private func handle(addActionRow: Int) {

        PopUpPresenter.dismissPopup()

        guard let action = AddAction(rawValue: addActionRow) else { return }

        switch action {
        case .send:
            model.requestSendTransaction()
        case .request:
            model.requestTokens()
        case .pinThread:
            model.switchPinedStatus()
        }
    }

    // MARK: - Actions

    private func showAddDialog() {

        let headerSection = PopUpHeaderView()
        let contentSection = PopUpButtonsTableView()
        let buttonsSection = PopUpButtonsView()

        headerSection.label.text = localized("chat.conversation.pop_up.add_dialog.title")

        let pinnedThreadButtonTitle = model.isPinned ? localized("chat.conversation.pop_up.add_dialog.buttons.pinned_thread.unpin") : localized("chat.conversation.pop_up.add_dialog.buttons.pinned_thread.pin")

        contentSection.update(options: [
            PopUpButtonsTableView.Model(id: UUID(), title: localized("chat.conversation.pop_up.add_dialog.buttons.send"), textAlignment: .left, isArrowVisible: true),
            PopUpButtonsTableView.Model(id: UUID(), title: localized("chat.conversation.pop_up.add_dialog.buttons.request"), textAlignment: .left, isArrowVisible: true),
            PopUpButtonsTableView.Model(id: UUID(), title: pinnedThreadButtonTitle, textAlignment: .left, isArrowVisible: false)
        ])

        contentSection.onSelectedRow = { [weak self] in
            self?.handle(addActionRow: $0.row)
        }

        buttonsSection.addButton(model: PopUpDialogButtonModel(title: localized("common.cancel"), type: .text, callback: { PopUpPresenter.dismissPopup() }))

        let popUp = TariPopUp(headerSection: headerSection, contentSection: contentSection, buttonsSection: buttonsSection)

        PopUpPresenter.show(popUp: popUp)
    }

    private func showReplaceAttachmentDialog() {

        PopUpPresenter.showPopUp(model: PopUpDialogModel(
            title: localized("chat.conversation.pop_up.replace_attachment.title"),
            message: localized("chat.conversation.pop_up.replace_attachment.message"),
            buttons: [
                PopUpDialogButtonModel(title: localized("chat.conversation.pop_up.replace_attachment.buttons.yes"), type: .normal, callback: { [weak self] in self?.model.confirmAttachmentReplacement() }),
                PopUpDialogButtonModel(title: localized("chat.conversation.pop_up.replace_attachment.buttons.no"), type: .text, callback: { [weak self] in self?.model.cancelAttachmetReplacement() })
            ],
            hapticType: .none
        ))
    }

    private func moveToContactDetailsScene(contact: ContactsManager.Model) {
        let controller = ContactDetailsConstructor.buildScene(model: contact)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func moveToSendTrasactionScene(paymentInfo: PaymentInfo) {
        AppRouter.presentSendTransaction(paymentInfo: paymentInfo)
    }

    private func moveToRequestTokensScene() {

        let controller = ChatRequestTokensConstructor.buildScene()

        controller.onSelection = { [weak self] in
            self?.model.attach(requestedTokenAmount: $0)
        }

        navigationController?.pushViewController(controller, animated: true)
    }
}
