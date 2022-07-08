//  UTXOsWalletViewController.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 31/05/2022
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
import Combine

final class UTXOsWalletViewController: UIViewController {
    
    // MARK: - Properties
    
    private let model: UTXOsWalletModel
    private let mainView = UTXOsWalletView()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialisers
    
    init(model: UTXOsWalletModel) {
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
    }
    
    // MARK: - Setups
    
    private func setupCallbacks() {
        
        model.$utxoModels
            .compactMap { [weak self] in self?.tileModels(fromModels: $0) }
            .sink { [weak self] in self?.mainView.updateTileList(models: $0) }
            .store(in: &cancellables)
        
        model.$utxoModels
            .compactMap { [weak self] in self?.textListModels(fromModels: $0) }
            .sink { [weak self] in self?.mainView.updateTextList(models: $0) }
            .store(in: &cancellables)
        
        model.$sortMethod
            .map { $0.title }
            .assign(to: \.selectedSortMethodName, on: mainView)
            .store(in: &cancellables)
        
        model.$selectedIDs
            .assign(to: \.selectedElements, on: mainView)
            .store(in: &cancellables)
        
        model.$selectedIDs
            .compactMap { [weak self] in self?.actionTypes(selectedIDs: $0) }
            .removeDuplicates()
            .assign(to: \.actionTypes, on: mainView)
            .store(in: &cancellables)
        
        model.$errorMessage
            .compactMap { $0 }
            .sink { PopUpPresenter.show(message: $0) }
            .store(in: &cancellables)
        
        mainView.$tappedElement
            .compactMap { $0 }
            .filter { [unowned self] _ in self.mainView.isEditingEnabled }
            .sink { [weak self] in self?.model.toogleState(elementID: $0) }
            .store(in: &cancellables)
        
        mainView.$isEditingEnabled
            .filter { $0 == false }
            .sink { [weak self] _ in self?.model.deselectAllElements() }
            .store(in: &cancellables)
        
        mainView.onFilterButtonTap = { [weak self] in
            self?.showFiltersListDialog()
        }

        mainView.onActionButtonTap = { [weak self] in
            switch $0 {
            case .split:
                self?.showSplitDialog()
            case .join:
                self?.showJoinConfimationDialog()
            case .splitJoin:
                break
            }
        }
        
        Publishers.CombineLatest3(model.$isLoadingData, model.$utxoModels, mainView.$selectedListType)
            .map {
                guard !$0 else { return .loadingScreen }
                guard $1.count > 0 else { return .placeholder }
                
                switch $2 {
                case .tiles:
                    return .tilesList
                case .text:
                    return .textList
                }
            }
            .assign(to: \.visibleContentType, on: mainView)
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    private func showFiltersListDialog() {
        
        let headerSection = PopUpHeaderView()
        let contentSection = PopUpSelectionView()
        let buttonsSection = PopUpButtonsView()
        
        headerSection.label.text = localized("utxos_wallet.pop_up.sort.title")
        contentSection.update(options: UTXOsWalletModel.SortMethod.allCases.map { $0.title }, selectedIndex: model.sortMethod.rawValue)
        
        buttonsSection.addButton(model: PopUpDialogButtonModel(title: localized("common.apply"), type: .normal, callback: { [weak contentSection, weak self] in
            PopUpPresenter.dismissPopup()
            guard let contentSection = contentSection, let sortState = UTXOsWalletModel.SortMethod(rawValue: contentSection.selectedIndex) else { return }
            self?.model.sortMethod = sortState
        }))
        buttonsSection.addButton(model: PopUpDialogButtonModel(title: localized("common.cancel"), type: .text, callback: { PopUpPresenter.dismissPopup() }))
        
        let popUp = TariPopUp(headerSection: headerSection, contentSection: contentSection, buttonsSection: buttonsSection)
        PopUpPresenter.show(popUp: popUp)
    }
    
    // MARK: - Actions - Break Pop Ups
    
    private func showSplitDialog() {
        
        let headerSection = PopUpHeaderView()
        let contentSection = PopUpUTXOsSplitContentView()
        let buttonsSection = PopUpButtonsView()
        
        headerSection.label.text = localized("utxos_wallet.pop_up.split.title")
        
        let cancellable = contentSection.$value
            .sink { [weak self, weak contentSection] in
                guard let self = self, let previewData = self.model.splitCoinPreview(splitCount: $0) else { return }
                contentSection?.update(amount: previewData.amount, splitCount: previewData.splitCount, splitAmount: previewData.splitAmount, fee: previewData.fee)
            }
        
        buttonsSection.addButton(model: PopUpDialogButtonModel(title: localized("utxos_wallet.pop_up.split.button.ok"), type: .normal, callback: {
            cancellable.cancel()
            PopUpPresenter.dismissPopup { [weak contentSection, weak self] in
                guard let contentSection = contentSection else { return }
                self?.showSplitConfirmationDialog(splitCount: contentSection.value)
            }
        }))
        buttonsSection.addButton(model: PopUpDialogButtonModel(title: localized("common.cancel"), type: .text, callback: { PopUpPresenter.dismissPopup() }))
        
        let popUp = TariPopUp(headerSection: headerSection, contentSection: contentSection, buttonsSection: buttonsSection)
        PopUpPresenter.show(popUp: popUp, configuration: .dialog(hapticType: .none))
    }
    
    private func showSplitConfirmationDialog(splitCount: Int) {
        showConfirmationDialog(message: localized("utxos_wallet.pop_up.split_confirmation.message")) { [weak self] in
            self?.model.performSplitAction(splitCount: splitCount)
            self?.showSplitSuccessDialog()
        }
    }
    
    private func showSplitSuccessDialog() {
        showSuccessDialog(message: localized("utxos_wallet.pop_up.split_success.description"))
    }
    
    // MARK: - Actions - Combine Pop Ups
    
    private func showJoinConfimationDialog() {
        
        let headerSection = PopUpHeaderView()
        let contentSection = PopUpCombineUTXOsConfirmationContentView()
        let buttonsSection = PopUpButtonsView()
        
        headerSection.label.text = localized("utxos_wallet.pop_up.confirmation.title")
        contentSection.messageText = localized("utxos_wallet.pop_up.join_confirmation.message")
        contentSection.feeText = model.joinCoinsFeePreview() ?? ""
        buttonsSection.addButton(model: PopUpDialogButtonModel(title: localized("utxos_wallet.pop_up.confirmation.button.ok"), type: .normal, callback: { [weak self] in
            self?.model.performJoinAction()
            self?.showJoinSuccessDialog()
        }))
        buttonsSection.addButton(model: PopUpDialogButtonModel(title: localized("common.cancel"), type: .text, callback: { PopUpPresenter.dismissPopup() }))
        
        let popUp = TariPopUp(headerSection: headerSection, contentSection: contentSection, buttonsSection: buttonsSection)
        PopUpPresenter.show(popUp: popUp, configuration: .dialog(hapticType: .none))
    }
    
    private func showJoinSuccessDialog() {
        showSuccessDialog(message: localized("utxos_wallet.pop_up.join_success.description"))
    }
    
    // MARK: - Actions - Pop Ups Helpers
    
    private func showConfirmationDialog(message: String, onConfirm: @escaping (() -> Void)) {
        
        let model = PopUpDialogModel(
            title: localized("utxos_wallet.pop_up.confirmation.title"),
            message: message,
            buttons: [
                PopUpDialogButtonModel(title: localized("utxos_wallet.pop_up.confirmation.button.ok"), type: .normal, callback: onConfirm),
                PopUpDialogButtonModel(title: localized("common.cancel"), type: .text),
            ],
            hapticType: .none
        )
        
        PopUpPresenter.showPopUp(model: model)
    }
    
    private func showSuccessDialog(message: String) {
        
        let headerSection = PopUpImageHeaderView()
        let contentSection = PopUpDescriptionContentView()
        let buttonsSection = PopUpButtonsView()
        
        headerSection.imageView.image = Theme.shared.images.utxoSuccessImage
        headerSection.imageHeight = 90.0
        
        headerSection.label.text = localized("utxos_wallet.pop_up.success.title")
        contentSection.label.text = message
        buttonsSection.addButton(model: PopUpDialogButtonModel(title: localized("common.close"), type: .text, callback: { [weak self] in
            self?.mainView.isEditingEnabled = false
            self?.model.reloadData()
            PopUpPresenter.dismissPopup()
        }))
        
        let popUp = TariPopUp(headerSection: headerSection, contentSection: contentSection, buttonsSection: buttonsSection)
        popUp.topOffset = 75.0
        
        PopUpPresenter.show(popUp: popUp, configuration: .dialog(hapticType: .none))
    }
    
    // MARK: - Helpers
    
    private func tileModels(fromModels models: [UTXOsWalletModel.UtxoModel]) -> [UTXOTileView.Model] {
        models
            .map {
                UTXOTileView.Model(
                    uuid: $0.uuid,
                    amountText: $0.amountText,
                    backgroundColor: .tari.purple?.colorVariant(text: $0.hash),
                    height: $0.tileHeight,
                    statusIcon: $0.status.icon,
                    statusColor: $0.status.color,
                    date: $0.date,
                    isSelectable: $0.isSelectable
                )
            }
    }
    
    private func textListModels(fromModels models: [UTXOsWalletModel.UtxoModel]) -> [UTXOsWalletTextListViewCell.Model] {
        models.map { UTXOsWalletTextListViewCell.Model(id: $0.uuid, amount: $0.amountWithCurrency, statusColor: $0.status.color, statusText: [$0.status.name, $0.date, $0.time].joined(separator: " | "), hash: $0.hash, isSelectable: $0.isSelectable) }
    }
    
    private func actionTypes(selectedIDs: Set<UUID>) -> [UTXOsWalletView.ActionType] {
        switch selectedIDs.count {
        case 0:
            return []
        case 1:
            return [.split]
        default:
            return [.join, .splitJoin]
        }
    }
}

extension UTXOsWalletModel.SortMethod {

    var title: String {
        switch self {
        case .amountAscending:
            return localized("utxos_wallet.pop_up.sort.size.ascending")
        case .amountDescending:
            return localized("utxos_wallet.pop_up.sort.size.descending")
        case .minedHeightAscending:
            return localized("utxos_wallet.pop_up.sort.date.ascending")
        case .minedHeightDescending:
            return localized("utxos_wallet.pop_up.sort.date.descending")
        }
    }
}
