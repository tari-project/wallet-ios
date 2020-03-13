//  MobileWalletUISnapshots.swift
	
/*
	Package MobileWalletUISnapshots
	Created by Jason van den Berg on 2020/03/09
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

class MobileWalletUISnapshots: XCTestCase {
    var app = XCUIApplication()
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        
        setupSnapshot(app)
        
        
        Biometrics.enrolled()
        
        app.launchArguments = ["ui-test-mode"]
        
        app.launch()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        app.terminate()
    }

    func testSnapshots() {
        let createWalletButton = app.buttons["Create Wallet"]
        guard createWalletButton.waitForExistence(timeout: 5) else { return }
        snapshot("001 create wallet")
        createWalletButton.tap()
        
        let createEmojiIdButton = app.buttons["Continue & Create Emoji ID"]
        guard createEmojiIdButton.waitForExistence(timeout: 20) else { return }
        snapshot("002 Create emoji ID")
        createEmojiIdButton.tap()
        
        let continueButton = app.buttons["Continue"]
        guard continueButton.waitForExistence(timeout: 20) else { return }
        snapshot("003 Emoji ID display")
        continueButton.tap()
        
        var enableFaceIdButton = app.buttons["Enable Face ID"]
        if !enableFaceIdButton.waitForExistence(timeout: 10) {
            //If we don't fine face ID button, assume touch ID device
            enableFaceIdButton = app.buttons["Enable Touch ID"]
        }
        snapshot("004 Enable face/touch ID")
        enableFaceIdButton.tap()
        
        snapshot("005 Enable Face ID confirmation")

        acceptPermissionsPromptIfRequired()
        Biometrics.successfulAuthentication()
        
        sleep(5)
        
        snapshot("006 Wallet intro")

        
//        let welcomeStaticText = app.staticTexts["Swipe down and I'll show you around your wallet"]
//        welcomeStaticText.waitForExistence(timeout: 5)
        
        sleep(5)
        app.swipeDown()
        
        let youGotSomeTariStaticText = app.staticTexts["You got some Tari!"]
        guard youGotSomeTariStaticText.waitForExistence(timeout: 20) else { return }
        snapshot("007 TariBot recieved")
        
        
        let sendTariButton = app.children(matching: .window).element(boundBy: 2).buttons["Send Tari"]
        guard sendTariButton.waitForExistence(timeout: 15) else { return }
        sendTariButton.tap()
        
        snapshot("008 Add recipient")
        
        app.tables.children(matching: .cell).element(boundBy: 0).staticTexts["TariBot"].tap()
        
        let sendContinueButton = app.buttons["Continue"]
        guard sendContinueButton.waitForExistence(timeout: 4) else { return }
        snapshot("009 Add recipient selected")
        sendContinueButton.tap()
        
        snapshot("010 Send amount")
        app.buttons["2"].tap()
        app.buttons["5"].tap()
        
        let amountContinueButton = app.buttons["Continue"]
        guard amountContinueButton.waitForExistence(timeout: 4) else { return }
        snapshot("011 Send amount set")
        amountContinueButton.tap()
        
        snapshot("012 Add note")
        
        //Typing hey
        app.keys["H"].tap()
        app.keys["e"].tap()
        app.keys["y"].tap()
        
        snapshot("013 Note added")

        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 0).staticTexts["Slide to Send"].tap()
                
        sleep(2)
        snapshot("013 Sending")
        
        let heyTxNote = app.tables.staticTexts["Hey"]
        guard heyTxNote.waitForExistence(timeout: 15) else { return }
        
        snapshot("014 Home view")
    
        heyTxNote.tap()
        
        snapshot("015 Transaction detail")
        
        app.buttons["Edit"].tap()
        
        snapshot("016 Alias editing")
        
        app.keys["delete"].tap()
        app.keys["o"].tap()
        app.keys["t"].tap()
        app.keys["y"].tap()
        app.buttons["Done"].tap()
        
        snapshot("017 Alias done editing")
        
        app.navigationBars["Payment Sent"].buttons["Back"].tap()
        
        app.buttons["profileIcon"].tap()
        
        snapshot("018 Alias done editing")

        app.buttons["Close"].tap()
    }
}
