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
        case unconfirmed
    }
    
    enum SortMethod: Int, CaseIterable {
        case amountAscending
        case amountDescending
        case minedHeightAscending
        case minedHeightDescending
    }

    struct UtxoModel {
        let uuid: UUID
        let amount: UInt64
        let amountText: String
        let tileHeight: CGFloat
        let status: UtxoStatus
        let date: String?
        let time: String?
        let commitment: String
        let blockHeight: String?
        let isSelectable: Bool
    }
    
    struct BreakPreviewData {
        let amount: String
        let breakCount: String
        let breakAmount: String
        let fee: String
    }
    
    // MARK: - Constants
    
    private let minTileHeight: CGFloat = 100.0
    private let maxTileHeight: CGFloat = 300.0
    
    // MARK: - Model
    
    @Published var sortMethod: SortMethod = .amountDescending
    
    @Published private(set) var utxoModels: [UtxoModel] = []
    @Published private(set) var isLoadingData: Bool = false
    @Published private(set) var selectedIDs: Set<UUID> = []
    @Published private(set) var utxoDetails: UtxoModel?
    @Published private(set) var errorMessage: MessageModel?
    
    // MARK: - Properties
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
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
        
        guard let model = utxoModels.first(where: { $0.uuid == elementID }), model.status == .mined else { return }
        
        guard selectedIDs.contains(elementID) else {
            selectedIDs.update(with: elementID)
            return
        }
        
        selectedIDs.remove(elementID)
    }
    
    func deselectAllElements() {
        selectedIDs = []
    }
    
    func breakCoinPreview(breakCount: Int, elementID: UUID) -> BreakPreviewData? {
        guard let model = utxoModels.first(where: { $0.uuid == elementID }) else { return nil }
        return breakCoinPreview(breakCount: breakCount, models: [model])
    }
    
    func breakCoinPreviewForSelectedElements(breakCount: Int) -> BreakPreviewData? {
        let models = utxoModels.filter { self.selectedIDs.contains($0.uuid) }
        return breakCoinPreview(breakCount: breakCount, models: models)
    }
    
    private func breakCoinPreview(breakCount: Int, models: [UtxoModel]) -> BreakPreviewData? {
        
        guard let wallet = TariLib.shared.tariWallet else {
            return nil
        }
        
        let amount = models
            .map(\.amount)
            .reduce(0, +)
        
        let commitments = models.map(\.commitment)
        
        do {
            let result = try wallet.previewCoinSplit(commitments: commitments, splitsCount: UInt(breakCount), feePerGram: Wallet.defaultFeePerGram.rawValue)
            let breakAmount = (amount - result.fee) / UInt64(breakCount)
            
            let amountText = MicroTari(amount).formattedPrecise
            let breakAmountText = MicroTari(breakAmount).formattedPrecise
            let feeText = MicroTari(result.fee).formattedPrecise
            
            return BreakPreviewData(amount: amountText, breakCount: "\(breakCount)", breakAmount: breakAmountText, fee: feeText)
            
        } catch {
            return nil
        }
    }
    
    func performBreakAction(breakCount: Int, elementID: UUID) {
        guard let model = utxoModels.first(where: { $0.uuid == elementID }) else {
            errorMessage = ErrorMessageManager.errorModel(forError: nil)
            return
        }
        performBreakAction(breakCount: breakCount, models: [model])
    }
    
    func performBreakActionForSelectedElements(breakCount: Int) {
        let models = utxoModels.filter { self.selectedIDs.contains($0.uuid) }
        performBreakAction(breakCount: breakCount, models: models)
    }
    
    private func performBreakAction(breakCount: Int, models: [UtxoModel]) {
        
        guard let wallet = TariLib.shared.tariWallet else {
            errorMessage = ErrorMessageManager.errorModel(forError: nil)
            return
        }
        
        let commitments = models.map(\.commitment)
        
        do {
            _ = try wallet.coinSplit(commitments: commitments, splitsCount: UInt(breakCount), feePerGram: Wallet.defaultFeePerGram.rawValue)
        } catch {
            errorMessage = ErrorMessageManager.errorModel(forError: error)
        }
    }
    
    func combineCoinsFeePreview() -> String? {
        
        guard let wallet = TariLib.shared.tariWallet else {
            return nil
        }
        
        let commitments = utxoModels
            .filter { self.selectedIDs.contains($0.uuid) }
            .map(\.commitment)
        
        do {
            let result = try wallet.previewCoinsJoin(commitments: commitments, feePerGram: Wallet.defaultFeePerGram.rawValue)
            return MicroTari(result.fee).formattedPrecise
        } catch {
            return nil
        }
    }
    
    func performCombineAction() {
        
        guard let wallet = TariLib.shared.tariWallet else {
            errorMessage = ErrorMessageManager.errorModel(forError: nil)
            return
        }
        
        let commitments = utxoModels
            .filter { self.selectedIDs.contains($0.uuid) }
            .map(\.commitment)
        
        do {
            _ = try wallet.coinsJoin(commitments: commitments, feePerGram: Wallet.defaultFeePerGram.rawValue)
        } catch {
            errorMessage = ErrorMessageManager.errorModel(forError: error)
        }
    }
    
    func reloadData() {
        fetchUTXOs(sortMethod: sortMethod)
    }
    
    func requestDetails(elementID: UUID) {
        utxoDetails = utxoModels.first { $0.uuid == elementID }
    }
    
    // MARK: - Actions
    
    private func fetchUTXOs(sortMethod: SortMethod) {
        
        guard let wallet = TariLib.shared.tariWallet else {
            errorMessage = ErrorMessageManager.errorModel(forError: nil)
            return
        }
        
        isLoadingData = true
        
        do {
            let utxosData = try wallet.allUtxos()
                .reduce(into: UTXOsData()) { result, model in
                    guard let status = FFIUtxoStatus(rawValue: model.status)?.walletUtxoStatus else { return }
                    
                    result.minAmount = min(model.value, result.minAmount)
                    result.maxAmount = max(model.value, result.maxAmount)
                    result.data.append((model: model, status: status))
                }
            
            guard !utxosData.data.isEmpty else {
                isLoadingData = false
                return
            }
            
            let minAmount = utxosData.minAmount
            let heightScale: CGFloat
            
            if utxosData.minAmount == utxosData.maxAmount {
                heightScale = 1.0
            } else {
                let amountDiff = utxosData.maxAmount - utxosData.minAmount
                let heightDiff = maxTileHeight - minTileHeight
                heightScale = heightDiff / CGFloat(amountDiff)
            }
            
            utxoModels = utxosData.data
                .sorted {
                    switch sortMethod {
                    case .amountAscending:
                        return $0.model.value < $1.model.value
                    case .amountDescending:
                        return $0.model.value > $1.model.value
                    case .minedHeightAscending:
                        return $0.model.mined_height < $1.model.mined_height
                    case .minedHeightDescending:
                        return $0.model.mined_height > $1.model.mined_height
                    }
                }
                .compactMap { [weak self] in
                    guard let self = self else { return nil }
                    
                    let tileHeight = CGFloat($0.model.value - minAmount) * heightScale + minTileHeight
                    let timestamp = Date(timeIntervalSince1970: TimeInterval($0.model.mined_timestamp) / 1000.0)
                    let date = timestamp > Date(timeIntervalSince1970: 0) ? self.dateFormatter.string(from: timestamp) : nil
                    let time = timestamp > Date(timeIntervalSince1970: 0) ? self.timeFormatter.string(from: timestamp) : nil
                    let blockHeight = $0.model.mined_height > 0 ? "\($0.model.mined_height)" : nil
                    return UtxoModel(
                        uuid: UUID(),
                        amount: $0.model.value,
                        amountText: MicroTari($0.model.value).formattedPrecise,
                        tileHeight: tileHeight,
                        status: $0.status,
                        date: date,
                        time: time,
                        commitment: $0.model.commitment.string,
                        blockHeight: blockHeight,
                        isSelectable: $0.status == .mined
                    )
                }
            
            isLoadingData = false
        } catch {
            errorMessage = ErrorMessageManager.errorModel(forError: error)
        }
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
        case .unconfirmed:
            return localized("utxos_wallet.tile.label.state.unconfirmed")
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .mined:
            return Theme.shared.images.utxoTick
        case .unconfirmed:
            return Theme.shared.images.utxoStatusHourglass
        }
    }
    
    var color: UIColor? {
        switch self {
        case .mined:
            return .tari.system.green
        case .unconfirmed:
            return .tari.system.orange
        }
    }
}

private enum FFIUtxoStatus: UInt8 {
    case unspend
    case spent
    case encumberedToBeReceived
    case encumberedToBeSpent
    case invalid
    case cancelledInbound
    case unspentMinedUnconfirmed
    case shortTermEncumberedToBeReceived
    case shortTermEncumberedToBeSpent
    case spentMinedUnconfirmed
    case abandonedCoinbase
    case notStored
}

extension FFIUtxoStatus {
    
    var walletUtxoStatus: UTXOsWalletModel.UtxoStatus? {
        switch self {
        case .unspend:
            return .mined
        case .encumberedToBeReceived, .unspentMinedUnconfirmed:
            return .unconfirmed
        default:
            return nil
        }
    }
    
    var isVisibleUtxoStatus: Bool { walletUtxoStatus != nil }
}

private struct UTXOsData {
    var data: [(model: TariUtxo, status: UTXOsWalletModel.UtxoStatus)] = []
    var maxAmount: UInt64 = 0
    var minAmount: UInt64 = .max
}
