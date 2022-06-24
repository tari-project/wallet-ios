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
import Combine

final class UTXOsWalletModel {
    
    enum UtxoStatus {
        case mined
    }
    
    enum SortMethod {
        case amountAscending
        case amountDescending
        case minedHeightAscending
        case minedHeightDescending
    }

    struct UtxoModel {
        let uuid: UUID
        let amountText: String
        let tileHeight: CGFloat
        let status: UtxoStatus
        let hash: String
    }
    
    // MARK: - Constants
    
    private let minTileHeight: CGFloat = 100.0
    private let maxTileHeight: CGFloat = 300.0
    
    // MARK: - Model
    
    @Published var sortMethod: SortMethod = .amountDescending
    
    @Published private(set) var utxoModels: [UtxoModel] = []
    @Published private(set) var selectedIDs: Set<UUID> = []
    @Published private(set) var errorMessage: MessageModel?
    
    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialisers
    
    init() {
        setupCallbacks()
    }
    
    // MARK: - Setups
    
    private func setupCallbacks() {
        
        $sortMethod
            .removeDuplicates()
            .sink { [weak self] in self?.fetchUTXOs(sortMethod: $0) }
            .store(in: &cancellables)
        
    }
    
    // MARK: - Model Actions
    
    func toogleState(elementID: UUID) {
        
        guard selectedIDs.contains(elementID) else {
            selectedIDs.update(with: elementID)
            return
        }
        
        selectedIDs.remove(elementID)
    }
    
    func deselectAllElements() {
        selectedIDs = []
    }
    
    // MARK: - Actions
    
    private func fetchUTXOs(sortMethod: SortMethod) {
    
        guard let wallet = TariLib.shared.tariWallet else {
            errorMessage = ErrorMessageManager.errorModel(forError: nil)
            return
        }
        
        do {
            let utxos = try fetchAllUTXOs(wallet: wallet)
            let heights = calculateHeights(rawAmounts: utxos.map(\.value))
            
            utxoModels = zip(utxos, heights)
                .compactMap {
                    guard let commitment = $0.commitment.string else { return nil }
                    return UtxoModel(uuid: UUID(), amountText: MicroTari($0.value).formattedPrecise, tileHeight: $1, status: .mined, hash: commitment)
                }
        } catch {
            errorMessage = ErrorMessageManager.errorModel(forError: error)
        }
    }
    
    private func fetchAllUTXOs(wallet: Wallet) throws -> [TariUtxo] {
        
        let batchSize: UInt = 50
        
        var allUTXOs = [TariUtxo]()
        var batch = [TariUtxo]()
        var page: UInt = 0
        
        repeat {
            
            batch = try wallet.utxos(page: page * batchSize, pageSize: batchSize, sortMethod: sortMethod.ffiSortMethod, dustTreshold: 0)
            
            allUTXOs += batch
            page += 1
            
        } while !batch.isEmpty
        
        return allUTXOs
    }
    
    // MARK: - Helpers
    
    private func calculateHeights(rawAmounts: [UInt64]) -> [CGFloat] {
        
        let rawAmounts = rawAmounts.map { CGFloat($0) }
        
        guard let minAmount = rawAmounts.min(), let maxAmount = rawAmounts.max(), minAmount < maxAmount else { return rawAmounts.map { _ in maxTileHeight }}
        
        let amountDiff = maxAmount - minAmount
        let heightDiff = maxTileHeight - minTileHeight
        let scale = heightDiff / amountDiff
        
        return rawAmounts.map { ($0 - minAmount) * scale + minTileHeight }
    }
}

extension UTXOsWalletModel.UtxoModel {
    var amountWithCurrency: String { "\(amountText) \(NetworkManager.shared.selectedNetwork.tickerSymbol)" }
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

private extension UTXOsWalletModel.SortMethod {
    
    var ffiSortMethod: TariUtxoSort {
        switch self {
        case .amountAscending:
            return TariUtxoSort(rawValue: 0)
        case .amountDescending:
            return TariUtxoSort(rawValue: 1)
        case .minedHeightAscending:
            return TariUtxoSort(rawValue: 2)
        case .minedHeightDescending:
            return TariUtxoSort(rawValue: 3)
        }
    }
}
