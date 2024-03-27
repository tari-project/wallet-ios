//  PopUpPresenter+CommonPopUps.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 10/04/2022
	Using Swift 5.0
	Running on macOS 12.3

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

struct PopUpDialogModel {
    let titleComponents: [StylizedLabel.StylizedText]
    let messageComponents: [StylizedLabel.StylizedText]
    let buttons: [PopUpDialogButtonModel]
    let hapticType: PopUpPresenter.HapticType

    init(titleComponents: [StylizedLabel.StylizedText], messageComponents: [StylizedLabel.StylizedText], buttons: [PopUpDialogButtonModel], hapticType: PopUpPresenter.HapticType) {
        self.titleComponents = titleComponents
        self.messageComponents = messageComponents
        self.buttons = buttons
        self.hapticType = hapticType
    }

    init(title: String?, message: String?, buttons: [PopUpDialogButtonModel], hapticType: PopUpPresenter.HapticType) {

        if let title {
            titleComponents = [StylizedLabel.StylizedText(text: title, style: .normal)]
        } else {
            titleComponents = []
        }

        if let message {
            messageComponents = [StylizedLabel.StylizedText(text: message, style: .normal)]
        } else {
            messageComponents = []
        }

        self.buttons = buttons
        self.hapticType = hapticType
    }
}

struct PopUpDialogButtonModel {

    enum ButtonType {
        case normal
        case destructive
        case text
        case textDimmed
    }

    let title: String
    let icon: UIImage?
    let type: ButtonType
    let callback: (() -> Void)?

    init(title: String, icon: UIImage? = nil, type: ButtonType, callback: (() -> Void)? = nil) {
        self.title = title
        self.icon = icon
        self.type = type
        self.callback = callback
    }
}

struct MessageModel {

    enum MessageType {
        case normal
        case error
    }

    let title: String
    let message: String?
    let type: MessageType
}

extension PopUpPresenter {

    enum BLEDialogType {
        case scanForContactListReceiver(onCancel: (() -> Void)?)
        case successContactSharing
        case scanForTransactionData(onCancel: (() -> Void)?)
        case confirmTransactionData(receiverName: String, onConfirmation: (() -> Void)?, onReject: (() -> Void)?)
        case failure(message: String?)
    }

    @MainActor static func show(message: MessageModel) {
        let model = PopUpDialogModel(title: message.title, message: message.message, buttons: [], hapticType: makeHapticType(model: message))
        showPopUp(model: model)
        log(message: message)
    }

    @MainActor static func showMessageWithCloseButton(message: MessageModel, onCloseButtonAction: (() -> Void)? = nil) {

        let model = PopUpDialogModel(
            title: message.title,
            message: message.message,
            buttons: [PopUpDialogButtonModel(title: localized("common.close"), type: .text, callback: onCloseButtonAction)],
            hapticType: makeHapticType(model: message)
        )

        showPopUp(model: model)
        log(message: message)
    }

    @MainActor static func showQRCodeDialog(title: String) -> PopUpQRContentView {

        let headerView = PopUpHeaderView()
        let contentView = PopUpQRContentView()
        let buttonsView = PopUpButtonsView()

        headerView.label.text = title
        buttonsView.addButton(model: PopUpDialogButtonModel(title: localized("common.close"), icon: nil, type: .text, callback: { PopUpPresenter.dismissPopup() }))

        let popUp = TariPopUp(headerSection: headerView, contentSection: contentView, buttonsSection: buttonsView)
        PopUpPresenter.show(popUp: popUp)

        return contentView
    }

