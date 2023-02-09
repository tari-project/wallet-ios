//  DeepLinkFormatterTests.swift

/*
	Package UnitTests
	Created by Adrian Truszczynski on 01/03/2022
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

final class DeepLinkFormatterTests: XCTestCase {

    override func setUp() {
        super.setUp()
        NetworkManager.shared.selectedNetwork = .testNetwork
    }

    // MARK: - General

    func testDeeplinkWithInvalidNetworkName() {

        let inputDeeplink = URL(string: "tari://invalid_network/transactions/send?publicKey=testpubkey&amount=123&note=Hello%20World!")!

        var result: TransactionsSendDeeplink?
        var cachedError: DeepLinkError!

        do {
            result = try DeepLinkFormatter.model(type: TransactionsSendDeeplink.self, deeplink: inputDeeplink)
        } catch {
            cachedError = error as? DeepLinkError
        }

        XCTAssertNil(result)
        switch cachedError {
        case .invalidNetworkName:
            break
        default:
            XCTFail("Invalid error type")
        }
    }

    func testDeeplinkWithInvalidCommandName() {

        let inputDeeplink = URL(string: "tari://test_network/invalid_command/send?publicKey=testpubkey&amount=123&note=Hello%20World!")!

        var result: TransactionsSendDeeplink?
        var cachedError: DeepLinkError!

        do {
            result = try DeepLinkFormatter.model(type: TransactionsSendDeeplink.self, deeplink: inputDeeplink)
        } catch {
            cachedError = error as? DeepLinkError
        }

        XCTAssertNil(result)
        switch cachedError {
        case .invalidCommandName:
            break
        default:
            XCTFail("Invalid error type")
        }
    }

    func testDeeplinkWithInvalidValue() {

        let inputDeeplink = URL(string: "tari://test_network/transactions/send?publicKey=testpubkey&amount=-123&note=Hello%20World!")!
        let invalidKey = "amount"

        var result: TransactionsSendDeeplink?
        var cachedError: DeepLinkError!

        do {
            result = try DeepLinkFormatter.model(type: TransactionsSendDeeplink.self, deeplink: inputDeeplink)
        } catch {
            cachedError = error as? DeepLinkError
        }

        XCTAssertNil(result)
        switch cachedError {
        case let .unableToParse(key):
            XCTAssertEqual(key, invalidKey)
        default:
            XCTFail("Invalid error type")
        }
    }

    // MARK: - TransactionsSendDeeplink

    func testValidTransactionsSendDeeplinkDecoding() {

        let inputDeeplink = URL(string: "tari://test_network/transactions/send?publicKey=testpubkey&amount=123&note=Hello%20World!")!
        let expectedResult = TransactionsSendDeeplink(receiverAddress: "testpubkey", amount: 123, note: "Hello World!")

        let result = try! DeepLinkFormatter.model(type: TransactionsSendDeeplink.self, deeplink: inputDeeplink)

        XCTAssertEqual(result.receiverAddress, expectedResult.receiverAddress)
        XCTAssertEqual(result.amount, expectedResult.amount)
        XCTAssertEqual(result.note, expectedResult.note)
    }

    func testValidTransactionsSendDeeplinkEncoding() {

        let inputModel = TransactionsSendDeeplink(receiverAddress: "testpubkey", amount: 123, note: "Hello World!")
        let expectedResult = URL(string: "tari://test_network/transactions/send?publicKey=testpubkey&amount=123&note=Hello%20World!")!

        let result = try! DeepLinkFormatter.deeplink(model: inputModel)

        XCTAssertEqual(result, expectedResult)
    }

    func testTransactionsSendDeeplinkDecodingWithMissingPublicKey() {

        let inputDeeplink = URL(string: "tari://test_network/transactions/send?amount=123&note=Hello%20World!")!
        let invalidKey = "publicKey"

        var result: TransactionsSendDeeplink?
        var cachedError: DeepLinkError!

        do {
            result = try DeepLinkFormatter.model(type: TransactionsSendDeeplink.self, deeplink: inputDeeplink)
        } catch {
            cachedError = error as? DeepLinkError
        }

        XCTAssertNil(result)
        switch cachedError {
        case let .unableToParse(key):
            XCTAssertEqual(key, invalidKey)
        default:
            XCTFail("Invalid error type")
        }
    }

    // MARK: - BaseNodesAddDeeplink

    func testValidBaseNodesAddDeeplinkDecoding() {

        let inputDeeplink = URL(string: "tari://test_network/base_nodes/add?name=test%20name&peer=onion3::test")!
        let expectedResult = BaseNodesAddDeeplink(name: "test name", peer: "onion3::test")

        let result = try! DeepLinkFormatter.model(type: BaseNodesAddDeeplink.self, deeplink: inputDeeplink)

        XCTAssertEqual(result.name, expectedResult.name)
        XCTAssertEqual(result.peer, expectedResult.peer)
    }

    func testValidBaseNodesAddDeeplinkEncoding() {

        let inputModel = BaseNodesAddDeeplink(name: "test name", peer: "onion3::test")
        let expectedResult = URL(string: "tari://test_network/base_nodes/add?name=test%20name&peer=onion3::test")!

        let result = try! DeepLinkFormatter.deeplink(model: inputModel)

        XCTAssertEqual(result, expectedResult)
    }

    func testBaseNodesAddDeeplinkDecodingWithMissingName() {

        let inputDeeplink = URL(string: "tari://test_network/base_nodes/add?peer=onion3::test")!
        let invalidKey = "name"

        var result: BaseNodesAddDeeplink?
        var cachedError: DeepLinkError!

        do {
            result = try DeepLinkFormatter.model(type: BaseNodesAddDeeplink.self, deeplink: inputDeeplink)
        } catch {
            cachedError = error as? DeepLinkError
        }

        XCTAssertNil(result)
        switch cachedError {
        case let .unableToParse(key):
            XCTAssertEqual(key, invalidKey)
        default:
            XCTFail("Invalid error type")
        }
    }

    func testBaseNodesAddDeeplinkDecodingWithMissingPeer() {

        let inputDeeplink = URL(string: "tari://test_network/base_nodes/add?name=test%20name")!
        let invalidKey = "peer"

        var result: BaseNodesAddDeeplink?
        var cachedError: DeepLinkError!

        do {
            result = try DeepLinkFormatter.model(type: BaseNodesAddDeeplink.self, deeplink: inputDeeplink)
        } catch {
            cachedError = error as? DeepLinkError
        }

        XCTAssertNil(result)
        switch cachedError {
        case let .unableToParse(key):
            XCTAssertEqual(key, invalidKey)
        default:
            XCTFail("Invalid error type")
        }
    }
}
