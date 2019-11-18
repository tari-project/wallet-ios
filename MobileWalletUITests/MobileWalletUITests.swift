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
        
        //Wipes app and creates new wallet
        wipeAppContents(app)
        Biometrics.enrolled()
        app.launch()
        XCUIApplication().buttons["Create Wallet"].tap()
        acceptPermissionsPromptIfRequired()
        Biometrics.successfulAuthentication()
        app.terminate()
        
        app.launchArguments = ["-disable-animations"]
    }

    override func tearDown() {
    }
   
    //Needs to be run after wallet creation
    func testHomeScreenTransactionView() {
        app.launch()
        Biometrics.successfulAuthentication()
        
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
    
    func testHomeScreenNotShownOnAuthFail() {
        app.launch()
        Biometrics.unsuccessfulAuthentication()
      
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard") // Shows permissions alerts over our app
        let cancelButton = springboard.alerts.buttons["Cancel"].firstMatch
        if cancelButton.exists {
            cancelButton.tap()
        } else {
            XCTFail("Missing auth failed alert")
        }
    }
        
    func testLaunchPerformance() {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // TODO measure time it takes to refresh transactions
//            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
//                XCUIApplication().launch()
//            }
        }
    }
}
