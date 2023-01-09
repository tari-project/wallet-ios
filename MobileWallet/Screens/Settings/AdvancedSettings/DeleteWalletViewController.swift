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

import UIKit
import TariCommon

class DeleteWalletViewController: SettingsParentTableViewController {

    let menuItem = SystemMenuTableViewCellItem(
        title: localized("settings.item.delete_wallet"),
        hasArrow: false,
        isDestructive: true
    )

    override func setupViews() {
        super.setupViews()
        tableView.register(type: SystemMenuTableViewCell.self)
        tableView.delegate = self
        tableView.dataSource = self
    }

    override func setupNavigationBar() {
        super.setupNavigationBar()
        navigationBar.title = localized("delete_wallet.title")
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

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        DeleteWalletHeaderView()
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

private final class DeleteWalletHeaderView: DynamicThemeHeaderFooterView {

    // MARK: - Subiews

    @View private var label: UILabel = {
        let view = UILabel()
        view.font = Theme.shared.fonts.settingsTableViewLastBackupDate
        view.text = localized("delete_wallet.warning")
        view.numberOfLines = 0
        return view
    }()

    // MARK: - Initialisers

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupConstraints() {

        contentView.addSubview(label)

        let constraints = [
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22.0),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22.0),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22.0),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -22.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        label.textColor = theme.text.body
    }
}
