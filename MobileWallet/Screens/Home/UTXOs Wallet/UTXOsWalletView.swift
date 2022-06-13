//  UTXOsWalletView.swift
	
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
import TariCommon
import Combine

final class UTXOsWalletView: BaseNavigationContentView {
    
    enum ListType {
        case tiles
        case text
    }
    
    // MARK: - Suviews
    
    @View var tileListButton: UTXOsWalletStateButton = {
        let view = UTXOsWalletStateButton()
        view.setImage(Theme.shared.images.utxoTileViewIcon, for: .normal)
        view.tintColor = .tari.greys.black
        view.toggleAutomatically = false
        return view
    }()
    
    @View var textListButton: UTXOsWalletStateButton = {
        let view = UTXOsWalletStateButton()
        view.setImage(Theme.shared.images.utxoTextListIcon, for: .normal)
        view.tintColor = .tari.greys.black
        view.toggleAutomatically = false
        return view
    }()
    
    @View private var sortMethodSegmenterControl: UISegmentedControl = {
        let view = UISegmentedControl(items: [localized("utxos_wallet.segmented_control.sort.size"), localized("utxos_wallet.segmented_control.sort.date")])
        view.setWidth(85.0, forSegmentAt: 0)
        view.setWidth(85.0, forSegmentAt: 1)
        view.selectedSegmentIndex = 0
        return view
    }()
    
    @View var sortDirectionButton: BaseButton = {
        let view = BaseButton()
        view.tintColor = .tari.greys.black
        view.contentMode = .scaleAspectFit
        view.imageEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
        return view
    }()
    
    @View var selectionModeButton: UTXOsWalletStateButton = {
        let view = UTXOsWalletStateButton()
        view.setImage(Theme.shared.images.utxoSelectIcon, for: .normal)
        view.tintColor = .tari.greys.black
        return view
    }()
    
    @View private var tileList = UTXOsWalletTileListView()
    
    @View private var textList: UTXOsWalletTextListView = {
        let view = UTXOsWalletTextListView()
        view.alpha = 0.0
        return view
    }()
    
    // MARK: - Properties
    
    @Published var isSortAscending: Bool = false
    @Published var selectedElements: Set<UUID> = []
    @Published private(set) var isEditingEnabled: Bool = false
    @Published private(set) var tappedElement: UUID?
    @Published private var visibleListType: ListType = .tiles
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialisers
    
    override init() {
        super.init()
        setupViews()
        setupConstraints()
        setupCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupViews() {
        backgroundColor = .tari.white
        navigationBar.title = localized("utxos_wallet.title")
    }
    
    private func setupConstraints() {
        
        [sortMethodSegmenterControl, tileList, textList, sortDirectionButton, selectionModeButton].forEach(addSubview)
        [textListButton, tileListButton].forEach(navigationBar.addSubview)
        
        let constraints = [
            textListButton.trailingAnchor.constraint(equalTo: tileListButton.leadingAnchor, constant: -4.0),
            textListButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            textListButton.heightAnchor.constraint(equalToConstant: 30.0),
            textListButton.widthAnchor.constraint(equalToConstant: 30.0),
            tileListButton.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor, constant: -12.0),
            tileListButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            tileListButton.heightAnchor.constraint(equalToConstant: 30.0),
            tileListButton.widthAnchor.constraint(equalToConstant: 30.0),
            sortMethodSegmenterControl.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 30.0),
            sortMethodSegmenterControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30.0),
            sortDirectionButton.leadingAnchor.constraint(equalTo: sortMethodSegmenterControl.trailingAnchor, constant: 8.0),
            sortDirectionButton.centerYAnchor.constraint(equalTo: sortMethodSegmenterControl.centerYAnchor),
            sortDirectionButton.heightAnchor.constraint(equalToConstant: 30.0),
            sortDirectionButton.widthAnchor.constraint(equalToConstant: 30.0),
            selectionModeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30.0),
            selectionModeButton.centerYAnchor.constraint(equalTo: sortMethodSegmenterControl.centerYAnchor),
            selectionModeButton.heightAnchor.constraint(equalToConstant: 30.0),
            selectionModeButton.widthAnchor.constraint(equalToConstant: 30.0),
            tileList.topAnchor.constraint(equalTo: sortMethodSegmenterControl.bottomAnchor),
            tileList.leadingAnchor.constraint(equalTo: leadingAnchor),
            tileList.trailingAnchor.constraint(equalTo: trailingAnchor),
            tileList.bottomAnchor.constraint(equalTo: bottomAnchor),
            textList.topAnchor.constraint(equalTo: sortMethodSegmenterControl.bottomAnchor),
            textList.leadingAnchor.constraint(equalTo: leadingAnchor),
            textList.trailingAnchor.constraint(equalTo: trailingAnchor),
            textList.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupCallbacks() {
        
        $isSortAscending
            .sink { [weak self] in
                let image = $0 ? Theme.shared.images.utxoAscendingIcon : Theme.shared.images.utxoDescendingIcon
                self?.sortDirectionButton.setImage(image, for: .normal)
            }
            .store(in: &cancellables)
        
        $visibleListType
            .sink { [weak self] in self?.updateListComponents(visibleListType: $0) }
            .store(in: &cancellables)
        
        $isEditingEnabled
            .sink { [weak self] in
                self?.tileList.isEditingEnabled = $0
                self?.textList.isEditingEnabled = $0
            }
            .store(in: &cancellables)
        
        $selectedElements
            .sink { [weak self] in
                self?.tileList.update(selectedElements: $0)
                self?.textList.update(selectedElements: $0)
            }
            .store(in: &cancellables)
        
        tileListButton.onTap = { [weak self] in
            self?.visibleListType = .tiles
        }
        
        textListButton.onTap = { [weak self] in
            self?.visibleListType = .text
        }
        
        selectionModeButton.onTap = { [weak self] in
            self?.isEditingEnabled.toggle()
        }
        
        tileList.onTapOnTile = { [weak self] in
            self?.tappedElement = $0
        }
        
        tileList.onLongPressOnTile = { [weak self] in
            guard let self = self, !self.isEditingEnabled else { return }
            self.selectionModeButton.isSelected = true
            self.isEditingEnabled = true
            self.tappedElement = $0
        }
        
        textList.onTapOnTickbox = { [weak self] in
            self?.tappedElement = $0
        }
    }
    
    // MARK: - Actions
    
    func updateTileList(models: [UTXOTileView.Model]) {
        tileList.models = models
    }
    
    func updateTextList(models: [UTXOsWalletTextListViewCell.Model]) {
        textList.models = models
    }
    
    private func updateListComponents(visibleListType: ListType) {
        switch visibleListType {
        case .tiles:
            tileListButton.isSelected = true
            textListButton.isSelected = false
        case .text:
            tileListButton.isSelected = false
            textListButton.isSelected = true
        }
        
        UIView.animate(withDuration: 0.3) {
            switch visibleListType {
            case .tiles:
                self.tileList.alpha = 1.0
                self.textList.alpha = 0.0
            case .text:
                self.tileList.alpha = 0.0
                self.textList.alpha = 1.0
            }
        }
    }
}
