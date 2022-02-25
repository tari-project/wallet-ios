//  SettingsParentViewController.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 28.05.2020
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

class BaseSettingsView: UIView {
    
    // MARK: - Subview
    
    @View private var statusBarBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.shared.colors.navigationBarBackground
        return view
    }()
    
    @View private(set) var navigationBar: NavigationBar = {
       let view = NavigationBar()
        view.title = localized("settings.title")
        view.verticalPositioning = .custom(24)
        view.backgroundColor = Theme.shared.colors.navigationBarBackground
        return view
    }()
    
    @View private(set) var separator: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.shared.colors.settingsNavBarSeparator
        return view
    }()
    
    // MARK: - Initialisers
    
    init() {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupViews() {
        backgroundColor = Theme.shared.colors.appBackground
        navigationBar.verticalPositioning = .center
    }
    
    private func setupConstraints() {
        
        [statusBarBackgroundView, navigationBar, separator].forEach(addSubview)
        
        let constraints = [
            statusBarBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            statusBarBackgroundView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            statusBarBackgroundView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            statusBarBackgroundView.bottomAnchor.constraint(equalTo: navigationBar.topAnchor),
            navigationBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            navigationBar.heightAnchor.constraint(equalToConstant: 50.0),
            separator.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1.0)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
}

class SettingsParentViewController: UIViewController {
    let navigationBar = NavigationBar()

    lazy var iCloudBackup: ICloudBackup = {
           let backup = ICloudBackup.shared
           backup.addObserver(self)
           return backup
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        styleNavigatorBar(isHidden: true)
        setupViews()
    }
}

extension SettingsParentViewController: ICloudBackupObserver {
    @objc func onUploadProgress(percent: Double, started: Bool, completed: Bool) {

    }

    @objc func failedToCreateBackup(error: Error) {

    }
}

extension SettingsParentViewController {
    @objc func setupViews() {
        view.backgroundColor = Theme.shared.colors.appBackground
        setupNavigationBar()
        setupNavigationBarSeparator()
    }

    @objc func setupNavigationBar() {
        navigationBar.title = localized("settings.title")
        navigationBar.verticalPositioning = .custom(24)
        navigationBar.backgroundColor = Theme.shared.colors.navigationBarBackground

        view.addSubview(navigationBar)
        navigationBar.translatesAutoresizingMaskIntoConstraints = false

        navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        navigationBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        navigationBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true

        if modalPresentationStyle == .popover {
            navigationBar.heightAnchor.constraint(equalToConstant: 58).isActive = true
        } else {
            navigationBar.heightAnchor.constraint(equalToConstant: 50).isActive = true
            navigationBar.verticalPositioning = .center
        }

        let stubView = UIView()
        stubView.backgroundColor = navigationBar.backgroundColor
        view.addSubview(stubView)
        stubView.translatesAutoresizingMaskIntoConstraints = false

        stubView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        stubView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        stubView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        stubView.bottomAnchor.constraint(equalTo: navigationBar.topAnchor).isActive = true
    }

    @objc func setupNavigationBarSeparator() {
        let separator = UIView()
        separator.backgroundColor = Theme.shared.colors.settingsNavBarSeparator

        navigationBar.addSubview(separator)

        separator.translatesAutoresizingMaskIntoConstraints = false

        separator.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
        separator.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        separator.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
}
