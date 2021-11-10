//  SeedWordsMnemonicWordList.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 10/11/2021
	Using Swift 5.0
	Running on macOS 12.0

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

final class SeedWordsMnemonicWordList {
    
    enum Language: String {
        case english = "English"
        case spanish = "Spanish"
    }
    
    enum Error: Swift.Error {
        case internalError
        case generic(code: Int32)
    }
    
    // MARK: - Properties
    
    private let pointer: OpaquePointer
    
    var seedWords: [String] {
        get throws {
            let length = try listLength
            return try (0..<length).map { try word(index: $0) }
        }
    }
    
    private var listLength: UInt32 {
        get throws {
            var errorCode: Int32 = -1
            let length = withUnsafeMutablePointer(to: &errorCode) {
                seed_words_get_length(pointer, $0)
            }
            
            guard errorCode == 0 else { throw Error.generic(code: errorCode) }
            return length
        }
    }
    
    // MARK: - Initialisators
    
    init?(language: Language) {
        
        var errorCode: Int32 = -1
        
        let result = withUnsafeMutablePointer(to: &errorCode) {
            seed_words_get_mnemonic_word_list_for_language(language.rawValue, $0)
        }
        
        guard let result = result else {
            return nil
        }
        
        pointer = result
    }
    
    // MARK: - Actions
    
    private func word(index: UInt32) throws -> String {
        
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode) {
            seed_words_get_at(pointer, index, $0)
        }
        
        guard errorCode == 0 else { throw Error.generic(code: errorCode) }
        guard let result = result else { throw Error.internalError }
        
        return String(cString: result)
    }
    
    // MARK: - Deinitalisation
    
    deinit {
        seed_words_destroy(pointer)
    }
}

