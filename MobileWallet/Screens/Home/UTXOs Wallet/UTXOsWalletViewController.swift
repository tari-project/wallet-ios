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
        
        model.$isSortOrderAscending
            .assign(to: \.isSortAscending, on: mainView)
            .store(in: &cancellables)
        
        mainView.sortDirectionButton.onTap = { [weak self] in
            self?.model.toggleSortOrder()
        }
    }
    
    // MARK: - Helpers
    
    private func tileModels(fromModels models: [UTXOsWalletModel.UtxoModel]) -> [UTXOTileView.Model] {
        models.map { UTXOTileView.Model(amountText: $0.amountText, backgroundColor: .tari.purple?.colorVariant(text: $0.hash), height: $0.tileHeight, statusIcon: $0.status.icon, statusName: $0.status.name) }
    }
    
    private func textListModels(fromModels models: [UTXOsWalletModel.UtxoModel]) -> [UTXOsWalletTextListViewCell.Model] {
        models.map { UTXOsWalletTextListViewCell.Model(id: UUID(), amount: $0.amountWithCurrency, hash: $0.hash) }
    }
}
