//  HomeViewControllerDebugExtension.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/23
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

import UIKit

extension HomeViewController {
    private func showTariLibLogs() {
        let logsVC = DebugLogsTableViewController()
        present(logsVC, animated: true, completion: nil)
    }

    private func generateTestData() {
        do {
            try TariLib.shared.tariWallet!.generateTestData()
        } catch {
            let errorAlert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(errorAlert, animated: true, completion: nil)
        }
    }

    private func simulateReceieveTransactions() {
        do {
            try TariLib.shared.tariWallet!.generateTestReceiveTransaction()
        } catch {
            let errorAlert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(errorAlert, animated: true, completion: nil)
        }
    }

    private func simulateConfirmSendTransactions() {
        //TODO
    }

    private func deleteWallet() {
        let alert = UIAlertController(title: "Delete wallet", message: "This will erase all data and close the app.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Erase", style: .destructive, handler: { (_)in
            wipeApp()

            UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                exit(0)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)
    }

    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        let alert = UIAlertController(title: "Debug menu", message: nil, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "View TariLib logs", style: .default, handler: { (_)in
            self.showTariLibLogs()
        }))

        alert.addAction(UIAlertAction(title: "Generate test data", style: .default, handler: { (_)in
            self.generateTestData()
        }))

        alert.addAction(UIAlertAction(title: "Simulate recieve transaction", style: .default, handler: { (_)in
            self.simulateReceieveTransactions()
        }))

//        alert.addAction(UIAlertAction(title: "Simulate confirm sent transaction", style: .default, handler: { (_)in
//            self.simulateConfirmSendTransactions()
//        }))

        alert.addAction(UIAlertAction(title: "Delete wallet", style: .destructive, handler: { (_)in
            self.deleteWallet()
        }))

        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
}
