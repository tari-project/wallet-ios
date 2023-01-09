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

        var firstVersionComponents = firstVersion.split(separator: ".")
        var secondVersionComponents = secondVersion.split(separator: ".")

        let componentsCount = max(firstVersionComponents.count, secondVersionComponents.count)

        firstVersionComponents += Array(repeating: "", count: componentsCount - firstVersionComponents.count)
        secondVersionComponents += Array(repeating: "", count: componentsCount - secondVersionComponents.count)

        let result = zip(firstVersionComponents, secondVersionComponents).first { $0 < $1 }

        return result == nil
    }
}
