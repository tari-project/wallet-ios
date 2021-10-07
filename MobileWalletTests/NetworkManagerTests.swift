//  NetworkManagerTests.swift
	
/*
	Package MobileWalletTests
	Created by Adrian Truszczynski on 31/08/2021
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

import XCTest

final class NetworkManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    private let defaultNetwork = TariNetwork.weatherwax
    private var networkManager: NetworkManager!
    
    // MARK: - Setups
    
    override func setUp() {
        super.setUp()
        
        GroupUserDefaults.selectedNetworkName = nil
        GroupUserDefaults.networksSettings = nil
        networkManager = NetworkManager()
    }
    
    // MARK: - Tests
    
    func testInitiatingValuesInPersistantStore() {
        let selectedNetworkNameAfterChange = GroupUserDefaults.selectedNetworkName
        XCTAssertEqual(selectedNetworkNameAfterChange, defaultNetwork.name)
    }
    
    func testSwitchNetwork() {
        
        let networkAfterSwitch = TariNetwork.igor
        
        let selectedNetworkNameBeforeSwitch = GroupUserDefaults.selectedNetworkName
        
        networkManager.selectedNetwork = networkAfterSwitch
        
        let selectedNetworkNameAfterSwitch = GroupUserDefaults.selectedNetworkName
        
        XCTAssertEqual(selectedNetworkNameBeforeSwitch, defaultNetwork.name)
        XCTAssertEqual(selectedNetworkNameAfterSwitch, networkAfterSwitch.name)
    }
    
    func testSettingsInitalization() {
        
        let networkSettingsBeforeChange = GroupUserDefaults.networksSettings
        
        _ = networkManager.selectedNetwork.settings // Initialization
        
        let networkSettingsAfterChange = GroupUserDefaults.networksSettings
        
        XCTAssertNil(networkSettingsBeforeChange)
        XCTAssertEqual(networkSettingsAfterChange!.count, 1)
        XCTAssertEqual(networkSettingsAfterChange!.first!.name, defaultNetwork.name)
    }
    
    func testSettingsOnNetworkSwitching() {
        
        _ = networkManager.selectedNetwork.settings // Initialization
        
        let networkAfterSwitch = TariNetwork.igor
        let networkSettingsBeforeChange = GroupUserDefaults.networksSettings

        networkManager.selectedNetwork = networkAfterSwitch
        _ = networkManager.selectedNetwork.settings // Update
        
        let networkSettingsAfterChange = GroupUserDefaults.networksSettings
        
        XCTAssertEqual(networkSettingsBeforeChange!.count, 1)
        XCTAssertEqual(networkSettingsAfterChange!.count, 2)
        XCTAssertEqual(networkSettingsAfterChange![0].name, defaultNetwork.name)
        XCTAssertEqual(networkSettingsAfterChange![1].name, networkAfterSwitch.name)
    }
    
    func testSelectedBaseNodeUpdate() {
        
        let baseNode = try! BaseNode(name: "Test Name", peer: "2e93c460df49d8cfbbf7a06dd9004c25a84f92584f7d0ac5e30bd8e0beee9a43::/onion3/nuuq3e2olck22rudimovhmrdwkmjncxvwdgbvfxhz6myzcnx2j4rssyd:18141")
        
        networkManager.selectedNetwork.selectedBaseNode = baseNode
        
        let selectedNetworkName = GroupUserDefaults.selectedNetworkName!
        let networkSettings = GroupUserDefaults.networksSettings!.first!
        
        XCTAssertEqual(selectedNetworkName, networkManager.selectedNetwork.name)
        XCTAssertEqual(networkSettings.selectedBaseNode, baseNode)
    }
    
    func testCustomBaseNodesUpdate() {
        
        let baseNode = try! BaseNode(name: "Test Name", peer: "2e93c460df49d8cfbbf7a06dd9004c25a84f92584f7d0ac5e30bd8e0beee9a43::/onion3/nuuq3e2olck22rudimovhmrdwkmjncxvwdgbvfxhz6myzcnx2j4rssyd:18141")
        
        networkManager.selectedNetwork.customBaseNodes = [baseNode]
        
        let customBaseNodes = GroupUserDefaults.networksSettings!.first!.customBaseNodes
        
        XCTAssertEqual(customBaseNodes.count, 1)
        XCTAssertEqual(customBaseNodes, networkManager.selectedNetwork.customBaseNodes)
        XCTAssertEqual(customBaseNodes.first!, baseNode)
    }
    
    func testIsCloudBackupEnabledUpdate() {
        
        networkManager.selectedNetwork.isCloudBackupEnabled = true
        
        let iCloudBackupEnabled = GroupUserDefaults.networksSettings!.first!.isCloudBackupEnabled
        
        XCTAssertEqual(iCloudBackupEnabled, networkManager.selectedNetwork.isCloudBackupEnabled)
        XCTAssertTrue(iCloudBackupEnabled)
    }
}
