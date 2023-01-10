//  UTXOsWalletTileView.swift

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
import Combine

final class UTXOsWalletTileListView: UIView {

    // MARK: - Subviews

    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.alwaysBounceVertical = true
        view.register(type: UTXOTileView.self)
        return view
    }()

    // MARK: - Properties

    @Published var models: [UTXOTileView.Model] = []
    @Published var verticalContentInset: CGFloat = 0.0
    @Published var isEditingEnabled: Bool = false
    @Published var selectedElements: Set<UUID> = []
    @Published private(set) var verticalContentOffset: CGFloat = 0.0

    var onTapOnTile: ((UUID) -> Void)?
    var onLongPressOnTile: ((UUID) -> Void)?

    private let collectionViewLayout: UTXOsWalletTileListLayout = {
        let layout = UTXOsWalletTileListLayout()
        layout.columnsCount = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2
        return layout
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Int, UTXOTileView.Model>?
    private var cancellables = Set<AnyCancellable>()

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

        addSubview(collectionView)

        let constraints = [
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        $models
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.updateTiles(models: $0) }
            .store(in: &cancellables)

        $verticalContentInset
            .map { UIEdgeInsets(top: $0, left: 0.0, bottom: 0.0, right: 0.0) }
            .sink { [weak self] in self?.collectionView.contentInset = $0 }
            .store(in: &cancellables)

        $isEditingEnabled
            .sink { [weak self] in self?.updateTilesState(isEditing: $0) }
            .store(in: &cancellables)

        $selectedElements
            .sink { [weak self] in self?.update(selectedElements: $0) }
            .store(in: &cancellables)

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, model in
            let cell = collectionView.dequeueReusableCell(type: UTXOTileView.self, indexPath: indexPath)

            guard let self = self else { return cell }

            cell.update(model: model)
            cell.update(isSelectable: model.isSelectable, isEditingEnabled: self.isEditingEnabled)
            cell.isTickSelected = self.selectedElements.contains(model.uuid)

            cell.onTap = { [weak self] uuid in
                self?.onTapOnTile?(uuid)
            }

            cell.onLongPress = { [weak self] uuid in
                guard self?.models.first(where: { $0.uuid == uuid })?.isSelectable == true else { return }
                self?.onLongPressOnTile?(uuid)
            }

            return cell
        }

        collectionViewLayout.onCheckHeightAtIndex = { [weak self] in
            self?.models[$0].height ?? 0.0
        }

        collectionView.delegate = self
    }

    // MARK: - Actions

    private func updateTiles(models: [UTXOTileView.Model]) {

        var snapshot = NSDiffableDataSourceSnapshot<Int, UTXOTileView.Model>()

        snapshot.appendSections([0])
        snapshot.appendItems(models)

        dataSource?.apply(snapshot, animatingDifferences: true)
    }

    private func updateTilesState(isEditing: Bool) {

        guard !models.isEmpty else { return }

        collectionView.visibleCells
            .compactMap { $0 as? UTXOTileView }
            .forEach { tile in
                guard let model = models.first(where: { $0.uuid == tile.elementID }) else { return }
                tile.update(isSelectable: model.isSelectable, isEditingEnabled: isEditing)
            }
    }

    private func update(selectedElements: Set<UUID>) {

        guard !models.isEmpty else { return }

        collectionView.visibleCells
            .compactMap { $0 as? UTXOTileView }
            .forEach {
                guard let elementID = $0.elementID else { return }
                $0.isTickSelected = selectedElements.contains(elementID) }
    }
}

extension UTXOsWalletTileListView: UICollectionViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        verticalContentOffset = scrollView.contentOffset.y
    }
}

private extension UTXOTileView {

    func update(isSelectable: Bool, isEditingEnabled: Bool) {
        updateTickBox(isVisible: isSelectable && isEditingEnabled)
        updateBackground(isSemitransparent: !isSelectable && isEditingEnabled)
    }
}
