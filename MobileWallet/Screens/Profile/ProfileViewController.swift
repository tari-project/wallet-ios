//  ProfileViewController.swift

/*
	Package MobileWallet
	Created by Gabriel Lupu on 04/02/2020
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
import Combine
import YatLib

final class ProfileViewController: UIViewController {
    
    // MARK: - Properties
    
    private let mainView = ProfileView()
    private let model = ProfileModel()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - View Lifecycle
    
    override func loadView() {
        view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        Tracker.shared.track("/home/profile", "Profile - Wallet Info")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.updateYatIdData()
    }
    
    // MARK: - Setups
    
    private func setupBindings() {
        
        model.$qrCodeImage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .assign(to: \.qrCodeImage, on: mainView)
            .store(in: &cancellables)
        
        model.$emojiData
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.update(emojiID: $0.emojiID, hex: $0.hex, copyText: $0.copyText, tooltopText: $0.tooltipText) }
            .store(in: &cancellables)
        
        model.$description
            .receive(on: DispatchQueue.main)
            .assign(to: \.text, on: mainView.middleLabel)
            .store(in: &cancellables)
        
        model.$isReconnectButtonVisible
            .map { !$0 }
            .receive(on: DispatchQueue.main)
            .assign(to: \.isHidden, on: mainView.reconnectYatButton)
            .store(in: &cancellables)
        
        model.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.show(error: $0) }
            .store(in: &cancellables)
        
        model.$yatButtonState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(yatButtonState: $0) }
            .store(in: &cancellables)
        
        model.$yatPublicKey
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.showYatOnboardingFlow(publicKey: $0) }
            .store(in: &cancellables)
        
        mainView.yatButton.onTap = { [weak self] in
            self?.model.toggleVisibleData()
        }
        
        mainView.reconnectYatButton.onTap = { [weak self] in
            self?.model.reconnectYat()
        }
    }
    
    // MARK: - Actions
    
    private func handle(yatButtonState: ProfileModel.YatButtonState) {
        switch yatButtonState {
        case  .hidden:
            mainView.hideYatButton()
        case .loading:
            mainView.showYatButtonSpinner()
        case .off:
            mainView.updateYatButton(isOn: false)
        case .on:
            mainView.updateYatButton(isOn: true)
        }
    }
    
    private func show(error: MessageModel) {
        PopUpPresenter.show(message: error)
    }
    
    private func showYatOnboardingFlow(publicKey: String) {
        Yat.integration.showOnboarding(onViewController: self, records: [
            YatRecordInput(tag: .XTRAddress, value: publicKey)
        ])
    }
}
