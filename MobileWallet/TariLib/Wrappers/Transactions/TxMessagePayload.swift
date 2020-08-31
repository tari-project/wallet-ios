//  TxMessagePayload.swift

/*
	Package MobileWallet
	Created by kutsal kaan bilgin on 20.09.2020
	Using Swift 5.0
	Running on macOS 10.15

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
import ObjectMapper

class TxMessagePayload: Mappable {

    var text: String?
    var giphyURL: String?
    var sourceYat: String?
    var destinationYat: String?

    private static let giphyLinkPrefix = "https://giphy.com/embed/"

    init() {

    }

    init(nonJSONMessage: String) {
        let (note, giphyURL) = splitTextAndGiphyURL(nonJSONMessage)
        self.text = note
        self.giphyURL = giphyURL
    }

    required init?(map: Map) {

    }

    func mapping(map: Map) {
        text            <- map["text"]
        giphyURL        <- map["giphy_url"]
        sourceYat       <- map["source_yat"]
        destinationYat  <- map["destination_yat"]
    }

    var giphyId: String? {
        return giphyURL?.replacingOccurrences(of: TxMessagePayload.giphyLinkPrefix, with: "")
    }

    private func splitTextAndGiphyURL(_ message: String) -> (String, String?) {
        if let endIndex = message.range(of: TxMessagePayload.giphyLinkPrefix)?.lowerBound {
            let text = message[..<endIndex].trimmingCharacters(in: .whitespaces)
            let giphyURL = message[endIndex...].trimmingCharacters(in: .whitespaces)
            return (text, giphyURL)

        } else {
            return (message, nil)
        }
    }

}
