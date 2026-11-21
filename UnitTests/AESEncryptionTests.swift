//  AESEncryptionTests.swift

/*
	Package UnitTests
	Created by Jan Kahmen on 21/11/2026
	Using Swift 6.0
	Running on macOS 15.8

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
import CommonCrypto
@testable import Tari_Aurora

final class AESEncryptionTests: XCTestCase {

    private let password = "backup password"
    private let plaintext = Data((0..<1000).map { UInt8($0 % 251) })
    private let magic = Data("TARIBKP2".utf8)

    func testRoundTrip() throws {
        let encryption = try AESEncryption(keyString: password)
        let encrypted = try encryption.encrypt(plaintext)

        XCTAssertEqual(encrypted.prefix(magic.count), magic)
        XCTAssertEqual(encrypted.count, plaintext.count + 52)
        XCTAssertEqual(try encryption.decrypt(encrypted), plaintext)
    }

    func testRoundTripOfEmptyData() throws {
        let encryption = try AESEncryption(keyString: password)
        XCTAssertEqual(try encryption.decrypt(try encryption.encrypt(Data())), Data())
    }

    func testTwoEncryptionsDiffer() throws {
        let encryption = try AESEncryption(keyString: password)
        XCTAssertNotEqual(try encryption.encrypt(plaintext), try encryption.encrypt(plaintext))
    }

    func testWrongPasswordIsRejected() throws {
        let encrypted = try AESEncryption(keyString: password).encrypt(plaintext)
        XCTAssertThrowsError(try AESEncryption(keyString: password + "x").decrypt(encrypted))
    }

    func testModifiedFileIsRejected() throws {
        let encryption = try AESEncryption(keyString: password)
        let encrypted = try encryption.encrypt(Data(plaintext.prefix(64)))

        // one position each in salt, nonce, ciphertext and tag
        for position in [8, 23, 24, 35, 36, 99, 100, encrypted.count - 1] {
            var modified = encrypted
            modified[position] ^= 0x01
            XCTAssertThrowsError(try encryption.decrypt(modified), "position \(position)")
        }
    }

    func testTruncatedFileIsRejected() throws {
        let encryption = try AESEncryption(keyString: password)
        let encrypted = try encryption.encrypt(plaintext)
        XCTAssertThrowsError(try encryption.decrypt(encrypted.dropLast()))
        XCTAssertThrowsError(try encryption.decrypt(encrypted.prefix(magic.count + 20)))
    }

    func testShortInputThrows() throws {
        let encryption = try AESEncryption(keyString: password)
        try (0..<48).forEach {
            XCTAssertThrowsError(try encryption.decrypt(Data(count: $0)), "\($0) bytes")
        }
    }

    func testLegacyFileIsRead() throws {
        let legacy = try legacyEncrypt(plaintext)
        let encryption = try AESEncryption(keyString: password)

        XCTAssertEqual(try encryption.decrypt(legacy), plaintext)
        // a slice does not start at index 0
        XCTAssertEqual(try encryption.decrypt((Data([0]) + legacy).dropFirst()), plaintext)
    }

    /// The format written before: `salt (16) | iv (16) | ciphertext`, AES-256-CBC, PBKDF2-HMAC-SHA1 with 10,000 rounds.
    private func legacyEncrypt(_ data: Data) throws -> Data {
        let salt = [UInt8]((0..<16).map { UInt8($0) })
        let iv = [UInt8]((16..<32).map { UInt8($0) })
        let passwordBytes = [UInt8](password.utf8)
        let input = [UInt8](data)

        var key = [UInt8](repeating: 0, count: kCCKeySizeAES256)
        let keyStatus = passwordBytes.withUnsafeBufferPointer {
            $0.withMemoryRebound(to: Int8.self) {
                CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), $0.baseAddress, $0.count, salt, salt.count, CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1), 10_000, &key, key.count)
            }
        }
        XCTAssertEqual(keyStatus, Int32(kCCSuccess))

        var output = [UInt8](repeating: 0, count: input.count + kCCBlockSizeAES128)
        var outputLength = 0
        let status = CCCrypt(CCOperation(kCCEncrypt), CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding), key, key.count, iv, input, input.count, &output, output.count, &outputLength)
        XCTAssertEqual(status, Int32(kCCSuccess))

        return Data(salt) + Data(iv) + Data(output.prefix(outputLength))
    }
}
