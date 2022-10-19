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

final class TransactionFeesManager {
    
    enum NetworkTraffic {
        case low
        case medium
        case high
        case unknown
    }
    
    enum Status {
        case calculating
        case data(FeesData)
        case dataUnavailable
    }
    
    struct FeeOptions {
        let slow: MicroTari
        let medium: MicroTari
        let fast: MicroTari
    }
    
    struct FeesData {
        let networkTraffic: NetworkTraffic
        let feesPerGram: FeeOptions
        let fees: FeeOptions
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
    
    private(set) var feesData: FeesData?
    private var networkTraffic: NetworkTraffic?
    private var feesPerGram: FeeOptions?
    
    // MARK: - Initialisers
    
    init() {
        updateData()
    }
    
    // MARK: - Actions
    
    private func updateData() {
        
        fetchTrafficAndFeesPerGram { [weak self] result in
            
            guard let self = self else { return }
            
            switch result {
            case let .success((networkTraffic, feesPerGram)):
                self.networkTraffic = networkTraffic
                self.feesPerGram = feesPerGram
                self.updateFees(networkTraffic: networkTraffic, feesPerGram: feesPerGram)
            case let .failure(error):
                self.lastError = error
                self.feesStatus = .dataUnavailable
            }
        }
    }
    
    private func updateFees(networkTraffic: NetworkTraffic, feesPerGram: FeeOptions) {
        
        do {
            let fees = try calculateFees(amount: amount, feesPerGram: feesPerGram)
            let feesData = FeesData(networkTraffic: networkTraffic, feesPerGram: feesPerGram, fees: fees)
            self.feesData = feesData
            feesStatus = .data(feesData)
        } catch {
            lastError = error
            self.feesStatus = .dataUnavailable
        }
    }
    
    private func handleNewAmount() {
        guard let networkTraffic = networkTraffic, let feesPerGram = feesPerGram else {
            updateData()
            return
        }
        updateFees(networkTraffic: networkTraffic, feesPerGram: feesPerGram)
    }
    
    private func fetchTrafficAndFeesPerGram(result: @escaping (Result<(NetworkTraffic, FeeOptions), Error>) -> Void) {
        
        DispatchQueue.global().async { [weak self] in
            
            guard let self = self else { return }
            
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            
            var response: (NetworkTraffic, FeeOptions)?
            
            DispatchQueue.global().async {
                response = try? self.calculateTrafficAndFeesPerGram()
                dispatchGroup.leave()
            }
            
            _ = dispatchGroup.wait(timeout: .now() + self.timeout)
            
            let finalResponse = response ?? (.unknown, FeeOptions(slow: Tari.defaultFeePerGram, medium: Tari.defaultFeePerGram, fast: Tari.defaultFeePerGram))
            result(.success(finalResponse))
        }
    }
    
    private func calculateTrafficAndFeesPerGram() throws -> (NetworkTraffic, FeeOptions) {
        
        let stats = try Tari.shared.fees.feePerGramStats(count: 3)
        let blocksCount = try stats.count
        let elementsCount = min(blocksCount, 3)
        let elements = try (0..<elementsCount).map { try stats.element(at: $0) }
        
        let traffic: NetworkTraffic
        let slowOption: UInt64
        let mediumOption: UInt64
        let fastOption: UInt64
        
        switch blocksCount {
        case 1:
            traffic = .low
            slowOption = try stats.minFeePerGram(feeParGramStatPointer: elements[0])
            mediumOption = try stats.avgFeePerGram(feeParGramStatPointer: elements[0])
            fastOption = try stats.maxFeePerGram(feeParGramStatPointer: elements[0])
        case 2:
            traffic = .medium
            slowOption = try stats.avgFeePerGram(feeParGramStatPointer: elements[1])
            mediumOption = try stats.minFeePerGram(feeParGramStatPointer: elements[0])
            fastOption = try stats.maxFeePerGram(feeParGramStatPointer: elements[0])
        case 3...UInt32.max:
            traffic = .high
            slowOption = try stats.avgFeePerGram(feeParGramStatPointer: elements[2])
            mediumOption = try stats.avgFeePerGram(feeParGramStatPointer: elements[1])
            fastOption = try stats.maxFeePerGram(feeParGramStatPointer: elements[0])
        default:
            throw InternalError.unexpectedBlockCount
        }
        
        let feesPerGram = FeeOptions(slow: MicroTari(slowOption), medium: MicroTari(mediumOption), fast: MicroTari(fastOption))
        
        return (traffic, feesPerGram)
    }
    
    private func calculateFees(amount: MicroTari, feesPerGram: FeeOptions) throws -> FeeOptions {
        
        let totalBalance = Tari.shared.walletBalance.balance.total
        let maxAmountRaw = totalBalance > rawMaxAmountBuffer ? totalBalance - rawMaxAmountBuffer : 0
        let amount = min(amount.rawValue, maxAmountRaw)
        
        let slowOption = try Tari.shared.fees.estimateFee(amount: amount, feePerGram: feesPerGram.slow.rawValue)
        let mediumOption = try Tari.shared.fees.estimateFee(amount: amount, feePerGram: feesPerGram.medium.rawValue)
        let fastOption = try Tari.shared.fees.estimateFee(amount: amount, feePerGram: feesPerGram.fast.rawValue)
        
        return FeeOptions(slow: MicroTari(slowOption), medium: MicroTari(mediumOption), fast: MicroTari(fastOption))
    }
}
