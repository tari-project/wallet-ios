//  MobileWalletTests.swift

/*
    Package MobileWalletTests
    Created by Jason van den Berg on 2019/10/28
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

@testable import Pods_MobileWallet

class MobileWalletTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testThemeAssets() {
        let colors = Theme.shared.colors
        let fonts = Theme.shared.fonts
        let images = Theme.shared.images
        
        do {
            for color in try colors.allProperties() {
                if color.value as? UIColor == nil {
                    XCTFail("Failed to find color asset in theme for property: \"\(color.key)\"")
                }
            }
            
            for font in try fonts.allProperties() {
                if font.value as? UIFont == nil {
                    XCTFail("Failed to find font asset in theme for property: \"\(font.key)\"")
                }
            }
            
            for image in try images.allProperties() {
                if image.value as? UIImage == nil {
                    XCTFail("Failed to find image asset in theme for property: \"\(image.key)\"")
                }
            }

        } catch {
            XCTFail("Failed to iterate through theme assets")
        }
    }
    
    func testRelativeDayValue() {
        /*
         Today Date Test
        */
        XCTAssertEqual(Date().addingTimeInterval(-120).relativeDayFromToday(), "2m ago")
        XCTAssertEqual(Date().addingTimeInterval(-(60 * 60 * 2)).relativeDayFromToday(), "2h ago")

        /*
         Yesterday Date Test
         */
        let yesterday = Calendar.current.date(byAdding: Calendar.Component.day, value: -1, to: Date())!
        let yesterdayDateValue = yesterday.relativeDayFromToday()
        XCTAssertEqual(yesterdayDateValue, "Yesterday", "Test Failed. Value returned from Relative Day value should have been - Yesterday")
        
        /*
         Explicit Date Test
        */
        let threeDaysAgo = Calendar.current.date(byAdding: Calendar.Component.day, value: -3, to: Date())!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMM d, yyyy", options: 0, locale: NSLocale.current)
        dateFormatter.timeZone = TimeZone.current
        let expectedResult = dateFormatter.string(from: threeDaysAgo)
        let threeDaysAgoValue = threeDaysAgo.relativeDayFromToday()
        XCTAssertEqual(threeDaysAgoValue, expectedResult, "Test Failed. Value returned from Relative Day value should have been - \(expectedResult)")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
