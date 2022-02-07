//  ErrorMessageManagerTests.swift
	
/*
	Package UnitTests
	Created by Adrian Truszczynski on 01/02/2022
	Using Swift 5.0
	Running on macOS 12.1

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

import XCTest
@testable import Tari_Aurora

private struct DummyError: Error {
    let code: Int
}

final class ErrorMessageManagerTests: XCTestCase {
    
    func testCustomMessageForValidError() {
        
        let errorWithCustomMessage = WalletError.invalidPassphrase
        let expectedMessage = localized("error.wallet.428") + "\n" + localized("error.code.prefix") + " " + errorWithCustomMessage.signature
        
        let message = ErrorMessageManager.errorMessage(forError: errorWithCustomMessage)
        
        XCTAssertEqual(message, expectedMessage)
    }
    
    func testGenericMessageForValidError() {
        
        let errorWithGenericMessage = WalletError(code: 42)
        let expectedMessage = localized("error.generic.description") + "\n" + localized("error.code.prefix") + " " + errorWithGenericMessage.signature
        
        let message = ErrorMessageManager.errorMessage(forError: errorWithGenericMessage)
        
        XCTAssertEqual(message, expectedMessage)
    }
    
    func testMessageForInvalidError() {
        
        let error = DummyError(code: 42)
        let expectedMessage = localized("error.generic.description")
        
        let message = ErrorMessageManager.errorMessage(forError: error)
        
        XCTAssertEqual(message, expectedMessage)
    }
    
    func testMessageForNil() {
        
        let expectedMessage = localized("error.generic.description")
        
        let message = ErrorMessageManager.errorMessage(forError: nil)
        
        XCTAssertEqual(message, expectedMessage)
    }
    
    func testCustomErrorModelForValidError() {
        
        let errorWithCustomMessage = WalletError.invalidPassphrase
        
        let expectedTitle = localized("error.generic.title")
        let expectedMessage = localized("error.wallet.428") + "\n" + localized("error.code.prefix") + " " + errorWithCustomMessage.signature
        
        let model = ErrorMessageManager.errorModel(forError: errorWithCustomMessage)
        
        XCTAssertEqual(model.title, expectedTitle)
        XCTAssertEqual(model.message, expectedMessage)
    }
    
    func testGenericErrorModelForValidError() {
        
        let errorWithGenericMessage = WalletError(code: 42)
        
        let expectedTitle = localized("error.generic.title")
        let expectedMessage = localized("error.generic.description") + "\n" + localized("error.code.prefix") + " " + errorWithGenericMessage.signature
        
        let model = ErrorMessageManager.errorModel(forError: errorWithGenericMessage)
        
        XCTAssertEqual(model.title, expectedTitle)
        XCTAssertEqual(model.message, expectedMessage)
    }
    
    func testErrorModelForInvalidError() {
        
        let error = DummyError(code: 42)
        
        let expectedTitle = localized("error.generic.title")
        let expectedMessage = localized("error.generic.description")
        
        let model = ErrorMessageManager.errorModel(forError: error)
        
        XCTAssertEqual(model.title, expectedTitle)
        XCTAssertEqual(model.message, expectedMessage)
    }
    
    func testErrorModelForNil() {
        
        let expectedTitle = localized("error.generic.title")
        let expectedMessage = localized("error.generic.description")
        
        let model = ErrorMessageManager.errorModel(forError: nil)
        
        XCTAssertEqual(model.title, expectedTitle)
        XCTAssertEqual(model.message, expectedMessage)
    }
    
    func testErrorModelForSeedWordsError() {
        
        let seedWordsError = SeedWords.Error.invalidSeedPhrase
        
        let expectedTitle = localized("restore_from_seed_words.error.title")
        let expectedMessage = localized("restore_from_seed_words.error.description.invalid_seed_word") + "\n" + localized("error.code.prefix") + " " + seedWordsError.signature
        
        let model = ErrorMessageManager.errorModel(forError: seedWordsError)
        
        XCTAssertEqual(model.title, expectedTitle)
        XCTAssertEqual(model.message, expectedMessage)
    }
}
