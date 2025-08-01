//  TransactionFeesManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 25/05/2022
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

import Foundation

final class TransactionFeesManager {
    enum Status {
        case calculating
        case data(FeeData)
        case dataUnavailable
    }

    struct FeeData {
        let feePerGram: MicroTari
        let fee: MicroTari
    }

    enum InternalError: Error {
        case unexpectedBlockCount
    }

    // MARK: - Constants

    private let timeout: TimeInterval = 3.0
    private let rawMaxAmountBuffer: UInt64 = 2000

    // MARK: - Properties

    var amount: MicroTari = MicroTari() {
        didSet { handleNewAmount() }
    }

    @Published private(set) var feesStatus: Status = .calculating
    @Published private(set) var lastError: Error?

    private(set) var feeData: FeeData?
    private var feePerGram: MicroTari?

    // MARK: - Initialisers

    init() {
        updateData()
    }

    // MARK: - Actions

    private func updateData() {
        fetchFeesPerGram { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(feePerGram):
                self.feePerGram = feePerGram
                self.updateFee(feePerGram: feePerGram)
            case let .failure(error):
                self.lastError = error
                self.feesStatus = .dataUnavailable
            }
        }
    }

    private func updateFee(feePerGram: MicroTari) {
        do {
            let fee = try calculateFee(amount: amount, feePerGram: feePerGram)
            let feeData = FeeData(feePerGram: feePerGram, fee: fee)
            self.feeData = feeData
            feesStatus = .data(feeData)
        } catch {
            lastError = error
            self.feesStatus = .dataUnavailable
        }
    }

    private func handleNewAmount() {
        guard let feePerGram else {
            updateData()
            return
        }
        updateFee(feePerGram: feePerGram)
    }

    private func fetchFeesPerGram(result: @escaping (Result<MicroTari, Error>) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }

            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()

            var response: MicroTari?

            DispatchQueue.global().async {
                response = try? self.calculateFeesPerGram()
                dispatchGroup.leave()
            }
            _ = dispatchGroup.wait(timeout: .now() + self.timeout)

            result(.success(response ?? TariConstants.defaultFeePerGram))
        }
    }

    private func calculateFeesPerGram() throws -> MicroTari {
        let stats = try Tari.mainWallet.fees.feePerGramStats(count: 3)
        let feePerGram = try stats.minFeePerGram()
        return MicroTari(max(1, feePerGram))
    }

    private func calculateFee(amount: MicroTari, feePerGram: MicroTari) throws -> MicroTari {
        let totalBalance = Tari.shared.wallet(.main).walletBalance.balance.total
        let maxAmountRaw = totalBalance > rawMaxAmountBuffer ? totalBalance - rawMaxAmountBuffer : 0
        let amount = min(amount.rawValue, maxAmountRaw)
        let option = try Tari.mainWallet.fees.estimateFee(amount: amount, feePerGram: feePerGram.rawValue)
        return MicroTari(option)
    }
}
