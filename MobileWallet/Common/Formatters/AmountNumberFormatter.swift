//  AmountNumberFormatter.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 19/01/2022
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

import Foundation
import Combine

final class AmountNumberFormatter {

    // MARK: - Constants

    private let maxFractionDigits: Int = 6

    // MARK: - Properties

    @Published private(set) var amount: String = "0"
    @Published private(set) var amountValue: Double = 0
    @Published private var rawAmount: String = "0"

    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.decimalSeparator = MicroTari.decimalSeparator
        formatter.groupingSeparator = MicroTari.groupingSeparator
        return formatter
    }()

    init() {
        setupBindings()
    }

    private func setupBindings() {

        let inputStream = $rawAmount
            .filter { [unowned self] in self.isValidNumber(string: $0) }

        inputStream
            .compactMap { [weak self] in self?.format(string: $0) }
            .assign(to: &$amount)
        inputStream
            .compactMap { [weak self] in self?.formatter.number(from: $0)?.doubleValue }
            .assign(to: &$amountValue)
    }

    func append(string: String) {

        guard string.rangeOfCharacter(from: .digitsAndDecimalSeparator.inverted) == nil else { return }
        if string.contains(MicroTari.decimalSeparator), rawAmount.contains(MicroTari.decimalSeparator) || string.filter({ String($0) == MicroTari.decimalSeparator }).count > 1 { return }

        let updatedRawAmount: String

        if rawAmount == "0", !string.hasPrefix(MicroTari.decimalSeparator) {
            updatedRawAmount = string
        } else {
            updatedRawAmount = rawAmount + string
        }

        guard fractionDigits(in: updatedRawAmount) <= maxFractionDigits else { return }
        rawAmount = updatedRawAmount
    }

    func removeLast() {
        guard rawAmount != "0" else { return }
        rawAmount.removeLast()
        guard rawAmount.isEmpty else { return }
        rawAmount = "0"
    }

    private func format(string: String) -> String {

        let haveDecimalSeparatorAsSuffix = string.hasSuffix(MicroTari.decimalSeparator)

        formatter.minimumFractionDigits = fractionDigits(in: string)

        guard let value = formatter.number(from: string), let formattedValue = formatter.string(from: value) else { return "0" }
        let suffix = haveDecimalSeparatorAsSuffix ? MicroTari.decimalSeparator : ""

        return formattedValue + suffix
    }

    private func isValidNumber(string: String) -> Bool {
        guard let value = formatter.number(from: string)?.doubleValue.micro else { return false }
        return UInt64(exactly: value) != nil
    }

    private func fractionDigits(in string: String) -> Int {
        guard let index = string.indexDistance(of: MicroTari.decimalSeparator) else { return 0 }
        return max(string.count - index - 1, 0)
    }
}

private extension Double {
    var micro: Self { self * 1000000.0 }
}
