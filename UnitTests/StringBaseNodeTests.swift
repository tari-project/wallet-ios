//  StringBaseNodeTests.swift
	
/*
	Package UnitTests
	Created by Adrian Truszczyński on 15/04/2024
	Using Swift 5.0
	Running on macOS 14.4

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

@testable import Tari_Aurora
import XCTest

final class StringBaseNodeTests: XCTestCase {

    func testValidHex() {

        let hex: String = "1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff"
        let address: String? = nil

        let result = String.isBaseNodeAddress(hex: hex, address: address)

        XCTAssertTrue(result)
    }

    func testValidHexAndOnionAddress() {

        let hex: String = "1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff"
        let address: String? = "/onion3/abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrst:12345"

        let result = String.isBaseNodeAddress(hex: hex, address: address)

        XCTAssertTrue(result)
    }

    func testValidHexAndIP4Address() {

        let hex: String = "1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff"
        let address: String? = "/ip4/11.22.33.44/tcp/12345"

        let result = String.isBaseNodeAddress(hex: hex, address: address)

        XCTAssertTrue(result)
    }

    func testInvalidHex() {

        let hex: String = "x111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff"
        let address: String? = nil

        let result = String.isBaseNodeAddress(hex: hex, address: address)

        XCTAssertFalse(result)
    }

    func testTooShortHex() {

        let hex: String = "111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff"
        let address: String? = nil

        let result = String.isBaseNodeAddress(hex: hex, address: address)

        XCTAssertFalse(result)
    }

    func testTooLongHex() {

        let hex: String = "01111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff"
        let address: String? = nil

        let result = String.isBaseNodeAddress(hex: hex, address: address)

        XCTAssertFalse(result)
    }

    func testTooShortHexWithOnionAddress() {

        let hex: String = "111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff"
        let address: String? = "/onion3/abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrst:12345"

        let result = String.isBaseNodeAddress(hex: hex, address: address)

        XCTAssertFalse(result)
    }

    func testTooLongHexWithIP4Address() {

        let hex: String = "01111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff"
        let address: String? = "/ip4/11.22.33.44/tcp/12345"

        let result = String.isBaseNodeAddress(hex: hex, address: address)

        XCTAssertFalse(result)
    }

    func testInvalidOnionAddress() {

        let hex: String = "1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff"
        let address: String? = "/onion/abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrst:12345"

        let result = String.isBaseNodeAddress(hex: hex, address: address)

        XCTAssertFalse(result)
    }
    

    func testTooShortOnionAddress() {

        let hex: String = "1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff"
        let address: String? = "/onion3/bcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrst:12345"

        let result = String.isBaseNodeAddress(hex: hex, address: address)

        XCTAssertFalse(result)
    }

    func testTooLongOnionAddress() {

        let hex: String = "1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff"
        let address: String? = "/onion3/xabcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrst:12345"

        let result = String.isBaseNodeAddress(hex: hex, address: address)

        XCTAssertFalse(result)
    }

    func testInvalidIP4Address() {

        let hex: String = "1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff"
        let address: String? = "/ip5/11.22.33.44/tcp/12345"

        let result = String.isBaseNodeAddress(hex: hex, address: address)

        XCTAssertFalse(result)
    }

    func testTooShortIP4Address() {

        let hex: String = "1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff"
        let address: String? = "/ip4/1111.22.33.44/tcp/12345"

        let result = String.isBaseNodeAddress(hex: hex, address: address)

        XCTAssertFalse(result)
    }

    func testTooLongIP4Address() {

        let hex: String = "1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff"
        let address: String? = "/ip4/22.33.44/tcp/12345"

        let result = String.isBaseNodeAddress(hex: hex, address: address)

        XCTAssertFalse(result)
    }

    func testOnionInvalidPort() {

        let hex: String = "1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff"
        let address: String? = "/onion3/abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrst:1234567"

        let result = String.isBaseNodeAddress(hex: hex, address: address)

        XCTAssertFalse(result)
    }

    func testIP4InvalidPort() {
        
        let hex: String = "1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff"
        let address: String? = "/ip4/11.22.33.44/tcp/1234567"

        let result = String.isBaseNodeAddress(hex: hex, address: address)

        XCTAssertFalse(result)
    }
}
