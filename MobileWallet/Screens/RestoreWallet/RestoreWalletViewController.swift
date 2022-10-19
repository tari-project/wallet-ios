//  RestoreWalletViewController.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 27.05.2020
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
import LocalAuthentication

final class RestoreWalletViewController: SettingsParentTableViewController {
    private let localAuth = LAContext()

    private let pendingView = PendingView(title: localized("restore_pending_view.title"),
                                          definition: localized("restore_pending_view.description"))
    private let items: [SystemMenuTableViewCellItem] = [
        SystemMenuTableViewCellItem(title: RestoreCellTitle.iCloudRestore.rawValue),
        SystemMenuTableViewCellItem(title: RestoreCellTitle.phraseRestore.rawValue)
    ]

    private enum RestoreCellTitle: CaseIterable {
        case iCloudRestore
        case phraseRestore

        var rawValue: String {
            switch self {
            case .iCloudRestore: return localized("restore_wallet.item.iCloud_restore")
            case .phraseRestore: return localized("restore_wallet.item.phrase_restore")
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
}

extension RestoreWalletViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: SystemMenuTableViewCell.self),
            for: indexPath
        ) as! SystemMenuTableViewCell
        let item = items[indexPath.row]
        cell.configure(item)
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = .zero
        cell.layoutMargins = .zero
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        63
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let item = RestoreCellTitle.allCases[indexPath.row + indexPath.section]
        switch item {
        case .iCloudRestore: oniCloudRestoreAction()
        case .phraseRestore: onPhraseRestoreAction()
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear

        header.heightAnchor.constraint(equalToConstant: 15.0).isActive = true
        return header
    }

    private func oniCloudRestoreAction() {
        localAuth.authenticateUser(reason: .userVerification) { [weak self] in
            if self?.iCloudBackup.lastBackup?.isEncrypted == true {
                self?.navigationController?.pushViewController(
                    PasswordVerificationViewController(
                        variation: .restore,
                        restoreWalletAction: self?.restoreWallet(password:)
                    ),
                    animated: true
                )
            } else {
                self?.restoreWallet(password: nil)
            }
        }
    }

    private func onPhraseRestoreAction() {
        let viewController = RestoreWalletFromSeedsViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func restoreWallet(password: String?) {
        pendingView.showPendingView { [weak self] in
            ICloudBackup.shared.restoreWallet(password: password, completion: { [weak self] error in
                if let error = error {
                    PopUpPresenter.showMessageWithCloseButton(message: MessageModel(title: localized("iCloud_backup.error.title.restore_wallet"), message: error.localizedDescription, type: .error)) { [weak self] in
                        self?.pendingView.hidePendingView { [weak self] in
                            switch error {
                            case ICloudBackupError.noICloudBackupExists:
                                self?.returnToSplashScreen()
                            default:
                                break
                            }
                        }
                    }
                    return
                }

                self?.pendingView.hidePendingView { [weak self] in
                    self?.returnToSplashScreen()
                }
            })
        }
    }

    private func returnToSplashScreen() {
        AppRouter.transitionToSplashScreen()
    }
}

// MARK: Setup subviews
extension RestoreWalletViewController {
    override func setupNavigationBar() {
        super.setupNavigationBar()
        navigationBar.backgroundColor = .clear
        navigationBar.title = localized("restore_wallet.title")
    }

    override func setupNavigationBarSeparator() {
        return
    }
}
