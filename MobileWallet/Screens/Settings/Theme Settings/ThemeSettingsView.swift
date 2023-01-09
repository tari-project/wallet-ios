//  ThemeSettingsView.swift

/*
	Package MobileWallet
	Created by Browncoat on 18/12/2022
	Using Swift 5.0
	Running on macOS 13.0

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

final class ThemeSettingsView: BaseNavigationContentView {

    struct ViewModel: Identifiable, Hashable {
        let id: UUID
        let image: UIImage?
        let title: String?
    }

    // MARK: - Subviews

    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.register(type: ThemeSettingsCollectionCell.self)
        view.backgroundColor = .clear
        view.alwaysBounceVertical = false
        return view
    }()

    // MARK: - Properties

    var onCellSelected: ((IndexPath) -> Void)?

    private let collectionViewLayout: UICollectionViewCompositionalLayout = {

        let itemFraction: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 0.25 : 0.5

        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(itemFraction), heightDimension: .estimated(44.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Int, ViewModel>?

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
        navigationBar.title = localized("theme_switcher.title")
    }

    private func setupConstraints() {

        addSubview(collectionView)

        let constraints = [
            collectionView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        let dataSource = UICollectionViewDiffableDataSource<Int, ViewModel>(collectionView: collectionView) { collectionView, indexPath, model in
            let cell = collectionView.dequeueReusableCell(type: ThemeSettingsCollectionCell.self, indexPath: indexPath)
            cell.update(image: model.image, title: model.title)
            return cell
        }

        self.dataSource = dataSource

        collectionView.dataSource = dataSource
        collectionView.delegate = self
    }

    // MARK: - Updates

    func select(index: Int) {
        collectionView.selectItem(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .top)
    }

    func update(viewModels: [ViewModel], selectedIndex: Int) {

        var snapshot = NSDiffableDataSourceSnapshot<Int, ViewModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(viewModels)
        dataSource?.apply(snapshot)

        collectionView.selectItem(at: IndexPath.init(row: selectedIndex, section: 0), animated: false, scrollPosition: .bottom)
    }
}

extension ThemeSettingsView: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onCellSelected?(indexPath)
    }
}
