//  TariLib.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/12
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

import Foundation

enum TariLibErrors: Error {
    case privateKeyNotFound
}

class TariLib {
    static let shared = TariLib()

    private let DATABASE_NAME = "tari_wallet"
    private let PRIVATE_KEY_STORAGE_KEY = "privateKey"

    private var storagePath: String {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL.path
    }

    var databasePath: String {
        return "\(storagePath)/\(DATABASE_NAME)"
    }

    static let logFilePrefix = "log"

    lazy var logFilePath: String = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        return "\(storagePath)/\(TariLib.logFilePrefix)-\(dateString).txt"
    }()

    var allLogFiles: [URL] {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let allLogFiles = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil).filter({$0.lastPathComponent.contains(TariLib.logFilePrefix)}).sorted(by: { (a, b) -> Bool in
                return a.path > b.path
            })
            return allLogFiles
        } catch {
            return []
        }
    }

    var publicAddress: String {
        return "/ip4/172.30.30.112/tcp/9838"
    }

    var listenerAddress: String {
        return "/ip4/0.0.0.0/tcp/9838"
    }

    private let fileManager = FileManager.default

    var tariWallet: Wallet?

    var walletExists: Bool {
        get {
            if (UserDefaults.standard.string(forKey: PRIVATE_KEY_STORAGE_KEY) != nil) {
                return true
            }

            return false
        }
    }

    init() {}

    /*
     Called automatically, just before instance deallocation takes place
     */
    deinit {}

    private func addBaseNode() throws {
        //Stanimals node:
        try tariWallet?.addBaseNodePeer(
            publicKey: PublicKey(hex: "90d8fe54c377ecabff383f7d8f0ba708c5b5d2a60590f326fbf1a2e74ea2441f"),
            address: "/onion3/plvcskybsckbfeubywjbmpnbm4kjqm2ip6kbwimakaim6xyucydpityd:18001")
    }

    private func transportType() throws -> TransportType {
        let torKey = ""
        let torBytes = [UInt8](torKey.utf8)
        let torIdentity = try ByteVector(byteArray: torBytes)

        let torCookieBytes = [UInt8](OnionManager.cookie)
        let torCookie = try ByteVector(byteArray: torCookieBytes)

        return try TransportType(
            controlServerAddress: "/ip4/127.0.0.1/tcp/39069",
            torPort: 39058, //TODO move ports to shared config
            torIdentity: torIdentity,
            torCookie: torCookie,
            socksUsername: "",
            socksPassword: ""
        )
    }

    func startTor() {
        TariEventBus.postToMainThread(.torConnectionProgress, sender: Int(0))
        OnionConnector().start(
            progress: { [weak self] percentage in
                TariEventBus.postToMainThread(.torConnectionProgress, sender: percentage)
            },
            completion: { [weak self] result in
                guard let self = self else { return }

                TariEventBus.postToMainThread(.torConnectionProgress, sender: Int(100))

                switch result {
                    case .success(let urlSessionConfiguration):
                        print("Tor connected")
                        TariEventBus.postToMainThread(.torConnected, sender: urlSessionConfiguration)
                    case .failure(let error):
                        print("Tor connection failed")
                        print(error)
                        TariEventBus.postToMainThread(.torConnectionFailed, sender: error)
                }
            }
        )
    }

    func createNewWallet() throws {
        try fileManager.createDirectory(atPath: storagePath, withIntermediateDirectories: true, attributes: nil)
        try fileManager.createDirectory(atPath: databasePath, withIntermediateDirectories: true, attributes: nil)

        print(TariLib.shared.databasePath)

        let privateKey = PrivateKey()

        //TODO use secure enclave
        let (hex, hexError) = privateKey.hex
        if hexError != nil {
            throw hexError!
        }

        UserDefaults.standard.set(hex, forKey: PRIVATE_KEY_STORAGE_KEY)

        let transport = try transportType()
        //let transport = try TransportType(listenerAddress: listenerAddress)

        let commsConfig = try CommsConfig(privateKey: privateKey, transport: transport, databasePath: databasePath, databaseName: DATABASE_NAME, publicAddress: publicAddress)

        tariWallet = try Wallet(commsConfig: commsConfig, loggingFilePath: TariLib.shared.logFilePath)

        try addBaseNode()
    }

    func startExistingWallet() throws {
        if let privateKeyHex = UserDefaults.standard.string(forKey: PRIVATE_KEY_STORAGE_KEY) {
            print("databasePath: ", databasePath)

            let privateKey = try PrivateKey(hex: privateKeyHex)
            let transport = try transportType()

            //TODO maybe on a simulator we don't use tor so development is sped up
            //let transport = try TransportType(listenerAddress: listenerAddress)
            let commsConfig = try CommsConfig(privateKey: privateKey, transport: transport, databasePath: databasePath, databaseName: DATABASE_NAME, publicAddress: publicAddress)
            tariWallet = try Wallet(commsConfig: commsConfig, loggingFilePath: TariLib.shared.logFilePath)
        } else {
            throw TariLibErrors.privateKeyNotFound
        }
    }
}
