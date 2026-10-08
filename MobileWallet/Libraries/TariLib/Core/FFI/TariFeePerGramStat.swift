//  TariFeePerGramStat.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 23/05/2022
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

// As of libminotari_wallet_ffi v6.1.0, `wallet_get_fee_per_gram_stats` returns a pointer to
// the opaque collection type `TariFeePerGramStats` (plural), not a single `TariFeePerGramStat`.
// `TariFeePerGramStat` wraps that collection pointer and walks it (via `fee_per_gram_stats_get_at`)
// to compute genuine min/avg/max reductions across every entry, since `minFeePerGram()` /
// `avgFeePerGram()` / `maxFeePerGram()` are consumed by a single call site
// (`TransactionFeesManager.calculateFeesPerGram()`) that wants exactly that reduction, not a single
// arbitrary entry.
final class TariFeePerGramStat {

    // MARK: - Properties

    var count: UInt32 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = fee_per_gram_stats_get_length(pointer, errorCodePointer)
            try checkError(code: errorCode)
            return result
        }
    }

    let pointer: OpaquePointer

    // MARK: - Initialisers

    init(walletPointer: OpaquePointer, count: UInt32) throws {
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)

        let pointer = wallet_get_fee_per_gram_stats(walletPointer, count, errorCodePointer)

        guard errorCode == 0 else { throw WalletError(code: errorCode) }
        guard let pointer else { throw WalletError.unknown }
        self.pointer = pointer
    }

    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    // MARK: - Actions

    func minFeePerGram() throws -> UInt64 {
        let values = try allEntryValues(valueForEntry: fee_per_gram_stat_get_min_fee_per_gram)
        return values.min() ?? 0
    }

    func avgFeePerGram() throws -> UInt64 {
        let values = try allEntryValues(valueForEntry: fee_per_gram_stat_get_avg_fee_per_gram)
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / UInt64(values.count)
    }

    func maxFeePerGram() throws -> UInt64 {
        let values = try allEntryValues(valueForEntry: fee_per_gram_stat_get_max_fee_per_gram)
        return values.max() ?? 0
    }

    // MARK: - Deinitialisers

    deinit {
        fee_per_gram_stats_destroy(pointer)
    }
}

private extension TariFeePerGramStat {

    func checkError(code: Int32) throws {
        guard code == 0 else { throw WalletError(code: code) }
    }

    // Walks every entry of the `TariFeePerGramStats` collection, extracting a value from each
    // `TariFeePerGramStat` entry via `valueForEntry`, and always destroying the entry pointer
    // (via `fee_per_gram_stat_destroy`) before moving to the next one.
    func allEntryValues(valueForEntry: (OpaquePointer, UnsafeMutablePointer<Int32>) -> UInt64) throws -> [UInt64] {
        let entriesCount = try count
        var values: [UInt64] = []
        values.reserveCapacity(Int(entriesCount))

        for index in 0..<entriesCount {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let entryPointer = fee_per_gram_stats_get_at(pointer, index, errorCodePointer)

            guard errorCode == 0, let entryPointer else { throw WalletError(code: errorCode) }
            defer { fee_per_gram_stat_destroy(entryPointer) }

            var valueErrorCode: Int32 = -1
            let valueErrorCodePointer = PointerHandler.pointer(for: &valueErrorCode)
            let value = valueForEntry(entryPointer, valueErrorCodePointer)
            try checkError(code: valueErrorCode)

            values.append(value)
        }

        return values
    }
}
