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

protocol Cryptable {
    func encrypt(_ data: Data) throws -> Data
    func decrypt(_ data: Data) throws -> Data
}

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

struct AESEncryption {
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

extension AESEncryption: Cryptable {
    func encrypt(_ data: Data) throws -> Data {
        let salt = try generateSalt()
        let key = try createKey(password: keyString, salt: salt)

        let bufferSize: Int = data.count + ivSize + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)

        try generateRandomIV(for: &buffer)
        var numberEncryptedBytes: Int = 0

        do {
            try key.withUnsafeBytes { keyBytes in
                try data.withUnsafeBytes { dataToEncryptBytes in
                    try buffer.withUnsafeMutableBytes { bufferBytes in

                        guard
                            let keyBytesBaseAddress = keyBytes.baseAddress,
                            let dataToEncryptBytesBaseAddress = dataToEncryptBytes.baseAddress,
                            let bufferBytesBaseAddress = bufferBytes.baseAddress
                        else { throw AESError.invalidInputData }

                        let dataInLength = dataToEncryptBytes.count
                        let dataToEncryptBytes = dataToEncryptBytesBaseAddress
                        let encryptedDataBuffer = bufferBytesBaseAddress + ivSize

                        let cryptStatus: CCCryptorStatus = CCCrypt(
                            CCOperation(kCCEncrypt),                // op: CCOperation
                            CCAlgorithm(kCCAlgorithmAES),           // alg: CCAlgorithm
                            options,                                // options: CCOptions
                            keyBytesBaseAddress,                    // key: the "password"
                            keySize,                                // keyLength: the "password" size
                            bufferBytesBaseAddress,                 // iv: Initialization Vector
                            dataToEncryptBytes,                     // dataIn: Data to encrypt bytes
                            dataInLength,                           // dataInLength: Data to encrypt size
                            encryptedDataBuffer,                    // dataOut: encrypted Data buffer
                            bufferSize,                             // dataOutAvailable: encrypted Data buffer size
                            &numberEncryptedBytes                   // dataOutMoved: the number of bytes written
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

        var outData: Data = buffer[..<(numberEncryptedBytes + ivSize)]
        outData.insert(contentsOf: [UInt8](salt), at: 0)

        return outData
    }

    func decrypt(_ dataIn: Data) throws -> Data {
        let data = dataIn.dropFirst(saltSize)
        let salt = dataIn.subdata(in: 0..<saltSize)
        let key = try createKey(password: keyString, salt: salt)

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
    private func generateRandomIV(for data: inout Data) throws {
        try generateRandomData(for: &data, length: kCCBlockSizeAES128)
    }

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

    private func createKey(password: String, salt: Data) throws -> Data {
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
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1),   // prf
                    10000,                                        // rounds
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
