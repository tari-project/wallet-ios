//  SeedWordsListViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 07/03/2022
	Using Swift 5.0
	Running on macOS 12.2

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

final class SeedWordsListViewController: UIViewController {

    // MARK: - Properties

    private let mainView = SeedWordsListView()
    private let model: SeedWordsListModel

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(model: SeedWordsListModel, backButtonType: NavigationBar.BackButtonType) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
        mainView.navigationBar.backButtonType = backButtonType
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
        model.fetchSeedWords()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mainView.isAnimationEnabled = true
    }

    // MARK: - Setups

    private func setupCallbacks() {

        model.$seedWords
            .assign(to: \.seedWords, on: mainView)
            .store(in: &cancellables)

        model.$isContinueButtonEnabled
            .assign(to: \.isContinueButtonEnabled, on: mainView)
            .store(in: &cancellables)

        mainView.onCheckBoxStateChanged = { [weak self] in
            self?.model.update(checkBoxStatus: $0)
        }

        mainView.continueButton.onTap = { [weak self] in
            self?.moveToVerifySeedWordsScene()
        }
    }

    // MARK: - Actions

    private func moveToVerifySeedWordsScene() {
        let inputData = VerifySeedWordsModel.InputData(seedWords: model.seedWords)
        let controller = VerifySeedWordsConstructor.buildScene(inputData: inputData)
        navigationController?.pushViewController(controller, animated: true)
    }
}
