//  SettingsParentTableViewController.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 29.05.2020
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

class SettingsParentTableViewController: SettingsParentViewController {
    let tableView = UITableView(frame: .zero, style: .grouped)

    var backUpWalletItem: SystemMenuTableViewCellItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        willEnterForeground()
    }

    @objc private func willEnterForeground() {
        if TariLib.shared.walletState != .started {
            TariEventBus.onMainThread(self, eventType: .walletStateChanged) {
                [weak self]
                (sender) in
                guard let self = self else { return }
                let walletState = sender!.object as! TariLib.WalletState
                switch walletState {
                case .started:
                    TariEventBus.unregister(self, eventType: .walletStateChanged)
                    self.reloadTableViewWithAnimation()
                case .startFailed:
                    TariEventBus.unregister(self, eventType: .walletStateChanged)
                default:
                    break
                }
            }
        } else {
            reloadTableViewWithAnimation()
        }
    }

    func updateMarks() {
        if iCloudBackup.inProgress {
            backUpWalletItem?.mark = .progress
            backUpWalletItem?.markDescription = ICloudBackupState.inProgress.rawValue
            backUpWalletItem?.percent = iCloudBackup.progressValue
            return
        }

        backUpWalletItem?.percent = 0.0
        if BackupScheduler.shared.isBackupScheduled {
            backUpWalletItem?.mark = .scheduled
            backUpWalletItem?.markDescription = ICloudBackupState.scheduled.rawValue
        } else {
            backUpWalletItem?.mark = iCloudBackup.isValidBackupExists() ? .success : .attention
            if iCloudBackup.isValidBackupExists() {
                 backUpWalletItem?.markDescription = ICloudBackupState.upToDate.rawValue
            } else {
                backUpWalletItem?.markDescription = iCloudBackup.lastBackup != nil ? ICloudBackupState.outOfDate.rawValue : ""
            }
        }
    }
}

extension SettingsParentTableViewController {
    override func onUploadProgress(percent: Double, started: Bool, completed: Bool) {
        super.onUploadProgress(percent: percent, started: started, completed: completed)
        updateMarks()
        if completed || started {
            reloadTableViewWithAnimation()
        }
    }

    @objc func reloadTableViewWithAnimation() {
        updateMarks()
        UIView.transition(
            with: tableView,
            duration: 0.5,
            options: .transitionCrossDissolve,
            animations: {
                [weak self] in
                self?.tableView.reloadData()
            },
            completion: nil
        )
    }
}

extension SettingsParentTableViewController {
    override func setupViews() {
        super.setupViews()
        view.backgroundColor = Theme.shared.colors.settingsTableStyleBackground
        setupTableView()
    }

    func setupTableView() {
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
    }
}

extension SettingsParentTableViewController: OnionConnectorDelegate {
    func onTorConnProgress(_ progress: Int) {
        navigationBar.setProgress(Float(progress) / 100.0)
    }

    func onTorConnDifficulties(error: OnionError) {
        UserFeedback.showError(title: error.failureReason ?? "Onion Error", description: error.localizedDescription)
    }

    @objc func onTorConnFinished(_ configuration: BridgesConfuguration) {
        OnionConnector.shared.removeObserver(self)
        navigationBar.setProgress(1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.navigationBar.progressView.isHidden = true
            self.view.isUserInteractionEnabled = true
            self.tableView.reloadData()
        }
    }

    @objc func onTorConnDifficulties() {
        OnionConnector.shared.removeObserver(self)
        navigationBar.progressView.isHidden = true
        view.isUserInteractionEnabled = true
    }
}
