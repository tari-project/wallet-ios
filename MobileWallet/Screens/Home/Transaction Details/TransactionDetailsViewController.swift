//  TransactionDetailsViewController.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 14/03/2022
	Using Swift 5.0
	Running on macOS 12.2

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

final class TransactionDetailsViewController: UIViewController {
    
    // MARK: - Properties
    
    private let model: TransactionDetailsModel
    private let mainView = TransactionDetailsView()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialisers
    
    init(model: TransactionDetailsModel) {
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
        hideKeyboardWhenTappedAroundOrSwipedDown()
    }
    
    // MARK: - Setups
    
    private func setupCallbacks() {
        
        model.$title
            .receive(on: DispatchQueue.main)
            .assign(to: \.title, on: mainView)
            .store(in: &cancellables)
        
        model.$subtitle
            .receive(on: DispatchQueue.main)
            .assign(to: \.subtitle, on: mainView)
            .store(in: &cancellables)
        
        model.$transactionState
            .receive(on: DispatchQueue.main)
            .assign(to: \.transactionState, on: mainView)
            .store(in: &cancellables)
        
        model.$amount
            .receive(on: DispatchQueue.main)
            .assign(to: \.text, on: mainView.valueView.valueLabel)
            .store(in: &cancellables)
        
        model.$fee
            .receive(on: DispatchQueue.main)
            .assign(to: \.fee, on: mainView.valueView)
            .store(in: &cancellables)
        
        model.$transactionDirection
            .receive(on: DispatchQueue.main)
            .assign(to: \.title, on: mainView.contactView)
            .store(in: &cancellables)
        
        model.$emojiIdViewModel
            .receive(on: DispatchQueue.main)
            .assign(to: \.emojiIdViewModel, on: mainView.contactView.contentView)
            .store(in: &cancellables)
        
        model.$isContactSectionVisible
            .map { !$0 }
            .receive(on: DispatchQueue.main)
            .assign(to: \.isHidden, on: mainView.contactView)
            .store(in: &cancellables)
        
        model.$isAddContactButtonVisible
            .map { !$0 }
            .receive(on: DispatchQueue.main)
            .assign(to: \.isHidden, on: mainView.contactView.contentView.addContactButton)
            .store(in: &cancellables)
        
        model.$isNameSectionVisible
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.mainView.contactNameView.isHidden = !$0
                self?.mainView.noteSeparatorView.isHidden = !$0
                guard $0, self?.mainView.contactNameView.contentView.textField.text?.isEmpty == true else { return }
                self?.mainView.contactNameView.contentView.isEditingEnabled = true
            }
            .store(in: &cancellables)
        
        model.$userAlias
            .receive(on: DispatchQueue.main)
            .assign(to: \.text, on: mainView.contactNameView.contentView.textField)
            .store(in: &cancellables)
        
        model.$note
            .receive(on: DispatchQueue.main)
            .assign(to: \.note, on: mainView.noteView.contentView)
            .store(in: &cancellables)
        
        model.$gifMedia
            .receive(on: DispatchQueue.main)
            .assign(to: \.gifMedia, on: mainView.noteView.contentView)
            .store(in: &cancellables)
        
        model.$wasTransactionCanceled
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self?.navigationController?.popToRootViewController(animated: true)
            }
            .store(in: &cancellables)
        
        model.$isBlockExplorerActionAvailable
            .map { !$0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.mainView.blockExplorerSeparatorView.isHidden = $0
                self?.mainView.blockExplorerView.isHidden = $0
            }
            .store(in: &cancellables)
        
        model.$linkToOpen
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { WebBrowserPresenter.open(url: $0) }
            .store(in: &cancellables)
        
        model.$errorModel
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { PopUpPresenter.show(message: $0) }
            .store(in: &cancellables)
        
        model.userAliasUpdateSuccessCallback = {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    
        mainView.valueView.feeButton.onTap = { [weak self] in
            self?.showFeeInfo()
        }
        
        mainView.cancelButton.onTap = { [weak self] in
            self?.showTransactionCancellationConfirmation()
        }
        
        mainView.contactView.contentView.addContactButton.onTap = { [weak self] in
            self?.model.addContactAliasRequest()
        }
        
        mainView.contactNameView.contentView.onNameChange = { [weak self] in
            self?.model.update(alias: $0)
        }
        
        mainView.blockExplorerView.contentView.onTap = { [weak self] in
            self?.model.requestLinkToBlockExplorer()
        }
    }
    
    // MARK: - Actions
    
    override func dismissKeyboard() {
        super.dismissKeyboard()
        model.resetAlias()
    }
    
    private func showFeeInfo() {
        PopUpPresenter.show(message: MessageModel(title: localized("common.fee_info.title"), message: localized("common.fee_info.description"), type: .normal))
    }
    
    private func showTransactionCancellationConfirmation() {
        
        let model = PopUpDialogModel(
            title: localized("tx_detail.tx_cancellation.title"),
            message: localized("tx_detail.tx_cancellation.message"),
            buttons: [
                PopUpDialogButtonModel(title: localized("tx_detail.tx_cancellation.yes"), type: .destructive, callback: { [weak self] in self?.model.cancelTransactionRequest() }),
                PopUpDialogButtonModel(title: localized("tx_detail.tx_cancellation.no"), type: .text)
            ],
            hapticType: .none
        )
        
        PopUpPresenter.showPopUp(model: model)
    }
}
