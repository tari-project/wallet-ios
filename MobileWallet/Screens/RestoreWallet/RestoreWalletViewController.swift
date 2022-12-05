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
import Combine

final class RestoreWalletViewController: SettingsParentTableViewController {
    private let localAuth = LAContext()

    private let pendingView = PendingView(title: localized("restore_pending_view.title"),
                                          definition: localized("restore_pending_view.description"))
    private let items: [SystemMenuTableViewCellItem] = [
        SystemMenuTableViewCellItem(title: RestoreCellTitle.iCloudRestore.rawValue),
        SystemMenuTableViewCellItem(title: RestoreCellTitle.dropboxRestore.rawValue),
        SystemMenuTableViewCellItem(title: RestoreCellTitle.phraseRestore.rawValue)
    ]
    
    private var cancellables = Set<AnyCancellable>()

    private enum RestoreCellTitle: CaseIterable {
        case iCloudRestore
        case dropboxRestore
        case phraseRestore

        var rawValue: String {
            switch self {
            case .iCloudRestore: return localized("restore_wallet.item.iCloud_restore")
            case .dropboxRestore: return localized("restore_wallet.item.dropbox_restore")
            case .phraseRestore: return localized("restore_wallet.item.phrase_restore")
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // MARK: - Actions
    
    private func showPasswordScreen(onCompletion: @escaping ((String?) -> Void)) {
        let controller = PasswordVerificationViewController(variation: .restore, restoreWalletAction: onCompletion)
        navigationController?.pushViewController(controller, animated: true)
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
        case .dropboxRestore: onDropboxRestoreAction()
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
        authenticateUserAndRestoreWallet(from: .iCloud)
    }
    
    private func onDropboxRestoreAction() {
        BackupManager.shared.dropboxPresentationController = self
        authenticateUserAndRestoreWallet(from: .dropbox)
    }

    private func onPhraseRestoreAction() {
        let viewController = RestoreWalletFromSeedsViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func authenticateUserAndRestoreWallet(from service: BackupManager.Service) {
        localAuth.authenticateUser(reason: .userVerification) { [weak self] in
            self?.restoreWallet(from: service, password: nil)
        }
    }
    
    private func restoreWallet(from service: BackupManager.Service, password: String?) {
        
        pendingView.showPendingView { [weak self] in
            
            guard let self else { return }
            
            BackupManager.shared.backupService(service).restoreBackup(password: password)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    switch completion {
                    case .finished:
                        BackupManager.shared.password = password
                        self?.endFlow(returnToSplashScreen: true)
                    case let .failure(error):
                        self?.handle(error: error, service: service)
                    }
                } receiveValue: { _ in }
                .store(in: &self.cancellables)
        }
    }
    
    private func showPasswordScreen(service: BackupManager.Service) {
        pendingView.hidePendingView { [weak self] in
            self?.showPasswordScreen { password in
                self?.restoreWallet(from: service, password: password)
            }
        }
    }
    
    private func endFlow(returnToSplashScreen: Bool) {
        pendingView.hidePendingView { [weak self] in
            guard returnToSplashScreen else { return }
            self?.returnToSplashScreen()
        }
    }

    private func returnToSplashScreen() {
        AppRouter.transitionToSplashScreen()
    }
    
    private func handle(error: Error, service: BackupManager.Service) {
        
        var errorMessage: String?
        
        switch error {
        case let error as BackupError where error == .passwordRequired:
            showPasswordScreen(service: service)
            return
        case let error as BackupError where error == .noRemoteBackup:
            errorMessage = localized("iCloud_backup.error.no_backup_exists")
        case let error as DropboxBackupError:
            errorMessage = error.message
        default:
            errorMessage = ErrorMessageManager.errorMessage(forError: error)
        }
        
        if let errorMessage {
            let model = MessageModel(title: localized("iCloud_backup.error.title.restore_wallet"), message: errorMessage, type: .error)
            PopUpPresenter.show(message: model)
        }
        
        endFlow(returnToSplashScreen: false)
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
