//  RestoreWalletFromSeedsViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 12/07/2021
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

import UIKit
import Combine

final class RestoreWalletFromSeedsViewController: SettingsParentViewController, OverlayPresentable {

    // MARK: - Properties

    private let mainView = RestoreWalletFromSeedsView()
    private let model = RestoreWalletFromSeedsModel()
    private var cancelables = Set<AnyCancellable>()

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFeedbacks()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        model.start()
    }

    // MARK: - Setups

    override func setupViews() {
        super.setupViews()
        setupConstraints()
    }

    private func setupConstraints() {

        view.addSubview(mainView)
        mainView.translatesAutoresizingMaskIntoConstraints = false

        let constraints = [
            mainView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            mainView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupFeedbacks() {

        model.viewModel.$isEmptyWalletCreated
            .sink { [weak self] isEmptyWalletCreated in
                guard isEmptyWalletCreated else { return }
                self?.showProgressOverlay()
            }
            .store(in: &cancelables)

        model.viewModel.$isConfimationEnabled
            .sink { [weak self] in self?.mainView.update(buttonIsEnabledStatus: $0) }
            .store(in: &cancelables)

        model.viewModel.$error
            .compactMap { $0 }
            .sink { PopUpPresenter.show(message: $0) }
            .store(in: &cancelables)

        model.viewModel.$isAutocompletionAvailable
            .assign(to: \.isTokenToolbarVisible, on: mainView.tokenView)
            .store(in: &cancelables)

        model.viewModel.$autocompletionTokens
            .assign(to: \.autocompletionTokens, on: mainView.tokenView)
            .store(in: &cancelables)

        model.viewModel.$autocompletionMessage
            .assign(to: \.autocompletionMessage, on: mainView.tokenView)
            .store(in: &cancelables)

        model.viewModel.$updatedInputText
            .assign(to: \.updatedInputText, on: mainView.tokenView)
            .store(in: &cancelables)

        model.viewModel.$seedWordModels
            .receive(on: DispatchQueue.main)
            .assign(to: \.seedWords, on: mainView.tokenView)
            .store(in: &cancelables)

        mainView.tokenView.$inputText
            .receive(on: DispatchQueue.main)
            .assign(to: \.inputText, on: model)
            .store(in: &cancelables)

        mainView.tokenView.onSelectSeedWord = { [weak self] in
            self?.model.removeSeedWord(row: $0)
        }

        mainView.tokenView.onRemovingCharacterAtFirstPosition = { [weak self] in
            self?.model.handleRemovingFirstCharacter(existingText: $0)
        }

        mainView.tokenView.onEndEditing = { [weak self] in
            self?.model.handleEndEditing()
        }

        mainView.selectBaseNodeButton.onTap = { [weak self] in
            self?.moveToSelectBaseNodeScene()
        }

        mainView.submitButton.onTap = { [weak self] in
            _ = self?.mainView.resignFirstResponder()
            self?.model.startRestoringWallet()
        }
    }

    // MARK: - Actions

    private func showProgressOverlay() {

        let overlay = SeedWordsRecoveryProgressViewController()

        overlay.onSuccess = {
            AppRouter.transitionToSplashScreen(isWalletConnected: true)
        }

        show(overlay: overlay)
    }

    private func moveToSelectBaseNodeScene() {
        navigationController?.pushViewController(SelectBaseNodeViewController(), animated: true)
    }
}
