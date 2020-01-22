//  MicroTari.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/01/15
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

struct MicroTari {
    private static let CONVERSION = 1000000
    static let PRECISE_FRACTION_DIGITS = String(MicroTari.CONVERSION).count
    static let ROUNDED_FRACTION_DIGITS = 2

    private let formatterWithOperator = NumberFormatter()
    private let defaultFormatter = NumberFormatter()
    private let preciseFormatter = NumberFormatter()

    let rawValue: UInt64

    var taris: Float {
        return Float(self.rawValue) / Float(MicroTari.CONVERSION)
    }

    var formatted: String {
        return defaultFormatter.string(from: NSNumber(value: self.taris))!
    }

    var formattedWithOperator: String {
        return formatterWithOperator.string(from: NSNumber(value: self.taris))!
    }

    var formattedWithNegativeOperator: String {
        return formatterWithOperator.string(from: NSNumber(value: self.taris * -1))!
    }

    var formattedPrecise: String {
        return preciseFormatter.string(from: NSNumber(value: self.taris))!
    }

    init(_ rawValue: UInt64) {
        self.rawValue = rawValue

        defaultFormatter.numberStyle = .decimal
        defaultFormatter.minimumFractionDigits = MicroTari.ROUNDED_FRACTION_DIGITS
        defaultFormatter.maximumFractionDigits = MicroTari.ROUNDED_FRACTION_DIGITS
        defaultFormatter.negativePrefix = "-"

        formatterWithOperator.numberStyle = .decimal
        formatterWithOperator.minimumFractionDigits = MicroTari.ROUNDED_FRACTION_DIGITS
        formatterWithOperator.maximumFractionDigits = MicroTari.ROUNDED_FRACTION_DIGITS
        formatterWithOperator.positivePrefix = "+ "
        formatterWithOperator.negativePrefix = "- "

        preciseFormatter.numberStyle = .decimal
        preciseFormatter.minimumFractionDigits = MicroTari.PRECISE_FRACTION_DIGITS
        preciseFormatter.maximumFractionDigits = MicroTari.PRECISE_FRACTION_DIGITS
        preciseFormatter.negativePrefix = "- "
    }
}
