//  WipeAppContents.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/13
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

/*
     Delete all app content and settings. Used only for UITesting on a simulator.
 */
func wipeIfRequiredOnSimulator() {
    #if !targetEnvironment(simulator)
        return
    #endif

    if !CommandLine.arguments.contains("-wipe-app") {
        return
    }

    print("***** Wiping app *****")

    let fileManager = FileManager.default

    let documentsURL =  fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let databasePath = documentsURL.appendingPathComponent("tari_wallet").path

    if fileManager.fileExists(atPath: databasePath, isDirectory: nil) {
        do {
            try fileManager.removeItem(at: URL(fileURLWithPath: databasePath))
        } catch {
            print(error)
            fatalError("Failed to delete documents directory")
        }
    }

    //Remove all user defaults
    let domain = Bundle.main.bundleIdentifier!
    UserDefaults.standard.removePersistentDomain(forName: domain)
    UserDefaults.standard.synchronize()

    print("***** Wipe complete *****")
}
