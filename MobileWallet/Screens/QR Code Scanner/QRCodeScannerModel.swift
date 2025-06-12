//  QRCodeScannerModel.swift

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

import Combine

enum QRCodeData {
    case deeplink(DeepLinkable)
    case bridges(String)
    case base64Address(String)
}

final class QRCodeScannerModel {

    struct ActionModel {
        let title: String
        let isValid: Bool
    }

    enum DataType {
        case deeplink(DeeplinkType)
        case torBridges
        case base64Address
    }

    enum CompletionAction {
        case unexpectedData(() -> Void)
        case expectedData(QRCodeData)
    }

    // MARK: - View Model

    @Published private(set) var actionModel: ActionModel?
    @Published private(set) var onCompletion: CompletionAction?

    // MARK: - Properties

    private let videoCaptureManager: VideoCaptureManager
    private let transactionFormatter = TransactionFormatter()
    private let expectedDataTypes: [DataType]
    private let disabledDataTypes: [DataType]

    private var scannedData: VideoCaptureManager.ScanResult?
    private var cancellables = Set<AnyCancellable>()

    private var expectedDeeplinkTypes: [DeeplinkType] {
        expectedDataTypes.compactMap {
            guard case let .deeplink(deeplink) = $0 else { return nil }
            return deeplink
        }
    }

    private var expectTorBridges: Bool {
        expectedDataTypes.contains {
            guard case .torBridges = $0 else { return false }
            return true
        }
    }

    private var expectBase64Address: Bool {
        expectedDataTypes.contains {
            guard case .base64Address = $0 else { return false }
            return true
        }
    }

    private var disabledDeeplinkTypes: [DeeplinkType] {
        disabledDataTypes.compactMap {
            guard case let .deeplink(deeplink) = $0 else { return nil }
            return deeplink
        }
    }

    private var disabledTorBridges: Bool {
        disabledDataTypes.contains {
            guard case .torBridges = $0 else { return false }
            return true
        }
    }

    // MARK: - Initialisers

    init(videoCaptureManager: VideoCaptureManager, expectedDataTypes: [DataType], disabledDataTypes: [DataType]) {
        self.videoCaptureManager = videoCaptureManager
        self.expectedDataTypes = expectedDataTypes
        self.disabledDataTypes = disabledDataTypes
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        videoCaptureManager.$result
            .sink { [weak self] in self?.handle(scanResult: $0) }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func startVideoCapture() {
        videoCaptureManager.startSession()
    }

    func stopVideoCapture() {
        videoCaptureManager.stopSession()
    }

    func useScannedQRCode() {
        guard let scannedData else { return }

        switch scannedData {
        case let .validDeeplink(deeplink):
            onCompletion = .unexpectedData({ try? DeeplinkHandler.handle(deeplink: deeplink, showDefaultDialogIfNeeded: false) })
        case let .torBridges(bridges):
            onCompletion = .unexpectedData({ AppRouter.presentCustomTorBridgesForm(bridges: bridges) })
        case let .base64Address(address):
            onCompletion = .expectedData(.base64Address(address))
        case .invalid:
            break
        }
    }

    func dismissScannedQRCode() {
        actionModel = nil
        scannedData = nil
    }

    // MARK: - Handlers

    private func handle(scanResult: VideoCaptureManager.ScanResult?) {

        guard actionModel?.isValid != true, onCompletion == nil, let scanResult else { return }

        switch scanResult {
        case let .validDeeplink(deeplink):
            handle(validDeeplink: deeplink, scanResult: scanResult)
        case let .torBridges(torBridges):
            handle(torBridges: torBridges, scanResult: scanResult)
        case let .base64Address(address):
            handle(base64Address: address, scanResult: scanResult)
        case .invalid:
            handleInvalidData()
        }
    }

    private func handle(validDeeplink: DeepLinkable, scanResult: VideoCaptureManager.ScanResult) {

        guard !disabledDeeplinkTypes.contains(where: { $0 == validDeeplink.type }) else { return }

        guard expectedDeeplinkTypes.contains(where: { $0 == validDeeplink.type }) else {
            handle(unexpectedDeeplink: validDeeplink, scanResult: scanResult)
            return
        }

        onCompletion = .expectedData(.deeplink(validDeeplink))
    }

    private func handle(torBridges: String, scanResult: VideoCaptureManager.ScanResult) {

        guard !disabledTorBridges else { return }

        guard expectTorBridges else {
            actionModel = ActionModel(title: localized("qr_code_scanner.labels.actions.tor_bridges"), isValid: true)
            scannedData = scanResult
            return
        }

        onCompletion = .expectedData(.bridges(torBridges))
    }

    private func handle(base64Address: String, scanResult: VideoCaptureManager.ScanResult) {
        guard expectBase64Address else {
            handleInvalidData()
            return
        }

        guard let addressComponents = try? TariAddress(base58: base64Address).components else {
            handleInvalidData()
            return
        }

        onCompletion = .expectedData(.base64Address(base64Address))
    }

    private func handleInvalidData() {
        guard actionModel?.isValid != false else { return }
        actionModel = ActionModel(title: localized("qr_code_scanner.labels.actions.invalid"), isValid: false)
        scannedData = nil
    }

    private func handle(unexpectedDeeplink: DeepLinkable, scanResult: VideoCaptureManager.ScanResult) {

        if unexpectedDeeplink.type == .paperWallet {
            self.scannedData = scanResult
            useScannedQRCode()
            return
        }

        Task {
            do {
                let actionTitle = try await actionTitle(deeplink: unexpectedDeeplink)
                actionModel = ActionModel(title: actionTitle, isValid: true)
                self.scannedData = scanResult
            } catch {
                handleInvalidData()
            }
        }
    }

    // MARK: - Data

    private func actionTitle(deeplink: DeepLinkable) async throws -> String {
        switch deeplink.type {
        case .transactionSend:
            guard let deeplink = deeplink as? TransactionsSendDeeplink else { return "" }
            try await transactionFormatter.updateContactsData()
            let address = try TariAddress(base58: deeplink.receiverAddress)
            let contactName = try transactionFormatter.contact(components: address.components)?.name ?? address.components.formattedCoreAddress
            return localized("qr_code_scanner.labels.actions.transaction_send", arguments: contactName)
        case .baseNodesAdd:
            return localized("qr_code_scanner.labels.actions.base_node_add")
        case .contacts, .profile:
            return localized("qr_code_scanner.labels.actions.contacts")
        case .paperWallet, .login:
            return ""
        }
    }
}
