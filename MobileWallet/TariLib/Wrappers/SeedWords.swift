//  SeedWords.swift

/*
    Package MobileWallet
    Created by David Main on 6/11/20
    Using Swift 5.0
    Running on macOS 10.15

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

final class SeedWords {

    enum Error: Swift.Error {
        case invalidSeedWord, invalidSeedPhrase, unexpectedResult, phraseIsTooShort, phraseIsTooLong
    }

    private enum PushWordResult: UInt8 {
        case invalidSeedWord, successfulPush, seedPhraseComplete, invalidSeedPhrase
    }

    // MARK: - Properties

    let pointer: OpaquePointer

    // MARK: - Initializers

    init(walletPointer: OpaquePointer) throws {
        var errorCode: Int32 = -1
        self.pointer = withUnsafeMutablePointer(to: &errorCode) { wallet_get_seed_words(walletPointer, $0) }
        guard errorCode == 0 else { throw WalletErrors.generic(errorCode) }
    }

    init(words: [String]) throws {

        self.pointer = seed_words_create()

        let lastIndex = words.count - 1

        for word in words.enumerated() {

            var errorCode: Int32 = -1

            let rawResult = withUnsafeMutablePointer(to: &errorCode) {
                seed_words_push_word(pointer, word.element, $0)
            }

            guard errorCode == 0 else { throw WalletErrors.generic(errorCode) }
            guard let result = PushWordResult(rawValue: rawResult) else { throw Error.unexpectedResult }

            switch result {
            case .invalidSeedWord:
                throw Error.invalidSeedWord
            case .successfulPush:
                guard word.offset < lastIndex else { throw Error.phraseIsTooShort }
            case .seedPhraseComplete:
                guard word.offset == lastIndex else { throw Error.phraseIsTooLong }
            case .invalidSeedPhrase:
                throw Error.invalidSeedPhrase
            }
        }
    }

    // MARK: - Actions

    func count() throws -> UInt32 {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode) { seed_words_get_length(pointer, $0) }
        guard errorCode == 0 else { throw WalletErrors.generic(errorCode) }
        return result
    }

    func element(at position: UInt32) throws -> String {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode) { seed_words_get_at(pointer, position, $0) }
        guard errorCode == 0 else { throw WalletErrors.generic(errorCode) }
        guard let result = result, let seedWord = String(validatingUTF8: result) else { return "" }
        return seedWord
    }

    func allElements() throws -> [String] {
        let seedWordsCount = try count()
        return try (0..<seedWordsCount).map { try self.element(at: $0) }
    }

    // MARK: - Deinitialization

    deinit {
        seed_words_destroy(pointer)
    }
}