    @MainActor static func showBLEDialog(type: BLEDialogType) {

        let headerSection = PopUpCircleImageHeaderView()
        let contentSection = PopUpDescriptionContentView()
        let buttonsSection = PopUpButtonsView()

        let viewModel = type.viewModel

        headerSection.image = viewModel.image
        headerSection.imageTintColor = viewModel.imageTintColor
        headerSection.text = viewModel.title
        contentSection.label.textComponents = viewModel.messageComponents

        viewModel.buttons.forEach { buttonsSection.addButton(model: $0) }

        switch type {
        case .successContactSharing:
            PopUpPresenter.dismissPopup(tag: PopUpTag.bleScanContactSharingDialog.rawValue)
        case .confirmTransactionData:
            PopUpPresenter.dismissPopup(tag: PopUpTag.bleScanTransactionDataDialog.rawValue)
        case .failure:
            PopUpPresenter.dismissPopup(tag: PopUpTag.bleScanContactSharingDialog.rawValue)
            PopUpPresenter.dismissPopup(tag: PopUpTag.bleScanTransactionDataDialog.rawValue)
        default:
            break
        }

        let popUp = TariPopUp(headerSection: headerSection, contentSection: contentSection, buttonsSection: buttonsSection)
        PopUpPresenter.show(popUp: popUp, configuration: .dialog(hapticType: viewModel.hapticType), tag: viewModel.tag)
    }

    @MainActor static func showPopUp(model: PopUpDialogModel) {

        var headerView: UIView?
        var contentView: UIView?
        var buttonsView: UIView?

        if !model.titleComponents.isEmpty {
            let view = PopUpHeaderView()
            view.label.textComponents = model.titleComponents
            headerView = view
        }

        if !model.messageComponents.isEmpty {
            let view = PopUpDescriptionContentView()
            view.label.textComponents = model.messageComponents
            contentView = view
        }

        if !model.buttons.isEmpty {
            buttonsView = PopUpComponentsFactory.makeButtonsView(models: model.buttons)
        }

        let popUp = TariPopUp(headerSection: headerView, contentSection: contentView, buttonsSection: buttonsView)
        let configuration = makeConfiguration(model: model)
        show(popUp: popUp, configuration: configuration)
    }

    @MainActor static func showAddressPoisoningPopUp(options: [PopUpAddressPoisoningContentCell.ViewModel], onContinue: ((_ selectedOption: PopUpAddressPoisoningContentCell.ViewModel, _ isTrusted: Bool) -> Void)?) {

        let headerSection = PopUpHeaderWithSubtitle()
        let contentSection = PopUpAddressPoisoningContentView()
        let buttonsSection = PopUpButtonsView()

        headerSection.titleLabel.text = localized("address_poisoning.pop_up.title")
        headerSection.subtitleLabel.text = localized("address_poisoning.pop_up.message", arguments: options.count)

        contentSection.viewModels = options

        buttonsSection.addButton(model: PopUpDialogButtonModel(title: localized("common.continue"), type: .normal, callback: {
            PopUpPresenter.dismissPopup {
                guard let index = contentSection.selectedIndex else { return }
                onContinue?(options[index], contentSection.isTrustedTickSelected)
            }
        }))
        buttonsSection.addButton(model: PopUpDialogButtonModel(title: localized("common.cancel"), type: .text, callback: { PopUpPresenter.dismissPopup() }))

        let popup = TariPopUp(headerSection: headerSection, contentSection: contentSection, buttonsSection: buttonsSection)
        PopUpPresenter.show(popUp: popup)
    }

    private static func log(message: MessageModel) {
        var log = "Pop-up Title: \(message.title)"

        if let description = message.message {
            log += " Message: \(description)"
        }

        switch message.type {
        case .normal:
            log += " Type: Normal"
        case .error:
            log += " Type: Error"
        }

        Logger.log(message: log, domain: .userInterface, level: .info)
    }

    // MARK: - Helpers

    private static func makeHapticType(model: MessageModel) -> HapticType {
        switch model.type {
        case .error:
            return .error
        case .normal:
            return .none
        }
    }

    private static func makeConfiguration(model: PopUpDialogModel) -> Configuration {
        model.buttons.isEmpty ? .message(hapticType: model.hapticType) : .dialog(hapticType: model.hapticType)
    }
}

extension PopUpPresenter.Configuration {

    static func message(hapticType: PopUpPresenter.HapticType) -> Self {
        Self(displayDuration: 12.0, dismissOnTapOutsideOrSwipe: true, hapticType: hapticType)
    }

