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
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)

        let result = fee_per_gram_stat_get_min_fee_per_gram(pointer, errorCodePointer)

        try checkError(code: errorCode)
        return result
    }

    func avgFeePerGram() throws -> UInt64 {
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)

        let result = fee_per_gram_stat_get_avg_fee_per_gram(pointer, errorCodePointer)

        try checkError(code: errorCode)
        return result
    }

    func maxFeePerGram() throws -> UInt64 {
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)

        let result = fee_per_gram_stat_get_max_fee_per_gram(pointer, errorCodePointer)

        try checkError(code: errorCode)
        return result
    }

    // MARK: - Deinitialisers

    deinit {
        fee_per_gram_stat_destroy(pointer)
    }
}

private extension TariFeePerGramStat {
    func checkError(code: Int32) throws {
        guard code == 0 else { throw WalletError(code: code) }
    }
}
