//  UTXOsWalletModel.swift
	
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

final class UTXOsWalletModel {
    
    enum UtxoStatus {
        case mined
    }

    struct UtxoModel {
        let amountText: String
        let color: UIColor?
        let tileHeight: CGFloat
        let status: UtxoStatus
    }
    
    // MARK: - Constants
    
    private let minTileHeight: CGFloat = 100.0
    private let maxTileHeight: CGFloat = 300.0
    
    // MARK: - Model
    
    @Published private(set) var utxoModels: [UtxoModel] = []
    @Published private(set) var isSortOrderAscending = false
    
    // MARK: - Initialisers
    
    init() {
        generateData()
    }
    
    // MARK: - Actions
    
    func toggleSortOrder() {
        isSortOrderAscending.toggle()
    }
    
    private func generateData() {
        
        let amounts = generateMockedAmounts().sorted { $0.rawValue < $1.rawValue }
        let heights = calculateHeights(fromAmounts: amounts)
        
        utxoModels = zip(amounts, heights)
            .sorted { $0.0.rawValue > $1.0.rawValue }
            .map { UtxoModel(amountText: $0.formattedPrecise, color: generateColor(), tileHeight: $1, status: .mined) }
    }
    
    // MARK: - Helpers
    
    private func generateMockedAmounts() -> [MicroTari] {
        
        let elementsCount = 20
        var amounts = [UInt64(100000)]
        
        amounts += (1...9).map { UInt64($0) }
        
        let elem = (elementsCount - 10) / 2
        let elem2 = (elementsCount - 10) - elem
        
        amounts += (0..<elem)
            .map { _ in UInt64.random(in: 100..<10000) }
            .map { $0 * 1000 }
        
        amounts += (0..<elem2)
            .map { _ in UInt64.random(in: 100...200) }
        
        return amounts.map { MicroTari($0) }
    }
    
    private func generateColor() -> UIColor? {
        let identifier = String.random(length: 32)
        return .tari.purple?.colorVariant(text: identifier)
    }
    
    private func calculateHeights(fromAmounts amounts: [MicroTari]) -> [CGFloat] {
        
        let rawAmounts = amounts.map { CGFloat($0.rawValue) }
        
        guard let minAmount = rawAmounts.min(), let maxAmount = rawAmounts.max() else { return amounts.map { _ in maxTileHeight }}
        
        let amountDiff = maxAmount - minAmount
        let heightDiff = maxTileHeight - minTileHeight
        let scale = heightDiff / amountDiff
        
        return rawAmounts.map { ($0 - minAmount) * scale + minTileHeight }
    }
}

extension UTXOsWalletModel.UtxoStatus {
    
    var name: String {
        switch self {
        case .mined:
            return localized("utxos_wallet.tile.label.state.mined")
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .mined:
            return Theme.shared.images.utxoStatusMined
        }
    }
}
