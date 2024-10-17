//  QRCodeScannerViewController.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 11/07/2023
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
import AVFoundation
import Combine

final class QRCodeScannerViewController: SecureViewController<QRCodeScannerView> {

    // MARK: - Properties

    var onExpectedDataScan: ((QRCodeData) -> Void)?

    private let model: QRCodeScannerModel

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(model: QRCodeScannerModel, videoSession: AVCaptureSession) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
        self.mainView.videoSession = videoSession
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.startVideoCapture()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        model.stopVideoCapture()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        model.$actionModel
            .sink { [weak self] in self?.hanlde(actionModel: $0) }
            .store(in: &cancellables)

        model.$onCompletion
            .compactMap { $0 }
            .sink { [weak self] in self?.handle(completionAction: $0) }
            .store(in: &cancellables)

        mainView.onCloseButtonTap = { [weak self] in
            self?.dismissScene(onCompletion: nil)
        }

        mainView.onApproveButtonTap = { [weak self] in
            self?.model.useScannedQRCode()
        }

        mainView.onCancelButtonTap = { [weak self] in
            self?.model.dismissScannedQRCode()
        }
    }

    // MARK: - Handlers

    private func hanlde(actionModel: QRCodeScannerModel.ActionModel?) {
        guard let actionModel else {
            mainView.update(actionViewModel: nil)
            return
        }
        mainView.update(actionViewModel: QRCodeScannerView.ActionViewModel(title: actionModel.title, actionType: actionModel.isValid ? .normal : .error))
    }

    // MARK: - Actions

    private func handle(completionAction: QRCodeScannerModel.CompletionAction) {
        switch completionAction {
        case let .unexpectedData(action):
            dismissScene(onCompletion: action)
        case let .expectedData(data):
            dismissScene(onCompletion: { [weak self] in self?.onExpectedDataScan?(data) })
        }
    }

    private func dismissScene(onCompletion: (() -> Void)?) {
        dismiss(animated: true, completion: onCompletion)
    }
}
