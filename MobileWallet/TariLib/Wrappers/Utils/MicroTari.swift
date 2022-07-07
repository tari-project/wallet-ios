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

enum MicroTariErrors: Error {
    case invalidStringFormat
}

struct MicroTari {
    private static let conversion = 1000000
    public static let ROUNDED_FRACTION_DIGITS = 2
    public static let MAX_FRACTION_DIGITS = 6

    private static let defaultFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = MicroTari.ROUNDED_FRACTION_DIGITS
        formatter.maximumFractionDigits = MicroTari.ROUNDED_FRACTION_DIGITS
        formatter.negativePrefix = "-"
        formatter.roundingMode = .down
        return formatter
    }()

    private static let withOperatorFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = MicroTari.ROUNDED_FRACTION_DIGITS
        formatter.maximumFractionDigits = MicroTari.MAX_FRACTION_DIGITS
        formatter.positivePrefix = "+ "
        formatter.negativePrefix = "- "
        return formatter
    }()

    private static let preciseFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = MicroTari.ROUNDED_FRACTION_DIGITS
        formatter.maximumFractionDigits = MicroTari.MAX_FRACTION_DIGITS
        formatter.negativePrefix = "- "
        return formatter
    }()

    private static let editFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = MicroTari.ROUNDED_FRACTION_DIGITS
        formatter.negativePrefix = "-"
        return formatter
    }()

    public static var groupingSeparator: String {
        return defaultFormatter.groupingSeparator
    }

    public static var decimalSeparator: String {
        return defaultFormatter.decimalSeparator
    }

    var rawValue: UInt64

    var taris: Double {
        return Double(self.rawValue) / Double(MicroTari.conversion)
    }

    var formatted: String {
        return MicroTari.defaultFormatter.string(from: NSNumber(value: self.taris))!
    }

    var formattedWithOperator: String {
        return MicroTari.withOperatorFormatter.string(from: NSNumber(value: self.taris))!
    }

    var formattedWithNegativeOperator: String {
        return MicroTari.withOperatorFormatter.string(from: NSNumber(value: self.taris * -1))!
    }

    var formattedPrecise: String {
        return MicroTari.preciseFormatter.string(from: NSNumber(value: self.taris))!
    }
    
    init() { self.init(0) }

    init(_ rawValue: UInt64) {
        self.rawValue = rawValue
    }

    init(tariValue: String) throws {
        guard let tariNumber = MicroTari.defaultFormatter.number(from: tariValue) else {
            throw MicroTariErrors.invalidStringFormat
        }

        guard MicroTari.checkValue(tariValue) else {
            throw MicroTariErrors.invalidStringFormat
        }

        self.rawValue = UInt64(tariNumber.floatValue * Float(MicroTari.conversion))
    }

    init(tariValue: UInt) {
        self.rawValue = UInt64(tariValue * UInt(MicroTari.conversion))
    }

    init(decimalValue: Double) throws {
        guard let rawVal = UInt64(exactly: decimalValue * Double(MicroTari.conversion)) else {
            throw MicroTariErrors.invalidStringFormat // TODO
        }

        self.rawValue = rawVal
    }

    public static func toTariNumber(_ number: NSNumber) -> UInt64 {
        return number.uint64Value * UInt64(conversion)
    }
}

extension MicroTari {
    public static func convertToNumber(_ number: String) -> NSNumber? {
        return defaultFormatter.number(from: number)
    }

    public static func convertToString(_ number: NSNumber, minimumFractionDigits: Int) -> String? {
        editFormatter.minimumFractionDigits = minimumFractionDigits
        return editFormatter.string(from: number)
    }

    public static func checkValue(_ value: NSNumber) -> Bool {
        let convertedValue = value.decimalValue * Decimal(MicroTari.conversion)
        return convertedValue.isLessThanOrEqualTo(Decimal(UInt64.max))
    }

    public static func checkValue(_ value: String) -> Bool {
        guard let number = convertToNumber(value) else { return false }
        return checkValue(number)
    }
}
