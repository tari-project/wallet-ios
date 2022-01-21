//  RequestTariAmountModel.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 17/01/2022
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

import Combine
import UIKit

final class RequestTariAmountModel {
    
    struct DeeplinkData {
        let message: String
        let deeplink: URL
    }
    
    // MARK: - View Model
    
    @Published private(set) var amount: String = ""
    @Published private(set) var isValidAmount: Bool = false
    @Published private(set) var deeplink: DeeplinkData?
    @Published private(set) var qrCode: UIImage?
    
    // MARK: - Properties
    
    private let amountFormatter = AmountNumberFormatter()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupCallbacks()
    }
    
    // MARK: - Setups
    
    private func setupCallbacks() {
        
        if #available(iOS 14.0, *) {
            amountFormatter.$amount
                .assign(to: &$amount)
            
            amountFormatter.$amountValue
                .map { $0 > 0.0 }
                .assign(to: &$isValidAmount)
        } else {
            amountFormatter.$amount
                .assign(to: \.amount, on: self)
                .store(in: &cancellables)
            
            amountFormatter.$amountValue
                .map { $0 > 0.0 }
                .assign(to: \.isValidAmount, on: self)
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Actions
    
    func updateAmount(key: String) {
        amountFormatter.append(string: key)
    }
    
    func deleteLastCharacter() {
        amountFormatter.removeLast()
    }
    
    func generateQrRequest() {
        guard let deeplink = makeDeeplink(), let deeplinkData = deeplink.absoluteString.data(using: .utf8), let qrCodeImage = QRCodeFactory.makeQrCode(data: deeplinkData) else { return }
        qrCode = qrCodeImage
    }
    
    func shareActionRequest() {
        guard let deeplink = makeDeeplink() else { return }
        let amount = String(amountFormatter.amountValue)
        let message = localized("request.deeplink.message", arguments: amount)
        self.deeplink = DeeplinkData(message: message, deeplink: deeplink)
    }
    
    // MARK: - Factories
    
    private func makeDeeplink() -> URL? {
        let network = NetworkManager.shared.selectedNetwork.name
        let amount = String(amountFormatter.amountValue)
        guard let publicKey = TariLib.shared.tariWallet?.publicKey.0?.hex.0, let url = DeeplinkFactory.tariRequest(network: network, publicKey: publicKey, amount: amount) else { return nil }
        return url
    }
}
