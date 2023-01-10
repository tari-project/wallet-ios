//  AboutViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 26/05/2022
	Using Swift 5.0
	Running on macOS 12.3

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

final class AboutViewController: UIViewController {

    private let mainView = AboutView()
    private let model = AboutModel()

    private var cancellables = Set<AnyCancellable>()

    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
        model.generateData()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        model.$rowModels
            .map { $0.map { AboutView.CellModel(icon: $0.icon, text: $0.title) }}
            .sink { [weak self] in self?.mainView.cellModels = $0 }
            .store(in: &cancellables)

        model.$selectedURL
            .compactMap { $0 }
            .sink { WebBrowserPresenter.open(url: $0) }
            .store(in: &cancellables)

        mainView.onTapOnCreativeCommonsButton = { [weak self] in
            self?.model.selectCrativeCommonButton()
        }

        mainView.onSelectRow = { [weak self] in
            self?.model.select(index: $0)
        }
    }
}
