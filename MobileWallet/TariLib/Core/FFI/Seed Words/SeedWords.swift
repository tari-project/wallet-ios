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

    enum InternalError: Int, CoreError {
        case invalidSeedWord
        case invalidSeedPhrase
        case unexpectedResult
        case phraseIsTooShort
        case phraseIsTooLong
        
        var code: Int { rawValue }
        var domain: String { "SWE" }
    }

    enum PushWordResult: UInt8 {
        case invalidSeedWord
        case successfulPush
        case seedPhraseComplete
        case invalidSeedPhrase
    }

    // MARK: - Properties
    
    let pointer: OpaquePointer
    
    var count: UInt32 {
        get throws {
            var errorCode: Int32 = -1
            let errorCodePointer = PointerHandler.pointer(for: &errorCode)
            let result = seed_words_get_length(pointer, errorCodePointer)
            guard errorCode == 0 else { throw WalletError(code: errorCode) }
            return result
        }
    }

    // MARK: - Initializers

    init(walletPointer: OpaquePointer) throws {
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = wallet_get_seed_words(walletPointer, errorCodePointer)
        
        guard errorCode == 0, let result = result else { throw WalletError(code: errorCode) }
        pointer = result
    }
    
    init() {
        pointer = seed_words_create()
    }
    
    // MARK: - Actions
    
    func push(word: String) throws -> PushWordResult {
        
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = seed_words_push_word(pointer, word, errorCodePointer)
        
        guard errorCode == 0, let pushResult = PushWordResult(rawValue: result) else { throw WalletError(code: errorCode) }
        return pushResult
    }

    // MARK: - Actions
    
    func word(index: UInt32) throws -> String {
        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = seed_words_get_at(pointer, index, errorCodePointer)
        guard errorCode == 0, let cString = result else { throw WalletError(code: errorCode) }
        return String(cString: cString)
    }

    // MARK: - Deinitialization

    deinit {
        seed_words_destroy(pointer)
    }
}

extension SeedWords {
    
    var all: [String] {
        get throws {
            let count = try count
            return try (0..<count).map { try word(index: $0) }
        }
    }
    
    convenience init(words: [String]) throws {
        self.init()
        let lastIndex = words.count - 1
        
        try words
            .enumerated()
            .forEach {
                let result = try push(word: $0.element)
                try validate(result: result, index: $0.offset, lastIndex: lastIndex)
            }
    }
    
    private func validate(result: PushWordResult, index: Int, lastIndex: Int) throws {
        
        switch result {
        case .invalidSeedWord:
            throw InternalError.invalidSeedWord
        case .successfulPush:
            guard index < lastIndex else { throw InternalError.phraseIsTooShort }
        case .seedPhraseComplete:
            guard index == lastIndex else { throw InternalError.phraseIsTooLong }
        case .invalidSeedPhrase:
            throw InternalError.invalidSeedPhrase
        }
    }
}
