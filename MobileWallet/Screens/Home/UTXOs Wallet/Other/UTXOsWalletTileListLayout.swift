//  UTXOsWalletTileListLayout.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 23/06/2022
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

final class UTXOsWalletTileListLayout: UICollectionViewLayout {

    private struct ColumnData {
        let columnIndex: Int
        var totalHeight: CGFloat
        var attributes: [UICollectionViewLayoutAttributes]
    }

    // MARK: - Constants

    private let horizontalMargin: CGFloat = 30.0
    private let verticalMargin: CGFloat = 12.0
    private let internalMargin: CGFloat = 12.0

    // MARK: - Properties

    var columnsCount = 0
    var onCheckHeightAtIndex: ((Int) -> CGFloat)?

    private var allAttributes: [UICollectionViewLayoutAttributes] = []
    private var totalHeight: CGFloat = 0

    // MARK: - Actions

    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else { return .zero }
        return CGSize(width: collectionView.bounds.width, height: totalHeight)
    }

    override func prepare() {
        super.prepare()

        guard let collectionView = collectionView, collectionView.numberOfSections > 0 else { return }

        let columnWidth = (collectionViewContentSize.width - horizontalMargin * 2.0 - internalMargin * CGFloat(columnsCount - 1)) / CGFloat(columnsCount)
        let itemsCount = collectionView.numberOfItems(inSection: 0)
        let initialData = (0..<columnsCount).map { ColumnData(columnIndex: $0, totalHeight: verticalMargin, attributes: []) }

        let data = (0..<itemsCount)
            .reduce(into: initialData) { [weak self] result, index in

                guard let self, let columnIndex = result.min(by: { $0.totalHeight < $1.totalHeight })?.columnIndex, let height = self.onCheckHeightAtIndex?(index) else { return }

                let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: 0))
                attributes.frame = CGRect(
                    x: horizontalMargin + columnWidth * CGFloat(columnIndex) + internalMargin * CGFloat(columnIndex),
                    y: result[columnIndex].totalHeight,
                    width: columnWidth,
                    height: height
                )

                result[columnIndex].totalHeight += height + verticalMargin
                result[columnIndex].attributes.append(attributes)
            }

        allAttributes = data.flatMap { $0.attributes }
        totalHeight = data.map { $0.totalHeight }.max() ?? 0.0
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        allAttributes.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        allAttributes.first { $0.indexPath == indexPath }
    }
}
