//
//  MobileWalletUITests.swift
//  MobileWalletUITests
//
//  Created by Jason van den Berg on 2019/10/28.
//  Copyright © 2019 Jason van den Berg. All rights reserved.
//

import XCTest

class MobileWalletUITests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSplash() {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        
         //Wait for splash loading animation to complete
        expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: app.staticTexts["Total Balance"], handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
        
        app.swipeUp()
        app.tables.staticTexts["Payment for 25 tacos"].tap()
        //TODO make some view asserts
        app.navigationBars["Payment Received"].buttons["Back"].tap()
        
        app.swipeDown()
        app.tables.staticTexts["Payment for 24 tacos"].tap()
        app.navigationBars["Payment Sent"].buttons["Back"].tap()
    }

    func testLaunchPerformance() {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
                XCUIApplication().launch()
            }
        }
    }
}
