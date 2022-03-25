//  YatCacheManagerTests.swift
	
/*
	Package UnitTests
	Created by Adrian Truszczynski on 15/11/2021
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

@testable import Tari_Aurora
import XCTest

final class YatCacheManagerTests: XCTestCase {

    private var cacheManager: YatCacheManager!
    private var cacheFolder: URL { FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first! }
    
    override func setUp() {
        super.setUp()
        try? FileManager.default.removeItem(at: cacheFolder)
        cacheManager = YatCacheManager()
    }

    func testAddFile() {
        
        let filename = "test_file-HASH.txt"
        let data = "Test data".data(using: .utf8)!
        
        let fileData = cacheManager.save(data: data, name: filename)
        let storedData = try! Data(contentsOf: fileData!.url)
        
        XCTAssert(fileData!.url.lastPathComponent.hasPrefix(filename))
        XCTAssertEqual(data, storedData)
    }
    
    func testReplaceFile() {
        
        let filename1 = "test_file-HASH1.txt"
        let filename2 = "test_file-HASH2.txt"
        let data1 = "Test data 1".data(using: .utf8)!
        let data2 = "Test data 2".data(using: .utf8)!
        
        let fileData1 = cacheManager.save(data: data1, name: filename1)
        let fileData2 = cacheManager.save(data: data2, name: filename2)
        
        let storedData1 = try? Data(contentsOf: fileData1!.url)
        let storedData2 = try! Data(contentsOf: fileData2!.url)
        
        XCTAssertNil(storedData1)
        XCTAssert(fileData2!.url.lastPathComponent.hasPrefix(filename2))
        XCTAssertEqual(data2, storedData2)
    }
    
    func testFetchFile() {
        
        let filename = "test_file-HASH.txt"
        let data = "Test data".data(using: .utf8)!
        
        let savedFileData = cacheManager.save(data: data, name: filename)!
        let fetchedFileData = cacheManager.fetchFileData(name: filename)!
        
        XCTAssertEqual(savedFileData.url, fetchedFileData.url)
    }
    
    func testFetchSquareVideoWithNoCachedVideo() {
        
        let inputTestData = testData(hash: "HASH", isVertical: false)
        
        let fileData = cacheManager.fetchFileData(name: inputTestData.filename)
        
        XCTAssertNil(fileData)
    }
    
    func testFetchSquareVideoWithCachedSquareVideo() {
        
        let inputTestData = testData(hash: "HASH", isVertical: false)
        _ = cacheManager.save(data: inputTestData.data, name: inputTestData.filename)
        
        let fileData = cacheManager.fetchFileData(name: inputTestData.filename)
        
        XCTAssertNotNil(fileData)
        XCTAssertEqual(fileData!.url.lastPathComponent, inputTestData.filename)
        XCTAssertEqual(fileData!.identifier, .normalVideo)
    }
    
    func testFetchSquareVideoWithCachedVerticalVideo() {
        
        let inputTestData = testData(hash: "HASH", isVertical: false)
        let verticalVideoData = testData(hash: "HASH", isVertical: true)
        _ = cacheManager.save(data: verticalVideoData.data, name: verticalVideoData.filename)
        
        let fileData = cacheManager.fetchFileData(name: inputTestData.filename)
        
        XCTAssertNotNil(fileData)
        XCTAssertEqual(fileData!.url.lastPathComponent, verticalVideoData.filename)
        XCTAssertEqual(fileData!.identifier, .verticalVideo)
    }
    
    func testFetchVerticalVideoWithNoCachedVideo() {
        
        let inputTestData = testData(hash: "HASH", isVertical: true)
        
        let fileData = cacheManager.fetchFileData(name: inputTestData.filename)
        
        XCTAssertNil(fileData)
    }
    
    func testFetchVerticalVideoWithCachedSquareVideo() {
        
        let inputTestData = testData(hash: "HASH", isVertical: true)
        let squareVideoData = testData(hash: "HASH", isVertical: false)
        _ = cacheManager.save(data: squareVideoData.data, name: squareVideoData.filename)
        
        let fileData = cacheManager.fetchFileData(name: inputTestData.filename)
        
        XCTAssertNil(fileData)
    }
    
    func testFetchVerticalVideoWithCachedVerticalVideo() {
        
        let inputTestData = testData(hash: "HASH", isVertical: true)
        _ = cacheManager.save(data: inputTestData.data, name: inputTestData.filename)
        
        let fileData = cacheManager.fetchFileData(name: inputTestData.filename)
        
        XCTAssertNotNil(fileData)
        XCTAssertEqual(fileData!.url.lastPathComponent, inputTestData.filename)
        XCTAssertEqual(fileData!.identifier, .verticalVideo)
    }
    
    func testFetchNewSquareVideoWithCachedSquareVideo() {
        
        let inputTestData = testData(hash: "NEWHASH", isVertical: false)
        let cachedVideoData = testData(hash: "HASH", isVertical: false)
        _ = cacheManager.save(data: cachedVideoData.data, name: cachedVideoData.filename)
        
        let fileData = cacheManager.fetchFileData(name: inputTestData.filename)
        
        XCTAssertNil(fileData)
    }
    
    func testFetchNewSquareVideoWithCachedVerticalVideo() {
        
        let inputTestData = testData(hash: "NEWHASH", isVertical: false)
        let cachedVideoData = testData(hash: "HASH", isVertical: true)
        _ = cacheManager.save(data: cachedVideoData.data, name: cachedVideoData.filename)
        
        let fileData = cacheManager.fetchFileData(name: inputTestData.filename)
        
        XCTAssertNil(fileData)
    }
    
    func testFetchNewVerticalVideoWithCachedSquareVideo() {
        
        let inputTestData = testData(hash: "NEWHASH", isVertical: true)
        let cachedVideoData = testData(hash: "HASH", isVertical: false)
        _ = cacheManager.save(data: cachedVideoData.data, name: cachedVideoData.filename)
        
        let fileData = cacheManager.fetchFileData(name: inputTestData.filename)
        
        XCTAssertNil(fileData)
    }
    
    func testFetchNewVerticalVideoWithCachedVerticalVideo() {
        
        let inputTestData = testData(hash: "NEWHASH", isVertical: true)
        let cachedVideoData = testData(hash: "HASH", isVertical: true)
        _ = cacheManager.save(data: cachedVideoData.data, name: cachedVideoData.filename)
        
        let fileData = cacheManager.fetchFileData(name: inputTestData.filename)
        
        XCTAssertNil(fileData)
    }
    
    // MARK: - Helpers
    
    private func testData(hash: String, isVertical: Bool) -> (filename: String, data: Data) {
        let identifier = isVertical ? ".vert" : ""
        let filename = "test_file-\(hash)\(identifier).mp4"
        let data = "test_data_\(hash)_\(identifier)".data(using: .utf8)!
        return (filename: filename, data: data)
    }
}
