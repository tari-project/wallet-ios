//  VersionValidator.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 23/11/2022
	Using Swift 5.0
	Running on macOS 12.6

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

enum VersionValidator {
    static func compare(_ firstVersion: String, isHigherOrEqualTo secondVersion: String) -> Bool {
        Version(rawVersion: firstVersion) >= Version(rawVersion: secondVersion)
    }
}

private struct Version: Comparable {

    let components: [String]
    let suffix: String

    private var suffixValue: Int {
        switch suffix {
        case "pre":
            return 1
        case "rc":
            return 2
        case "":
            return 3
        default:
            return 0
        }
    }

    init(rawVersion: String) {

        let rawComponents = rawVersion
            .split(separator: "-", maxSplits: 1)
            .map { String($0) }

        if rawComponents.count >= 1 {
            components = rawComponents[0]
                .split(separator: ".")
                .map { String($0) }
        } else {
            components = []
        }

        if rawComponents.count == 2 {
            suffix = rawComponents[1]
        } else {
            suffix = ""
        }
    }

    static func < (lhs: Self, rhs: Self) -> Bool {

        var firstComponents = lhs.components
        var secondComponents = rhs.components

        let componentsCount = max(firstComponents.count, secondComponents.count)

        firstComponents += Array(repeating: "", count: componentsCount - firstComponents.count)
        secondComponents += Array(repeating: "", count: componentsCount - secondComponents.count)

        let result: Bool? = zip(firstComponents, secondComponents)
            .compactMap {
                guard $0 != $1 else { return nil }
                return $0 < $1
            }
            .first

        if let result {
            return result
        }

        if lhs.suffixValue == rhs.suffixValue {
            return lhs.suffix < rhs.suffix
        }

        return lhs.suffixValue < rhs.suffixValue
    }
}
