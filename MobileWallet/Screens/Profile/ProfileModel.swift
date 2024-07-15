//  ProfileModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 12/01/2022
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
import YatLib

final class ProfileModel {

    enum AddressType {
        case address(components: TariAddressComponents)
        case yat(String)
    }

    enum YatButtonState {
        case hidden
        case loading
        case off
        case on
    }

    enum Action {
        case showQRPopUp
        case shareQR(image: UIImage)
        case shareLink(url: URL)
        case showBLEWaitingForReceiverDialog
        case showBLESuccessDialog
        case showBLEFailureDialog(message: String?)
    }

    // MARK: - View Model

    @Published var name: String?
    @Published private(set) var addressType: AddressType?
    @Published private(set) var isYatOutOfSync: Bool = false
    @Published private(set) var errorMessage: MessageModel?
    @Published private(set) var yatButtonState: YatButtonState = .hidden
    @Published private(set) var yatAddress: String?
    @Published private(set) var action: Action?

    // MARK: - Properties

    private(set) var addressComponents: TariAddressComponents?

    private var walletAddress: TariAddress?
    private var yat: String?
    private var bleTask: BLECentralTask?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init() {
        updateData()
        setupCallbacks()
    }

    // MARK: - Setups

    private func setupCallbacks() {

        $name
            .sink { UserSettingsManager.name = $0 }
            .store(in: &cancellables)

        $yatButtonState
            .sink { [weak self] in self?.update(yatButtonState: $0) }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func toggleVisibleData() {
        switch yatButtonState {
        case .off:
            yatButtonState = .on
        case .on:
            yatButtonState = .off
        case .hidden, .loading:
            return
        }
    }

    func reconnectYat() {
        yatAddress = try? walletAddress?.byteVector.hex
    }

    private func updateData() {

        name = UserSettingsManager.name

        do {
            walletAddress = try Tari.shared.walletAddress
            guard let walletAddress else { return }
            addressComponents = try walletAddress.components
        } catch {
            addressComponents = nil
            errorMessage = MessageModel(title: localized("profile_view.error.qr_code.title"), message: localized("wallet.error.failed_to_access"), type: .error)
        }
    }

    func updateYatIdData() {

        guard let connectedYat = TariSettings.shared.walletSettings.connectedYat else { return }

        yatButtonState = .loading

        Yat.api.emojiID.lookupEmojiIDPaymentPublisher(emojiId: connectedYat, tags: YatRecordTag.XTRAddress.rawValue)
            .sink(
                receiveCompletion: { [weak self] in self?.handle(completion: $0) },
                receiveValue: { [weak self] in self?.handle(paymentAddressResponse: $0, yat: connectedYat) }
            )
            .store(in: &cancellables)
    }

    private func update(yatButtonState: YatButtonState) {
        switch yatButtonState {
        case .on:
            guard let yat else { return }
            addressType = .yat(yat)
        case .off, .loading, .hidden:
            guard let addressComponents else { return }
            addressType = .address(components: addressComponents)
        }
    }

    func generateQrCode() {

        action = .showQRPopUp

        Task {
            guard let deeplink = try? makeDeeplink(), let deeplinkData = deeplink.absoluteString.data(using: .utf8), let image = await QRCodeFactory.makeQrCode(data: deeplinkData) else { return }
            action = .shareQR(image: image)
        }
    }

    func generateLink() {
        guard let deeplink = try? makeDeeplink() else { return }
        action = .shareLink(url: deeplink)
    }

    func shareContactUsingBLE() {

        guard let deeplink = try? makeDeeplink(), let payload = deeplink.absoluteString.data(using: .utf8) else { return }

        action = .showBLEWaitingForReceiverDialog

        let bleTask = BLECentralTask(service: BLEConstants.contactBookService.uuid, characteristic: BLEConstants.contactBookService.characteristics.contactsShare)
        self.bleTask = bleTask

        Task {
            do {
                guard try await bleTask.findAndWrite(payload: payload) else { return }
                action = .showBLESuccessDialog
            } catch {
                handle(bleWriteError: error)
            }
        }
    }

    func cancelBLESharing() {
        bleTask?.cancel()
    }

    private func makeDeeplink() throws -> URL? {
        guard let alias = name else { return nil }
        let hex = try Tari.shared.walletAddress.byteVector.hex
        let deeplinkModel = UserProfileDeeplink(alias: alias, tariAddress: hex)
        return try DeepLinkFormatter.deeplink(model: deeplinkModel)
    }

    private func show(error: Error?) {
        yatButtonState = .hidden
        self.errorMessage = ErrorMessageManager.errorModel(forError: error)
    }

    // MARK: - Handlers

    private func handle(paymentAddressResponse: PaymentAddressResponse, yat: String) {

        self.yat = yat
        yatButtonState = .off

        guard let walletAddress = paymentAddressResponse.result?[YatRecordTag.XTRAddress.rawValue]?.address else {
            isYatOutOfSync = true
            return
        }

        isYatOutOfSync = walletAddress != (try? self.walletAddress?.byteVector.hex)
    }

    private func handle(completion: Subscribers.Completion<APIError>) {
        switch completion {
        case .finished:
            break
        case let .failure(error):
            show(error: error)
        }
    }

    private func handle(bleWriteError error: Error) {

        let message: String?

        if let error = error as? BLECentralManager.BLECentralError {
            message = error.errorMessage
        } else {
            message = ErrorMessageManager.errorMessage(forError: error)
        }

        action = .showBLEFailureDialog(message: message)
    }
}
