//  ReceiveViewController.swift

/*
	Package MobileWallet
	Created by Konrad Faltyn on 28/03/2025
	Using Swift 6.0
	Running on macOS 15.3

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

import Foundation
import TariCommon
import Combine

class ReceiveViewController: SecureViewController<ReceiveView> {

    private let model = ReceiveModel()
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupCallbacks()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        model.generateQrRequest()
    }

    func setupViews() {
        mainView.navigationBar.title = "Receive"
    }

    func setupCallbacks() {
        model.$qrCode
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.qrCode = $0 }
            .store(in: &cancellables)

        model.$deeplink
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.showShareDialog(data: $0) }
            .store(in: &cancellables)

        model.$base64Address
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.baseAddressLabel.text = $0.shortenedMiddle(to: 20)}
            .store(in: &cancellables)

        model.$emojiAddress
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mainView.emojiAddressLabel.text = $0.shortenedMiddle(to: 10)}
            .store(in: &cancellables)

        mainView.onShareButonTap = { [weak self] in
            self?.model.shareActionRequest()
        }

        mainView.onCopyBaseButonTap = { [weak self] in
            UIPasteboard.general.string = self?.model.base64Address
            UIView.transition(with: self?.mainView.copyBaseButton ?? UIView(), duration: 0.2, options: .transitionCrossDissolve) {
                self?.mainView.copyBaseButton.setTitle("Copied", for: .normal)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                UIView.transition(with: self?.mainView.copyBaseButton ?? UIView(), duration: 0.2, options: .transitionCrossDissolve) {
                    self?.mainView.copyBaseButton.setTitle("Copy", for: .normal)
                }
            }
        }

        mainView.onCopyEmojiButonTap = { [weak self] in
            UIPasteboard.general.string = self?.model.emojiAddress
            UIView.transition(with: self?.mainView.copyEmojiButton ?? UIView(), duration: 0.2, options: .transitionCrossDissolve) {
                self?.mainView.copyEmojiButton.setTitle("Copied", for: .normal)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                UIView.transition(with: self?.mainView.copyEmojiButton ?? UIView(), duration: 0.2, options: .transitionCrossDissolve) {
                    self?.mainView.copyEmojiButton.setTitle("Copy", for: .normal)
                }
            }
        }
    }

    func update() {

    }

    private func showShareDialog(data: ReceiveModel.DeeplinkData) {
        let controller = UIActivityViewController(activityItems: [data.message, data.deeplink], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = mainView.shareButton
        present(controller, animated: true)
    }
}

extension String {
    func shortenedMiddle(to length: Int) -> String {
        guard self.count > length, length > 3 else { return self }

        let keep = length - 1 // account for "…"
        let startCount = Int(ceil(Double(keep) / 2.0))
        let endCount = keep - startCount

        let start = self.prefix(startCount)
        let end = self.suffix(endCount)

        return "\(start)…\(end)"
    }
}
