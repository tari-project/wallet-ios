//  UTXOsWalletTextListView.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 08/06/2022
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

final class UTXOsWalletTextListView: UIView {
    
    // MARK: - Subviews
    
    @View private var tableView: UITableView = {
        let view = UITableView()
        view.separatorColor = .tari.greys.mediumLightGrey
        view.separatorInset = UIEdgeInsets(top: 0.0, left: 30.0, bottom: 0.0, right: 30.0)
        view.register(type: UTXOsWalletTextListViewCell.self)
        return view
    }()
    
    // MARK: - Properties
    
    var models: [UTXOsWalletTextListViewCell.Model] = [] {
        didSet { updateCells(models: models) }
    }
    
    var isEditingEnabled: Bool = false {
        didSet { updateCellsState(isEditing: isEditingEnabled) }
    }
    
    var onTapOnTickbox: ((UUID) -> Void)?
    
    private var selectedIDs: Set<UUID> = []
    private var dataSource: UITableViewDiffableDataSource<Int, UTXOsWalletTextListViewCell.Model>?
    
    // MARK: - Initialisers
    
    init() {
        super.init(frame: .zero)
        setupConstraints()
        setupCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupConstraints() {
        
        addSubview(tableView)
        
        let constraints = [
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupCallbacks() {
        
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, model in
            
            guard let self = self else { return UITableViewCell() }
            
            let cell = tableView.dequeueReusableCell(type: UTXOsWalletTextListViewCell.self, indexPath: indexPath)
            
            cell.update(model: model)
            cell.updateTickBox(isVisible: self.isEditingEnabled, animated: false)
            cell.isTickSelected = self.selectedIDs.contains(model.id)
            
            cell.onTapOnTickbox = {
                self.onTapOnTickbox?($0)
            }
            
            return cell
        }
        
        tableView.dataSource = dataSource
    }
    
    // MARK: - Actions
    
    func update(selectedElements: Set<UUID>) {
        
        selectedIDs = selectedElements
        
        tableView.visibleCells
            .compactMap { $0 as? UTXOsWalletTextListViewCell }
            .forEach {
                guard let elementID = $0.elementID else { return }
                $0.isTickSelected = selectedIDs.contains(elementID)
            }
    }
    
    private func updateCells(models: [UTXOsWalletTextListViewCell.Model]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, UTXOsWalletTextListViewCell.Model>()
        snapshot.appendSections([0])
        snapshot.appendItems(models, toSection: 0)
        dataSource?.apply(snapshot)
    }
    
    private func updateCellsState(isEditing: Bool) {
        tableView.visibleCells
            .compactMap { $0 as? UTXOsWalletTextListViewCell }
            .forEach { $0.updateTickBox(isVisible: isEditing, animated: true) }
    }
}
