//  OnboardingTests.swift
	
/*
	Package MobileWalletUITests
	Created by Jason van den Berg on 2019/11/14
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

class OnboardingUITests: XCTestCase {
    private let app = XCUIApplication()
    
    override func setUp() {
        
        continueAfterFailure = false

        //Setup initial state for each test
        wipeAppContents(app)
        
        app.launchArguments = ["-disable-animations"]
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testWalletCreationWithSuccessfulBiometrics() {
        Biometrics.enrolled()
        app.launch()
        
        expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: app.staticTexts["Create Wallet"], handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        XCUIApplication().buttons["Create Wallet"].tap()

        acceptPermissionsPromptIfRequired()
        Biometrics.successfulAuthentication()
        
        //Expect the home screen
        expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: app.staticTexts["Total Balance"], handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testWalletCreationWithUnuccessfulBiometrics() {
        //Implement me
    }
    
    func testWalletCreationWithUnenrolledBiometrics() {
        //Implement me
    }
    
    func testLaunchPerformance() {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
                app.launch()
            }
        }
    }
    
    
}
