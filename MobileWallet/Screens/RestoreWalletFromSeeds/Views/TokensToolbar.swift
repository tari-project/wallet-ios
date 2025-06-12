//  TokensToolbar.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 04/11/2021
	Using Swift 5.0
	Running on macOS 12.0

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

final class TokensToolbar: DynamicThemeToolbar {

    // MARK: - Subviews

    @View var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: TokensToolbarFlowLayout())
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        return view
    }()

    @View private var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.Poppins.Medium.withSize(16.0)
        return label
    }()

    // MARK: - Properties

    var tokenModels: [TokenViewModel] = [] {
        didSet { reloadData() }
    }

    var text: String? {
        didSet { updateLabel() }
    }

    var onTapOnToken: ((String) -> Void)?

    private var dataSource: UICollectionViewDiffableDataSource<Int, TokenViewModel>?

    // MARK: - Initialisers

    override init() {
        super.init()
        setupViews()
        setupConstraints()
        setupFeedback()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        collectionView.register(type: TokenView.self)
        isTranslucent = true
    }

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        barTintColor = .Background.primary
        label.textColor = .Text.primary
    }

    private func setupConstraints() {

        [collectionView, label].forEach(addSubview)

        let constraints = [
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: 44.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupFeedback() {

        dataSource = UICollectionViewDiffableDataSource<Int, TokenViewModel>(collectionView: collectionView) { collectionView, indexPath, model in
            let cell = collectionView.dequeueReusableCell(type: TokenView.self, indexPath: indexPath)
            cell.text = model.title
            cell.isDeleteIconVisible = false
            return cell
        }

        collectionView.dataSource = dataSource
        collectionView.delegate = self
    }

    // MARK: - Actions

    private func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, TokenViewModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(tokenModels)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }

    private func updateLabel() {

        let isTextVisible = text != nil

        UIView.animate(withDuration: 0.3) {
            self.label.text = self.text
            self.label.alpha = isTextVisible ? 1.0 : 0.0
            self.collectionView.alpha = isTextVisible ? 0.0 : 1.0
        }
    }
}

extension TokensToolbar: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onTapOnToken?(tokenModels[indexPath.row].title)
    }
}

private final class TokensToolbarFlowLayout: UICollectionViewFlowLayout {

    override init() {
        super.init()
        estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        minimumLineSpacing = 5.0
        minimumInteritemSpacing = 5.0
        sectionInset = UIEdgeInsets(top: 0.0, left: 18.0, bottom: 0.0, right: 18.0)
        scrollDirection = .horizontal
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
