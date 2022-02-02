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
    
    struct EmojiData {
        let emojiID: String
        let hex: String?
        let copyText: String
        let tooltipText: String?
    }
    
    enum YatButtonState {
        case hidden
        case loading
        case off
        case on
    }
    
    // MARK: - View Model
    
    @Published private(set) var emojiData: EmojiData?
    @Published private(set) var description: String?
    @Published private(set) var isReconnectButtonVisible: Bool = false
    @Published private(set) var qrCodeImage: UIImage?
    @Published private(set) var error: SimpleErrorModel?
    @Published private(set) var yatButtonState: YatButtonState = .hidden
    @Published private(set) var yatPublicKey: String?
    
    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    private var publicKey: PublicKey?
    private var yat: String?
    private var isYatOutOfSync = false
    
    private var walletDescription: String {
        localized("profile_view.error.qr_code.description.with_param", arguments: NetworkManager.shared.selectedNetwork.tickerSymbol)
    }
    
    // MARK: - Initialisers
    
    init() {
        setupCallbacks()
    }
    
    // MARK: - Setups
    
    private func setupCallbacks() {
        
        TariLib.shared.walletStatePublisher
            .filter {
                switch $0 {
                case .started, .startFailed:
                    return true
                case .notReady, .starting:
                    return false
                }
            }
            .sink { [weak self] _ in self?.updateData() }
            .store(in: &cancellables)
        
        $yatButtonState
            .sink { [weak self] in self?.updatePresentedData(yatButtonState: $0) }
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
        yatPublicKey = publicKey?.hex.0
    }
    
    private func updateData() {
        
        guard let publicKey = TariLib.shared.tariWallet?.publicKey.0, publicKey.hexDeeplink.1 == nil, let deeplinkData = publicKey.hexDeeplink.0.data(using: .utf8) else {
            qrCodeImage = nil
            emojiData = nil
            error = SimpleErrorModel(title: localized("profile_view.error.qr_code.title"), description: localized("wallet.error.failed_to_access"))
            return
        }
        
        self.publicKey = publicKey
        qrCodeImage = QRCodeFactory.makeQrCode(data: deeplinkData)
        
        updateYatIdData()
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
    
    // MARK: - Handlers
    
    private func handle(paymentAddressResponse: PaymentAddressResponse, yat: String) {
        
        self.yat = yat
        yatButtonState = .off
        
        guard let walletAddress = paymentAddressResponse.result?[YatRecordTag.XTRAddress.rawValue]?.address else {
            isYatOutOfSync = true
            return
        }
        
        isYatOutOfSync = walletAddress != publicKey?.hex.0
    }
    
    private func handle(completion: Subscribers.Completion<APIError>) {
        switch completion {
        case .finished:
            break
        case let .failure(error):
            show(error: error)
        }
    }
    
    private func show(error: Error?) {
        yatButtonState = .hidden
        self.error = SimpleErrorModel(title: localized("error.generic.title"), description: localized("error.generic.description"), error: error)
    }
    
    private func updatePresentedData(yatButtonState: YatButtonState) {
        switch yatButtonState {
        case .hidden, .loading, .off:
            guard let publicKey = publicKey else { return }
            emojiData = EmojiData(emojiID: publicKey.emojis.0, hex: publicKey.hex.0, copyText: localized("emoji.copy"), tooltipText: localized("emoji.hex_tip"))
            description = walletDescription
            isReconnectButtonVisible = false
        case .on:
            guard let yat = self.yat else { return }
            emojiData = EmojiData(emojiID: yat, hex: nil, copyText: localized("emoji.yat.copy"), tooltipText: nil)
            description = isYatOutOfSync ? localized("profile_view.error.yat_mismatch") : walletDescription
            isReconnectButtonVisible = isYatOutOfSync
        }
    }
}
