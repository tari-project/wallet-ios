//  String+Tools.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 07/04/2023
	Using Swift 5.0
	Running on macOS 13.0

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

extension String {

    var isBaseNodeAddress: Bool {
        guard let onionRegex = try? NSRegularExpression(pattern: "[a-z0-9]{64}::\\/onion3\\/[a-z0-9]{56}:[0-9]{2,6}"),
                let ip4Regex = try? NSRegularExpression(pattern: "[a-z0-9]{64}::\\/ip4\\/[0-9]{1,3}[.][0-9]{1,3}[.][0-9]{1,3}[.][0-9]{1,3}\\/tcp\\/[0-9]{2,6}") else {
            return false
        }

        let range = NSRange(location: 0, length: utf16.count)
        return onionRegex.matches(in: self, options: [], range: range).count == 1 || ip4Regex.matches(in: self, range: range).count == 1
    }

    func splitElementsInBrackets() -> [String] {
        guard #available(iOS 16.0, *) else { return components(separatedBy: CharacterSet(charactersIn: "[]")).map { String($0) }}
        return split(separator: /\[|\]/).map { String($0) }
    }
}
