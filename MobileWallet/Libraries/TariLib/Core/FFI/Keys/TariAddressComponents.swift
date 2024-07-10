//  TariAddressComponents.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 10/07/2024
	Using Swift 5.0
	Running on macOS 14.4

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

import Base58Swift

struct TariAddressComponents {

    let network: String
    let networkName: String
    let features: String
    let featuresNames: String
    let viewKey: String?
    let spendKey: String
    let checksum: String

    let fullRaw: String
    let fullEmoji: String
}

extension TariAddressComponents {

    var networkAndFeatures: String { network + features }
    var spendKeyPrefix: String { String(spendKey.prefix(3)) }
    var spendKeySuffix: String { String(spendKey.suffix(3)) }

    init(address: TariAddress) throws {

        let addressNetwork = try address.network
        let addressFeatures = try address.features

        let networkBase58 = Base58.base58Encode([addressNetwork.value])
        let featuresBase58 = Base58.base58Encode([addressFeatures.value])
        let addressData = try address.byteVector.data.dropFirst(2)
        let addressBase58 = Base58.base58Encode([UInt8](addressData))

        network = addressNetwork.value.tariEmoji
        networkName = addressNetwork.name
        features = addressFeatures.value.tariEmoji
        featuresNames = addressFeatures.names.joined(separator: ", ")
        viewKey = try address.viewKey?.emojis
        spendKey = try address.spendKey.emojis
        checksum = try address.checksum.tariEmoji
        fullRaw = [networkBase58, featuresBase58, addressBase58].joined()
        fullEmoji = try address.emojis
    }
}
