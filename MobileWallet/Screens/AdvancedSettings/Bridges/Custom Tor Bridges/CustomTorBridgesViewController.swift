//  CustomTorBridgesViewController.swift

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

final class CustomTorBridgesViewController: SecureViewController<CustomTorBridgesView> {

    // MARK: - Properties

    private let model: CustomTorBridgesModel
    private let imageDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(model: CustomTorBridgesModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallbacks()
        hideKeyboardWhenTappedAroundOrSwipedDown()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        model.$torBridges
            .sink { [weak self] in self?.mainView.update(torBridgesText: $0) }
            .store(in: &cancellables)

        model.$isConnectionPossible
            .sink { [weak self] in self?.mainView.isConnectButtonEnabled = $0 }
            .store(in: &cancellables)

        model.$endFlow
            .filter { $0 }
            .sink { [weak self] _ in self?.navigationController?.popViewController(animated: true) }
            .store(in: &cancellables)

        mainView.onConnectButtonTap = { [weak self] in
            self?.model.connect()
        }

        mainView.onSelectRow = { [weak self] in
            self?.handle(selectedRow: $0)
        }

        mainView.onTextUpdate = { [weak self] in
            self?.model.update(torBridges: $0)
        }
    }

    // MARK: - Actions

    private func update(torBridges: String) {
        model.update(torBridges: torBridges)
    }

    private func showQRCodeScanner() {
        AppRouter.presentQrCodeScanner(expectedDataTypes: [.torBridges]) { [weak self] data in
            guard case let .bridges(bridges) = data else { return }
            self?.update(torBridges: bridges)
        }
    }

    private func showImagePicker() {
        let controller = UIImagePickerController()
        controller.delegate = self
        controller.modalPresentationStyle = UIDevice.current.userInterfaceIdiom == .pad ? .automatic :.popover
        present(controller, animated: true, completion: nil)
    }

    // MARK: - Handlers

    private func handle(selectedRow: CustomTorBridgesView.Row) {

        switch selectedRow {
        case .input:
            return
        case .requestBridges:
            guard let url = URL(string: TariSettings.shared.torBridgesUrl) else { return }
            WebBrowserPresenter.open(url: url)
        case .scanQRCode:
            showQRCodeScanner()
        case .uploadQRCode:
            showImagePicker()
        }
    }
}

extension CustomTorBridgesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {

        picker.dismiss(animated: true)

        guard let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage, let ciImage = image.makeCIImage() else { return }
        guard let features = imageDetector?.features(in: ciImage) else { return }

        let torBridges = features
            .compactMap { $0 as? CIQRCodeFeature }
            .compactMap { $0.messageString }
            .joined()
            .findBridges()

        guard let torBridges else {
            PopUpPresenter.show(message: MessageModel(title: localized("custom_bridges.error.image_decode.title"), message: localized("custom_bridges.error.image_decode.description"), type: .error))
            return
        }

        update(torBridges: torBridges)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
