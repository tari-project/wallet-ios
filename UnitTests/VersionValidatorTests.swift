//  VersionValidatorTests.swift
	
/*
	Package UnitTests
	Created by Adrian Truszczynski on 23/11/2022
	Using Swift 5.0
	Running on macOS 12.6

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

final class VersionValidatorTests: XCTestCase {
    
    func testFirstVersionIsHigher() {
        
        let firstVersion = "1.23.45"
        let secondVersion = "1.23.01"
        
        let result = VersionValidator.compare(firstVersion, isHigherOrEqualTo: secondVersion)
        XCTAssertTrue(result)
    }
    
    func testFirstVersionIsHigherAndLonger() {
        
        let firstVersion = "11.23.45"
        let secondVersion = "1.23.45"
        
        let result = VersionValidator.compare(firstVersion, isHigherOrEqualTo: secondVersion)
        XCTAssertTrue(result)
    }
    
    func testFirstVersionIsHigherAndShorter() {
        
        let firstVersion = "1.23.45"
        let secondVersion = "1.23.001"
        
        let result = VersionValidator.compare(firstVersion, isHigherOrEqualTo: secondVersion)
        XCTAssertTrue(result)
    }
    
    func testFirstVersionHaveExtraComponent() {
        
        let firstVersion = "1.23.45.1"
        let secondVersion = "1.23.45"
        
        let result = VersionValidator.compare(firstVersion, isHigherOrEqualTo: secondVersion)
        XCTAssertTrue(result)
    }
    
    func testSecondVersionIsHigher() {
        
        let firstVersion = "1.23.01"
        let secondVersion = "1.23.45"
        
        let result = VersionValidator.compare(firstVersion, isHigherOrEqualTo: secondVersion)
        XCTAssertFalse(result)
    }
    
    func testSecondVersionIsHigherAndLonger() {
        
        let firstVersion = "1.23.01"
        let secondVersion = "11.23.45"
        
        let result = VersionValidator.compare(firstVersion, isHigherOrEqualTo: secondVersion)
        XCTAssertFalse(result)
    }
    
    func testSecondVersionIsHigherAndShorter() {
        
        let firstVersion = "1.23.001"
        let secondVersion = "1.23.45"
        
        let result = VersionValidator.compare(firstVersion, isHigherOrEqualTo: secondVersion)
        XCTAssertFalse(result)
    }
    
    func testSecondVersionHaveExtraComponent() {
        
        let firstVersion = "1.23.45"
        let secondVersion = "1.23.45.1"
        
        let result = VersionValidator.compare(firstVersion, isHigherOrEqualTo: secondVersion)
        XCTAssertFalse(result)
    }
    
    func testVersionsAreEqual() {
        
        let firstVersion = "1.23.45"
        let secondVersion = "1.23.45"
        
        let result = VersionValidator.compare(firstVersion, isHigherOrEqualTo: secondVersion)
        XCTAssertTrue(result)
    }
}
