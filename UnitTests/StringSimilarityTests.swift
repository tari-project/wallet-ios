//  StringSimilarityTests.swift
	
/*
	Package UnitTests
	Created by Adrian Truszczyński on 22/01/2024
	Using Swift 5.0
	Running on macOS 14.2

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

final class StringSimilarityTests: XCTestCase {

    func testSameTexts() {

        let firstText = "123xxxabc"
        let secondText = "123xxxabc"
        let minSameCharacters = 3
        let usedPrefixSuffixCharacters = 3

        let result = firstText.isSimilar(to: secondText, minSameCharacters: minSameCharacters, usedPrefixSuffixCharacters: usedPrefixSuffixCharacters)

        XCTAssertFalse(result)
    }

    func testSimilarTexts() {

        let firstText = "123xxxabc"
        let secondText = "123xxxdef"
        let minSameCharacters = 3
        let usedPrefixSuffixCharacters = 3

        let result = firstText.isSimilar(to: secondText, minSameCharacters: minSameCharacters, usedPrefixSuffixCharacters: usedPrefixSuffixCharacters)

        XCTAssertTrue(result)
    }

    func testDifferentTexts() {

        let firstText = "123xxxabc"
        let secondText = "a23xxxdef"
        let minSameCharacters = 3
        let usedPrefixSuffixCharacters = 3

        let result = firstText.isSimilar(to: secondText, minSameCharacters: minSameCharacters, usedPrefixSuffixCharacters: usedPrefixSuffixCharacters)

        XCTAssertFalse(result)
    }

    func testTextsWithDifferentLenghts() {

        let firstText = "123xxxabc"
        let secondText = "123xxxxdef"
        let minSameCharacters = 3
        let usedPrefixSuffixCharacters = 3

        let result = firstText.isSimilar(to: secondText, minSameCharacters: minSameCharacters, usedPrefixSuffixCharacters: usedPrefixSuffixCharacters)

        XCTAssertFalse(result)
    }

    func testTextsWithZeroSameCharacters() {

        let firstText = "123xxxabc"
        let secondText = "123xxxdef"
        let minSameCharacters = 0
        let usedPrefixSuffixCharacters = 3

        let result = firstText.isSimilar(to: secondText, minSameCharacters: minSameCharacters, usedPrefixSuffixCharacters: usedPrefixSuffixCharacters)

        XCTAssertTrue(result)
    }

    func testEmptyString() {

        let firstText = ""
        let secondText = "123xxxdef"
        let minSameCharacters = 3
        let usedPrefixSuffixCharacters = 3

        let result = firstText.isSimilar(to: secondText, minSameCharacters: minSameCharacters, usedPrefixSuffixCharacters: usedPrefixSuffixCharacters)

        XCTAssertFalse(result)
    }

    func testEmptyStrings() {

        let firstText = ""
        let secondText = ""
        let minSameCharacters = 3
        let usedPrefixSuffixCharacters = 3

        let result = firstText.isSimilar(to: secondText, minSameCharacters: minSameCharacters, usedPrefixSuffixCharacters: usedPrefixSuffixCharacters)

        XCTAssertFalse(result)
    }

    func testTooShortText() {

        let firstText = "123bc"
        let secondText = "123xxxdef"
        let minSameCharacters = 3
        let usedPrefixSuffixCharacters = 3

        let result = firstText.isSimilar(to: secondText, minSameCharacters: minSameCharacters, usedPrefixSuffixCharacters: usedPrefixSuffixCharacters)

        XCTAssertFalse(result)
    }

    func testTooShortTexts() {

        let firstText = "123bc"
        let secondText = "123ef"
        let minSameCharacters = 3
        let usedPrefixSuffixCharacters = 3

        let result = firstText.isSimilar(to: secondText, minSameCharacters: minSameCharacters, usedPrefixSuffixCharacters: usedPrefixSuffixCharacters)

        XCTAssertFalse(result)
    }
}
