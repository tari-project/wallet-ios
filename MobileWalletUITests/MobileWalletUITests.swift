//
//  MobileWalletUITests.swift
//  MobileWalletUITests
//
//  Created by Jason van den Berg on 2019/10/28.
//  Copyright © 2019 Jason van den Berg. All rights reserved.
//

import XCTest

class MobileWalletUITests: XCTestCase {
    private let app = XCUIApplication()
    
    override func setUp() {
        continueAfterFailure = false

        app.launchArguments = ["-disable-animations"]
    }

    override func tearDown() {
    }
    
    func testLaunchPerformance() {
//        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
//            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
//                XCUIApplication().launch()
//            }
//        }
    }
}
