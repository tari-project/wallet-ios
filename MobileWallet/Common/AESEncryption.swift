//  AESEncryption.swift

/*
    Package MobileWallet
    Created by S.Shovkoplyas on 09.06.2020
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

import Foundation
import CommonCrypto
import CryptoKit

enum AESError: Error {
    case generic(_ description: String)
    case invalidKeySize
    case invalidInputData
    case randomDataFailed
    case encryptionFailed(_ statusCode: Int32)
    case decryptionFailed(_ statusCode: Int32)
    case keyGeneration(_ statusCode: Int32)
}

extension AESError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .generic(let description):
            return localized("AES Error. \(description)")
        case .invalidKeySize:
            return localized("Too short key string to encrypt file.")
        case .invalidInputData:
            return localized("Failed to read bytes from data.")
        case .randomDataFailed:
            return localized("Failed to generate random data")
        case .keyGeneration(let statusCode):
            return localized("Failed to generate key. Error: \(statusCode))")
        case .encryptionFailed(let statusCode):
            return localized("Something went wrong. Failed to encrypt data. Error: \(statusCode)")
        case .decryptionFailed(let statusCode):
            return localized("Something went wrong. Failed to decrypt data. Error: \(statusCode)")
        }
    }
}

/// Backup file formats:
///
/// - current: `magic (8) | salt (16) | nonce (12) | ciphertext | tag (16)`, AES-256-GCM, key from PBKDF2-HMAC-SHA256
///   with 600,000 rounds. The magic and the salt are authenticated together with the ciphertext.
/// - legacy: `salt (16) | iv (16) | ciphertext`, AES-256-CBC, key from PBKDF2-HMAC-SHA1 with 10,000 rounds. It has no
///   integrity protection and is only read, never written.
struct AESEncryption {
    private static let magic = Data("TARIBKP2".utf8)
    private static let nonceSize = 12
    private static let tagSize = 16
    private static let rounds: UInt32 = 600_000
    private static let legacyRounds: UInt32 = 10_000

    private let keyString: String
    private let ivSize: Int = kCCBlockSizeAES128
    private let saltSize: Int = kCCBlockSizeAES128
    private let keySize: Int = kCCKeySizeAES256
    private let options: CCOptions  = CCOptions(kCCOptionPKCS7Padding)

    init(keyString: String) throws {
        guard !keyString.isEmpty else { throw AESError.invalidKeySize }
        self.keyString = keyString
    }
}

extension AESEncryption {
    func encrypt(_ data: Data) throws -> Data {
        let salt = try generateSalt()
        let key = try createKey(password: keyString, salt: salt, algorithm: CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), rounds: Self.rounds)
        let header = Self.magic + salt

        do {
            let sealedBox = try AES.GCM.seal(data, using: SymmetricKey(data: key), authenticating: header)
            return header + Data(sealedBox.nonce) + sealedBox.ciphertext + sealedBox.tag
        } catch {
            throw AESError.encryptionFailed(Int32(kCCUnspecifiedError))
        }
    }

    func decrypt(_ dataIn: Data) throws -> Data {
        // `Data` slices keep the indices of their base, rebase first
        let dataIn = Data(dataIn)
        guard dataIn.starts(with: Self.magic) else { return try decryptLegacy(dataIn) }

        let headerSize = Self.magic.count + saltSize
        guard dataIn.count >= headerSize + Self.nonceSize + Self.tagSize else { throw AESError.invalidInputData }

        let header = dataIn.prefix(headerSize)
        let salt = dataIn.subdata(in: Self.magic.count..<headerSize)
        let nonce = dataIn.subdata(in: headerSize..<(headerSize + Self.nonceSize))
        let ciphertext = dataIn.subdata(in: (headerSize + Self.nonceSize)..<(dataIn.count - Self.tagSize))
        let tag = dataIn.suffix(Self.tagSize)
        let key = try createKey(password: keyString, salt: salt, algorithm: CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), rounds: Self.rounds)

        do {
            let sealedBox = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: nonce), ciphertext: ciphertext, tag: tag)
            return try AES.GCM.open(sealedBox, using: SymmetricKey(data: key), authenticating: header)
        } catch {
            // Wrong password or modified file, the two cannot be told apart
            throw AESError.decryptionFailed(Int32(kCCDecodeError))
        }
    }

    private func decryptLegacy(_ dataIn: Data) throws -> Data {
        // salt, iv and at least one cipher block
        guard dataIn.count >= saltSize + ivSize + kCCBlockSizeAES128 else { throw AESError.invalidInputData }

        let data = dataIn.dropFirst(saltSize)
        let salt = dataIn.subdata(in: 0..<saltSize)
        let key = try createKey(password: keyString, salt: salt, algorithm: CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1), rounds: Self.legacyRounds)

        let bufferSize: Int = data.count - ivSize
        var buffer = Data(count: bufferSize)

        var numberDecryptedBytes: Int = 0

        do {
            try key.withUnsafeBytes { keyBytes in
                try data.withUnsafeBytes { dataToDecryptBytes in
                    try buffer.withUnsafeMutableBytes { bufferBytes in

                        guard
                            let keyBytesBaseAddress = keyBytes.baseAddress,
                            let dataToDecryptBytesBaseAddress = dataToDecryptBytes.baseAddress,
                            let bufferBytesBaseAddress = bufferBytes.baseAddress
                        else { throw AESError.invalidInputData }

                        let dataInLength = bufferSize
                        let dataToDecryptBytes = dataToDecryptBytesBaseAddress + ivSize
                        let decryptedDataBuffer = bufferBytesBaseAddress

                        let cryptStatus: CCCryptorStatus = CCCrypt(
                            CCOperation(kCCDecrypt),                // op: CCOperation
                            CCAlgorithm(kCCAlgorithmAES),           // alg: CCAlgorithm
                            options,                                // options: CCOptions
                            keyBytesBaseAddress,                    // key: the "password"
                            keySize,                                // keyLength: the "password" size
                            dataToDecryptBytesBaseAddress,          // iv: Initialization Vector
                            dataToDecryptBytes,                     // dataIn: Data to decrypt bytes
                            dataInLength,                           // dataInLength: Data to decrypt size
                            decryptedDataBuffer,                    // dataOut: decrypted Data buffer
                            bufferSize,                             // dataOutAvailable: decrypted Data buffer size
                            &numberDecryptedBytes                   // dataOutMoved: the number of bytes written
                        )

                        guard cryptStatus == CCCryptorStatus(kCCSuccess) else {
                            throw AESError.decryptionFailed(cryptStatus)
                        }
                    }
                }
            }
        } catch {
            throw error
        }

        let outData: Data = buffer[..<numberDecryptedBytes]
        return outData
    }
}

extension AESEncryption {
    private func generateSalt() throws -> Data {
        var data = Data(count: saltSize)
        try generateRandomData(for: &data, length: saltSize)
        return data
    }

    private func generateRandomData(for data: inout Data, length: Int) throws {
        try data.withUnsafeMutableBytes { dataBytes in
            guard let dataBytesBaseAddress = dataBytes.baseAddress else {
                throw AESError.randomDataFailed
            }
            let status: Int32 = SecRandomCopyBytes(
                kSecRandomDefault,
                length,
                dataBytesBaseAddress
            )
            guard status == 0 else {
                throw AESError.randomDataFailed
            }
        }
    }

    private func createKey(password: String, salt: Data, algorithm: CCPseudoRandomAlgorithm, rounds: UInt32) throws -> Data {
        guard let password = password.data(using: .utf8) else { throw AESError.generic("Failed to get data from password") }

        let length = keySize
        var derivedBytes = [UInt8](repeating: 0, count: length)

        try password.withUnsafeBytes { passwordBytes in
            try salt.withUnsafeBytes { saltBytes in
                guard
                    let passwordBytesInt8 = passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                    let saltBytesUnt8 = saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self)
                else { throw AESError.generic("Failed to get data for password") }

                let status = CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),                  // algorithm
                    passwordBytesInt8,                            // password
                    password.count,                               // passwordLen
                    saltBytesUnt8,                                // salt
                    salt.count,                                   // saltLen
                    algorithm,                                    // prf
                    rounds,                                       // rounds
                    &derivedBytes,                                // derivedKey
                    length)                                       // derivedKeyLen

                guard status == 0 else {
                    throw AESError.keyGeneration(status)
                }
            }
        }
        return Data(bytes: derivedBytes, count: length)
    }
}
