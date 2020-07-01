//  AESEncryptionTests.swift
	
/*
	Package MobileWalletTests
	Created by S.Shovkoplyas on 30.06.2020
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

import XCTest

class AESEncryptionTests: XCTestCase {
    private let testText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    
    private let fileName = "AESTest"
    private let encryptedFileName = "encrypted"
    private let decryptedFileName = "decrypted"
    private let testPass = "coolpassword"
    
    func testAESEncription() {
        do {
            try cleanAESTestsDirectory()
            
            let zippedTxtFileURL = try zipTxtFile()
            let encryptedFileURL = try encrypt(fileAt: zippedTxtFileURL)
            let decryptedFileURL = try decrypt(fileAt: encryptedFileURL)
            
            let string = try String(contentsOf: decryptedFileURL)
            XCTAssertEqual(testText, string, "Test Failed. Value returned from decrypted file should be equal to testText variable")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    private func zipTxtFile() throws -> URL {
        let writeURL = try getAESTestDirectory()
        let fileURL = writeURL.appendingPathComponent(fileName + ".txt")
        try testText.write(to: fileURL, atomically: false, encoding: .utf8)
        
        let archiveName = fileName + ".zip"
        let archiveURL = writeURL.appendingPathComponent(archiveName)
        try FileManager().zipItem(at: fileURL, to: archiveURL, compressionMethod: .deflate)
        
        return archiveURL
    }
    
    private func encrypt(fileAt url: URL) throws -> URL {
        let data = try Data(contentsOf: url)
        let aes = try AESEncryption(keyString: testPass)
        
        let encryptedData = try aes.encrypt(data)
        let fileURL = try getAESTestDirectory().appendingPathComponent(encryptedFileName)
        try encryptedData.write(to: fileURL)
        return fileURL
    }
    
    private func decrypt(fileAt url: URL) throws -> URL {
        let data = try Data(contentsOf: url)
        let aes = try AESEncryption(keyString: testPass)
        
        let decryptedZipUrl = try getAESTestDecryptedDirectory().appendingPathComponent(decryptedFileName + ".zip")
        let decryptedTxtUrl = try getAESTestDecryptedDirectory().appendingPathComponent(fileName + ".txt")
        
        let decryptedData = try aes.decrypt(data)
        try decryptedData.write(to: decryptedZipUrl)
        
        try FileManager.default.unzipItem(at: decryptedZipUrl, to: getAESTestDecryptedDirectory())
        return decryptedTxtUrl
    }
    
    private func cleanAESTestsDirectory() throws {
        let directory = try getAESTestDirectory()
        
        if FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.removeItem(atPath: directory.path)
        }
    }
    
    private func getAESTestDirectory() throws -> URL {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        
        let url = URL(fileURLWithPath: path!).appendingPathComponent(fileName)
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        let decryptedDirectory = url.appendingPathComponent("Decrypted")
        if !FileManager.default.fileExists(atPath: decryptedDirectory.path) {
            try FileManager.default.createDirectory(at: decryptedDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        return url
    }
    
    private func getAESTestDecryptedDirectory() throws -> URL {
        return try getAESTestDirectory().appendingPathComponent("Decrypted")
    }
}
