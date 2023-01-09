//  AboutView.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 26/05/2022
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

final class AboutView: BaseNavigationContentView {
    
    struct CellModel: Identifiable, Hashable {
        let id: UUID = UUID()
        let icon: UIImage?
        let text: String?
    }
    
    // MARK: - Properties
    
    var cellModels: [CellModel] = [] {
        didSet { updateCells() }
    }
    
    var onTapOnCreativeCommonsButton: (() -> Void)?
    var onSelectRow: ((Int) -> Void)?
    
    // MARK: - Subviews
    
    @View private var tableView: MenuTableView = {
        let view = MenuTableView()
        view.register(type: AboutViewCell.self)
        view.separatorStyle = .none
        return view
    }()
    
    // MARK: - Properties
    
    private var dataSource: UITableViewDiffableDataSource<Int, CellModel>?
    
    // MARK: - Initialisers
    
    override init() {
        super.init()
        setupViews()
        setupCallbacks()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupViews() {
        navigationBar.title = localized("about.title")
    }
    
    func setupCallbacks() {
        
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, model in
            let cell = tableView.dequeueReusableCell(type: AboutViewCell.self, indexPath: indexPath)
            cell.update(icon: model.icon, text: model.text)
            return cell
        }
        
        tableView.dataSource = dataSource
        tableView.delegate = self
    }
    
    private func setupConstraints() {
        
        addSubview(tableView)
        
        let constraints = [
            tableView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - Actions
    
    private func updateCells() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, CellModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(cellModels, toSection: 0)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}

extension AboutView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onSelectRow?(indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = AboutViewHeader()
        headerView.onButtonTap = { [weak self] in
            self?.onTapOnCreativeCommonsButton?()
        }
        return headerView
    }
}
