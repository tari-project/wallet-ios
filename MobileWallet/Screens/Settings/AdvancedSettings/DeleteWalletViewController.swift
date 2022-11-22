//  DeleteWalletViewController.swift

/*
    Package MobileWallet
    Created by kutsal kaan bilgin on 2.11.2020
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
import SwiftUI

class DeleteWalletViewController: UIViewController {

    let navigationBar = NavigationBar()
    let tableView = UITableView(frame: .zero, style: .grouped)
    let menuItem = SystemMenuTableViewCellItem(
        title: localized("settings.item.delete_wallet"),
        hasArrow: false,
        isDestructive: true
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        view.backgroundColor = Theme.shared.colors.settingsTableStyleBackground
        setupNavigationBar()
        setupNavigationBarSeparator()
        setupTableView()
    }

    private func setupNavigationBar() {
        navigationBar.title = localized("delete_wallet.title")
        navigationBar.verticalPositioning = .custom(24)
        navigationBar.backgroundColor = Theme.shared.colors.navigationBarBackground

        view.addSubview(navigationBar)
        navigationBar.translatesAutoresizingMaskIntoConstraints = false

        navigationBar.topAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.topAnchor
        ).isActive = true
        navigationBar.leadingAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.leadingAnchor
        ).isActive = true
        navigationBar.trailingAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.trailingAnchor
        ).isActive = true

        if modalPresentationStyle == .popover {
            navigationBar.heightAnchor.constraint(
                equalToConstant: 58
            ).isActive = true
        } else {
            navigationBar.heightAnchor.constraint(
                equalToConstant: 50
            ).isActive = true
            navigationBar.verticalPositioning = .center
        }

        let stubView = UIView()
        stubView.backgroundColor = navigationBar.backgroundColor
        view.addSubview(stubView)
        stubView.translatesAutoresizingMaskIntoConstraints = false

        stubView.topAnchor.constraint(
            equalTo: view.topAnchor
        ).isActive = true
        stubView.leadingAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.leadingAnchor
        ).isActive = true
        stubView.trailingAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.trailingAnchor
        ).isActive = true
        stubView.bottomAnchor.constraint(
            equalTo: navigationBar.topAnchor
        ).isActive = true
    }

    private func setupNavigationBarSeparator() {
        let separator = UIView()
        separator.backgroundColor = Theme.shared.colors.settingsNavBarSeparator
        navigationBar.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.bottomAnchor.constraint(
            equalTo: navigationBar.bottomAnchor
        ).isActive = true
        separator.leadingAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.leadingAnchor
        ).isActive = true
        separator.trailingAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.trailingAnchor
        ).isActive = true
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }

    private func setupTableView() {
        tableView.register(
            SystemMenuTableViewCell.self,
            forCellReuseIdentifier: String(describing: SystemMenuTableViewCell.self)
        )
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorColor = Theme.shared.colors.settingsTableStyleBackground

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true

        tableView.delegate = self
        tableView.dataSource = self
    }

    private func displayWarningDialog() {
        
        let popUpModel = PopUpDialogModel(
            title: localized("delete_wallet.dialog.title"),
            message: localized("delete_wallet.dialog.description"),
            buttons: [
                PopUpDialogButtonModel(title: localized("backup_wallet_settings.switch.warning.confirm"), type: .destructive, callback: { [weak self] in self?.deleteWallet() }),
                PopUpDialogButtonModel(title: localized("backup_wallet_settings.switch.warning.cancel"), type: .textDimmed)
            ],
            hapticType: .error
        )
        
        PopUpPresenter.showPopUp(model: popUpModel)
    }

    private func deleteWallet() {
        Tari.shared.deleteWallet()
        Tari.shared.canAutomaticalyReconnectWallet = false
        BackupManager.shared.disableBackup()
        AppRouter.transitionToSplashScreen()
    }
}

extension DeleteWalletViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: SystemMenuTableViewCell.self),
            for: indexPath
        ) as! SystemMenuTableViewCell
        cell.configure(menuItem)
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = .zero
        cell.layoutMargins = .zero
        return cell
    }

    func tableView(_ tableView: UITableView,
                   viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear

        let warningLabel =  UILabel()
        warningLabel.numberOfLines = 0

        warningLabel.font = Theme.shared.fonts.settingsTableViewLastBackupDate
        warningLabel.textColor = Theme.shared.colors.settingsViewDescription
        warningLabel.text = localized("delete_wallet.warning")
        header.addSubview(warningLabel)
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        warningLabel.leadingAnchor.constraint(
            equalTo: header.leadingAnchor,
            constant: Theme.shared.sizes.appSidePadding
        ).isActive = true
        warningLabel.trailingAnchor.constraint(
            equalTo: header.trailingAnchor,
            constant: -Theme.shared.sizes.appSidePadding
        ).isActive = true
        warningLabel.topAnchor.constraint(
            equalTo: header.topAnchor,
            constant: Theme.shared.sizes.appSidePadding
        ).isActive = true
        header.bottomAnchor.constraint(
            equalTo: warningLabel.bottomAnchor,
            constant: Theme.shared.sizes.appSidePadding
        ).isActive = true
        return header
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65.0
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        displayWarningDialog()
        return nil
    }

}
