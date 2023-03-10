//  StringProtocol.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/02/03
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

import UIKit

extension String {

    var firstOrEmpty: String {
        guard let first else { return "" }
        return String(first)
    }

    func insertSeparator(_ separatorString: String, atEvery n: Int) -> String {
        guard 0 < n else { return self }
        return self.enumerated().map({String($0.element) + (($0.offset != self.count - 1 && $0.offset % n ==  n - 1) ? "\(separatorString)" : "")}).joined()
    }

    func findBridges() -> String? {
        if let data = replacingOccurrences(of: "'", with: "\"").data(using: .utf8),
            let newBridges = try? JSONSerialization.jsonObject(with: data, options: []) as? [String] {
            return newBridges.joined(separator: "\n")
        } else {
            return nil
        }
    }

    static func random(unicodeRange: Range<UInt8> = 0..<UInt8.max, length: Int) -> String {
        (0..<length)
            .map { _ in
                let charNumber = UInt8.random(in: unicodeRange)
                let unicode = UnicodeScalar(charNumber)
                return String(Character(unicode))
            }
            .joined()
    }

    func tokenize() -> [String] {

        var result = split(separator: " ").map { String($0) }

        if !result.isEmpty, hasSuffix(" ") {
            result.append("")
        }

        return result
    }

    func withCurrencySymbol(imageBounds: CGRect) -> NSAttributedString {

        guard let symbol = Theme.shared.images.currencySymbol else { return NSAttributedString() }

        let currencySymbol = NSTextAttachment(image: symbol)
        currencySymbol.bounds = imageBounds

        let output = NSMutableAttributedString()
        output.append(NSAttributedString(attachment: currencySymbol))
        output.append(NSAttributedString(string: " " + self))

        return output
    }

    func height(forWidth width: CGFloat, font: UIFont) -> CGFloat {
        let rect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font], context: nil)
        return boundingBox.height
    }
}

extension StringProtocol {

    func indexDistance<S: StringProtocol>(of string: S) -> Int? {
        range(of: string)?.lowerBound.distance(in: self)
    }
}

extension Collection {
    func distance(to index: Index) -> Int {
        distance(from: startIndex, to: index)
    }
}

extension String.Index {
    func distance<S: StringProtocol>(in string: S) -> Int {
        string.distance(to: self)
    }
}

extension Array where Element == String.SubSequence {

    var firstString: String? {
        guard let first else { return nil }
        return String(first)
    }
}
