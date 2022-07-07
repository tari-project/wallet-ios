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
    
    enum VisibleContentType {
        case placeholder
        case loadingScreen
        case tilesList
        case textList
    }
    
    enum ActionType {
        case split
        case join
        case splitJoin
    }
    
    // MARK: - Constants
    
    private let topBarHeight: CGFloat = 66.0
    
    // MARK: - Suviews
    
    @View private var contextualButtonsOverlay = ContextualButtonsOverlay()
    
    @View private var switchListButton: BaseButton = {
        let view = BaseButton()
        view.tintColor = .tari.greys.black
        return view
    }()
    
    @View private var topToolbar = UTXOsWalletTopBar()
    @View private var tileList = UTXOsWalletTileListView()
    
    @View private var textList: UTXOsWalletTextListView = {
        let view = UTXOsWalletTextListView()
        view.alpha = 0.0
        return view
    }()
    
    @View private var placeholderView: UTXOsWalletPlaceholderView = {
        let view = UTXOsWalletPlaceholderView()
        view.alpha = 0.0
        return view
    }()
    
    @View private var loadingView: UTXOsWalletLoadingView = {
        let view = UTXOsWalletLoadingView()
        view.alpha = 0.0
        return view
    }()
    
    // MARK: - Properties
    
    @Published var selectedSortMethodName: String?
    @Published var visibleContentType: VisibleContentType = .tilesList
    @Published var selectedElements: Set<UUID> = []
    @Published var actionTypes: [ActionType] = []
    @Published var isEditingEnabled: Bool = false
    @Published private(set) var tappedElement: UUID?
    @Published private(set) var selectedListType: ListType = .tiles
    
    var onFilterButtonTap: (() -> Void)?
    var onActionButtonTap: ((ActionType) -> Void)?
    
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
        backgroundColor = Theme.shared.colors.profileBackground
        navigationBar.title = localized("utxos_wallet.title")
        topToolbar.height = topBarHeight
        tileList.verticalContentInset = topBarHeight
        textList.verticalContentInset = topBarHeight
    }
    
    private func setupConstraints() {
        
        [loadingView, placeholderView, tileList, textList, topToolbar, contextualButtonsOverlay].forEach(addSubview)
        navigationBar.addSubview(switchListButton)
        
        let constraints = [
            switchListButton.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor, constant: -30.0),
            switchListButton.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor),
            switchListButton.heightAnchor.constraint(equalToConstant: 30.0),
            switchListButton.widthAnchor.constraint(equalToConstant: 30.0),
            topToolbar.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            topToolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            topToolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            loadingView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            loadingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: bottomAnchor),
            placeholderView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            placeholderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            placeholderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            placeholderView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tileList.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            tileList.leadingAnchor.constraint(equalTo: leadingAnchor),
            tileList.trailingAnchor.constraint(equalTo: trailingAnchor),
            tileList.bottomAnchor.constraint(equalTo: bottomAnchor),
            textList.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            textList.leadingAnchor.constraint(equalTo: leadingAnchor),
            textList.trailingAnchor.constraint(equalTo: trailingAnchor),
            textList.bottomAnchor.constraint(equalTo: bottomAnchor),
            contextualButtonsOverlay.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            contextualButtonsOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            contextualButtonsOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            contextualButtonsOverlay.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupCallbacks() {
        
        $selectedSortMethodName
            .sink { [weak self] in self?.topToolbar.filterButtonTitle = $0 }
            .store(in: &cancellables)
        
        $selectedListType
            .sink { [weak self] in self?.updateListSwitchIcon(selectedListType: $0) }
            .store(in: &cancellables)
        
        $visibleContentType
            .sink { [weak self] in self?.updateListComponents(visibleContentType: $0) }
            .store(in: &cancellables)
        
        $isEditingEnabled
            .sink { [weak self] in
                self?.topToolbar.isEditingEnabled = $0
                self?.tileList.isEditingEnabled = $0
                self?.textList.isEditingEnabled = $0
            }
            .store(in: &cancellables)
        
        $selectedElements
            .sink { [weak self] in
                self?.tileList.selectedElements = $0
                self?.textList.selectedElements = $0
            }
            .store(in: &cancellables)
        
        switchListButton.onTap = { [weak self] in
            guard let self = self else { return }
            switch self.selectedListType {
            case .text:
                self.selectedListType = .tiles
            case .tiles:
                self.selectedListType = .text
            
            }
        }
        
        topToolbar.onFilterButtonTap = { [weak self] in
            self?.onFilterButtonTap?()
        }
        
        topToolbar.onSelectButtonTap = { [weak self] in
            self?.isEditingEnabled.toggle()
        }
        
        tileList.onTapOnTile = { [weak self] in
            self?.tappedElement = $0
        }
        
        tileList.onLongPressOnTile = { [weak self] in
            guard let self = self, !self.isEditingEnabled else { return }
            self.isEditingEnabled = true
            self.tappedElement = $0
        }
        
        textList.onTapOnTickbox = { [weak self] in
            self?.tappedElement = $0
        }
        
        Publishers.CombineLatest3(tileList.$verticalContentOffset, textList.$verticalContentOffset, $selectedListType)
            .map {
                switch $2 {
                case .tiles:
                    return $0
                case .text:
                    return $1
                }
            }
            .map { [unowned self] in $0 + self.topBarHeight }
            .map { min($0, 50.0) / 50.0 }
            .map { min($0, 0.9) }
            .sink { [weak self] in self?.topToolbar.backgroundAlpha = $0 }
            .store(in: &cancellables)
        
        $actionTypes
            .compactMap { [weak self] in self?.contextualButtonsModels(actionTypes: $0) }
            .sink { [weak self] in self?.contextualButtonsOverlay.setup(buttons: $0) }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    func updateTileList(models: [UTXOTileView.Model]) {
        tileList.models = models
    }
    
    func updateTextList(models: [UTXOsWalletTextListViewCell.Model]) {
        textList.models = models
    }
    
    private func updateListComponents(visibleContentType: VisibleContentType) {
        
        let isDataVisible = visibleContentType == .tilesList || visibleContentType == .textList
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.beginFromCurrentState]) {
            self.switchListButton.alpha = isDataVisible ? 1.0 : 0.0
            self.topToolbar.alpha = isDataVisible ? 1.0 : 0.0
            self.loadingView.alpha = visibleContentType == .loadingScreen ? 1.0 : 0.0
            self.placeholderView.alpha = visibleContentType == .placeholder ? 1.0 : 0.0
            self.tileList.alpha = visibleContentType == .tilesList ? 1.0 : 0.0
            self.textList.alpha = visibleContentType == .textList ? 1.0 : 0.0
        }
    }
    
    private func updateListSwitchIcon(selectedListType: ListType) {
        switch selectedListType {
        case .tiles:
            switchListButton.setImage(Theme.shared.images.utxoTextListIcon, for: .normal)
        case .text:
            switchListButton.setImage(Theme.shared.images.utxoTileViewIcon, for: .normal)
        }
    }
    
    // MARK: - Helpers
    
    private func contextualButtonsModels(actionTypes: [ActionType]) -> [ContextualButtonsOverlay.ButtonModel] {
        actionTypes.map { action in
            
            let callback: () -> Void = { [weak self] in
                self?.onActionButtonTap?(action)
            }
            
            switch action {
            case .split:
                return ContextualButtonsOverlay.ButtonModel(text: localized("utxos_wallet.button.actions.split"), image: Theme.shared.images.utxoActionSplit, callback: callback)
            case .join:
                return ContextualButtonsOverlay.ButtonModel(text: localized("utxos_wallet.button.actions.join"), image: Theme.shared.images.utxoActionJoin, callback: callback)
            case .splitJoin:
                return ContextualButtonsOverlay.ButtonModel(text: localized("utxos_wallet.button.actions.join_split"), image: Theme.shared.images.utxoActionJoinSplit, callback: callback)
            }
        }
    }
}
