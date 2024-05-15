//  RequestTariAmountViewController.swift

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

final class RequestTariAmountViewController: UIViewController {

    // MARK: - Properties

    private let mainView = RequestTariAmountView()
    private let model = RequestTariAmountModel()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - View Lifecycle

    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
    }

    // MARK: - Setups

    private func setupBindings() {

        model.$amount
            .assign(to: \.amount, on: mainView)
            .store(in: &cancellables)

        model.$isValidAmount
            .assign(to: \.areButtonsEnabled, on: mainView)
            .store(in: &cancellables)

        model.$qrCode
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.showQrCode(image: $0) }
            .store(in: &cancellables)

        model.$deeplink
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.showShareDialog(data: $0) }
            .store(in: &cancellables)

        mainView.onKeyboardKeyTap = { [weak self] in
            switch $0 {
            case let .key(character):
                self?.model.updateAmount(key: character)
            case .delete:
                self?.model.deleteLastCharacter()
            }
        }

        mainView.generateQrButton.onTap = { [weak self] in
            self?.model.generateQrRequest()
        }

        mainView.shareButton.onTap = { [weak self] in
            self?.model.shareActionRequest()
        }
    }

    // MARK: - Actions

    private func showQrCode(image: UIImage) {

        let controller = QRCodePresentationController(image: image)

        controller.onShareButtonTap = { [weak controller, weak self] in
            controller?.dismiss(animated: true) {
                self?.model.shareActionRequest()
            }
        }

        present(controller, animated: true)
    }

    private func showShareDialog(data: RequestTariAmountModel.DeeplinkData) {
        let controller = UIActivityViewController(activityItems: [data.message, data.deeplink], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = mainView.shareButton
        present(controller, animated: true)
    }
}
