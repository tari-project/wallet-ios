//  VerifySeedWordsViewController.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 23/02/2022
	Using Swift 5.0
	Running on macOS 12.1

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

final class VerifySeedWordsViewController: UIViewController {
    
    // MARK: - Properties
    
    private let mainView = VerifySeedWordsView()
    private let model: VerifySeedWordsModel
    
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers
    
    init(model: VerifySeedWordsModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 15, *) {} else {
            model.fetchData()
        }
    }
    
    // MARK: - Setups
    
    private func setupCallbacks() {
        
        model.$selectedTokenModels
            .assign(to: \.seedWords, on: mainView.tokensView)
            .store(in: &cancellables)
        
        model.$availableTokenModels
            .assign(to: \.seedWords, on: mainView.selectableTokensView)
            .store(in: &cancellables)
        
        model.$isSelectedTokenTipVisible
            .assign(to: \.isInfoLabelVisible, on: mainView)
            .store(in: &cancellables)
        
        model.$isSuccessVisible
            .assign(to: \.isSuccessViewVisible, on: mainView)
            .store(in: &cancellables)
        
        model.$isErrorVisible
            .assign(to: \.isErrorVisible, on: mainView)
            .store(in: &cancellables)
        
        model.$isContinueButtonEnabled
            .map { $0 ? .normal : .disabled }
            .assign(to: \.variation, on: mainView.continueButton)
            .store(in: &cancellables)
        
        model.$shouldEndFlow
            .filter { $0 }
            .sink { [weak self] _ in self?.endFlow() }
            .store(in: &cancellables)
        
        mainView.tokensView.onSelectSeedWord = { [weak self] in
            self?.model.removeSelectedToken(index: $0)
        }
        
        mainView.selectableTokensView.onSelectSeedWord = { [weak self] in
            self?.model.selectToken(index: $0)
        }
        
        mainView.continueButton.onTap = { [weak self] in
            self?.model.continueFlowRequest()
        }
    }
    
    // MARK: - Actions
    
    private func endFlow() {
        guard let controller = navigationController?.viewControllers.first(where: { $0 is BackupWalletSettingsViewController }) else { return }
        navigationController?.popToViewController(controller, animated: true)
    }
}
