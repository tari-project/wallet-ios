//  TransactionsViewController.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 13/01/2022
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

final class TransactionsViewController: UIViewController {
    
    // MARK: - Properties
    
    private let pageViewController = PageViewController()
    private let mainView = TransactionsView()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - View Lifecycle
    
    override func loadView() {
        view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageController()
        setupCallbacks()
    }
    
    // MARK: - Setups
    
    private func setupPageController() {
        pageViewController.controllers = [AddRecipientViewController(), RequestTariAmountViewController()]
        add(childController: pageViewController, containerView: mainView.contentView)
    }
    
    private func setupCallbacks() {
        
        mainView.toolbar.onButtonTap = { [weak self] in
            self?.pageViewController.move(toIndex: $0)
        }
        
        pageViewController.$pageIndex
            .sink { [weak self] in self?.handle(pageIndex: $0) }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    private func handle(pageIndex: CGFloat) {
        
        let roundedIndex = round(pageIndex)
        
        switch roundedIndex {
        case 0:
            mainView.navigationBar.title = localized("add_recipient.title")
        case 1:
            mainView.navigationBar.title = localized("request.navigation_bar.title")
        default:
            break
        }
        
        mainView.toolbar.indexPosition = pageIndex
    }
    
    // MARK: - Deeplinks
    
    func update(deeplinkParameters: DeepLinkParams?, publicKey: PublicKey) {
        let controller = pageViewController.controllers.compactMap { $0 as? AddRecipientViewController }.first
        controller?.deepLinkParams = deeplinkParameters
        controller?.onAdd(publicKey: publicKey)
    }
}