    static func dialog(hapticType: PopUpPresenter.HapticType) -> Self {
        Self(displayDuration: nil, dismissOnTapOutsideOrSwipe: false, hapticType: hapticType)
    }
}

private struct BLEDialogModel {
    let image: UIImage?
    let imageTintColor: PopUpCircleImageHeaderView.ImageTint
    let title: String?
    let messageComponents: [StylizedLabel.StylizedText]
    let tag: String?
    let buttons: [PopUpDialogButtonModel]
    let hapticType: PopUpPresenter.HapticType
}

private extension PopUpPresenter.BLEDialogType {

    var viewModel: BLEDialogModel {

        switch self {
        case let .scanForContactListReceiver(onCancel):
            return BLEDialogModel(
                image: .Images.ContactBook.BLEDialog.icon,
                imageTintColor: .purple,
                title: localized("contact_book.popup.ble.share.title"),
                messageComponents: [StylizedLabel.StylizedText(text: localized("contact_book.popup.ble.share.message"), style: .normal)],
                tag: PopUpTag.bleScanContactSharingDialog.rawValue,
                buttons: [makeCancelButtonModel(callback: onCancel)],
                hapticType: .none
            )
        case .successContactSharing:
            return BLEDialogModel(
                image: .Images.ContactBook.BLEDialog.success,
                imageTintColor: .purple,
                title: localized("contact_book.popup.ble.success.title"),
                messageComponents: [StylizedLabel.StylizedText(text: localized("contact_book.popup.ble.success.message"), style: .normal)],
                tag: nil,
                buttons: [makeCancelButtonModel()],
                hapticType: .success
            )
        case let .scanForTransactionData(onCancel):
            return BLEDialogModel(
                image: .Images.ContactBook.BLEDialog.icon,
                imageTintColor: .purple,
                title: localized("contact_book.popup.ble.transaction.scan.title"),
                messageComponents: [StylizedLabel.StylizedText(text: localized("contact_book.popup.ble.transaction.scan.message"), style: .normal)],
                tag: PopUpTag.bleScanTransactionDataDialog.rawValue,
                buttons: [makeCancelButtonModel(callback: onCancel)],
                hapticType: .none
            )
        case let .confirmTransactionData(receiverName, confirmationCallback, rejectCallback):
            return BLEDialogModel(
                image: .Images.ContactBook.BLEDialog.icon,
                imageTintColor: .purple,
                title: localized("contact_book.popup.ble.transaction.confimation.title"),
                messageComponents: [
                    StylizedLabel.StylizedText(text: localized("contact_book.popup.ble.transaction.confimation.message.part.1"), style: .normal),
                    StylizedLabel.StylizedText(text: receiverName, style: .bold),
                    StylizedLabel.StylizedText(text: localized("contact_book.popup.ble.transaction.confimation.message.part.3"), style: .normal)
                ],
                tag: nil,
                buttons: [
                    PopUpDialogButtonModel(title: localized("contact_book.popup.ble.transaction.confimation.button.confirm"), type: .normal, callback: { PopUpPresenter.dismissPopup { confirmationCallback?() }}),
                    PopUpDialogButtonModel(title: localized("contact_book.popup.ble.transaction.confimation.button.reject"), type: .text, callback: { PopUpPresenter.dismissPopup { rejectCallback?() }})
                ],
                hapticType: .success
            )
        case let .failure(message):

            var components = [StylizedLabel.StylizedText]()

            if let message {
                components = [StylizedLabel.StylizedText(text: message, style: .normal)]
            }

            return BLEDialogModel(
                image: .Images.ContactBook.BLEDialog.failure,
                imageTintColor: .red,
                title: localized("contact_book.popup.ble.failure.title"),
                messageComponents: components,
                tag: nil,
                buttons: [makeCancelButtonModel()],
                hapticType: .error
            )
        }
    }

    private func makeCancelButtonModel(callback: (() -> Void)? = nil) -> PopUpDialogButtonModel {
        PopUpDialogButtonModel(title: localized("common.close"), type: .text, callback: { PopUpPresenter.dismissPopup(onCompletion: callback) })
    }
}
