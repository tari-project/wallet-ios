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

        //Setup initial state for each test
        wipeAppContents(app)
        
        app.launchArguments = ["-disable-animations"]
    }

    override func tearDown() {
    }
   
    //Needs to be run after wallet creation
//    func testHomeScreenTransactionView() {
//        app.launch()
//        
//        expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: app.staticTexts["Create Wallet"], handler: nil)
//        waitForExpectations(timeout: 5, handler: nil)
//        XCUIApplication().buttons["Create Wallet"].tap()
//        acceptPermissionsPromptIfRequired()
//        Biometrics.successfulAuthentication()
//        
//         //Wait for splash loading animation to complete
//        expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: app.staticTexts["Total Balance"], handler: nil)
//        waitForExpectations(timeout: 10, handler: nil)
//        
//        app.swipeUp()
//        app.tables.staticTexts["Payment for 25 tacos"].tap()
//        //TODO make some view asserts
//        app.navigationBars["Payment Received"].buttons["Back"].tap()
//        
//        app.swipeDown()
//        app.tables.staticTexts["Payment for 24 tacos"].tap()
//        app.navigationBars["Payment Sent"].buttons["Back"].tap()
//    }
    
    func testLaunchPerformance() {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
                XCUIApplication().launch()
            }
        }
    }
}
