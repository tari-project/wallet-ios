//  TorBridgesViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 04/09/2023
	Using Swift 5.0
	Running on macOS 13.4

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

final class TorBridgesViewController: UIViewController {

    // MARK: - Properties

    private let model: TorBridgesModel
    private let mainView = TorBridgesView()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(model: TorBridgesModel) {
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
        model.updateStatus()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        model.$isConnectionPossible
            .sink { [weak self] in self?.mainView.isConnectButtonEnabled = $0 }
            .store(in: &cancellables)

        model.$selectedBridgesType
            .sink { [weak self] in self?.handle(selectedBridgesType: $0) }
            .store(in: &cancellables)

        model.$action
            .compactMap { $0 }
            .sink { [weak self] in self?.handle(action: $0) }
            .store(in: &cancellables)

        mainView.onSelectedRow = { [weak self] in
            self?.handle(selectedRowByUser: $0)
        }

        mainView.onConnectButtonTap = { [weak self] in
            self?.model.connect()
        }
    }

    // MARK: - Actions

    private func moveToCustomTorBridgesScene(bridges: String?) {
        let controller = CustomTorBridgesConstructor.buildScene(bridges: bridges)
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: - Handlers

    private func handle(selectedRowByUser: TorBridgesView.Row) {
        switch selectedRowByUser {
        case .noBridges:
            model.update(areCustomBridgesSelected: false)
        case .customBridges:
            model.update(areCustomBridgesSelected: true)
        }
    }

    private func handle(selectedBridgesType: TorBridgesModel.BridgesType) {
        switch selectedBridgesType {
        case .noBridges:
            mainView.select(row: .noBridges)
        case .customBridges:
            mainView.select(row: .customBridges)
        }
    }

    private func handle(action: TorBridgesModel.Action) {
        switch action {
        case let .setupCustomBridges(bridges):
            moveToCustomTorBridgesScene(bridges: bridges)
        }
    }
}
