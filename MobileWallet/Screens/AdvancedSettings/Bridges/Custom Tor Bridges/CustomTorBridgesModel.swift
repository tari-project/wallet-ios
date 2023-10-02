//  CustomTorBridgesModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 04/09/2023
	Using Swift 5.0
	Running on macOS 13.4

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

final class CustomTorBridgesModel {

    // MARK: - View Model

    @Published private(set) var isConnectionPossible = false
    @Published private(set) var torBridges: String?
    @Published private(set) var endFlow: Bool = false

    // MARK: - Properties

    private var isUsingCustomBridges: Bool { Tari.shared.isUsingCustomBridges }
    private var usedTorBridges: String? { Tari.shared.torBridges }

    // MARK: - Initialisers

    init(torBridges: String?) {
        self.torBridges = torBridges
        updateValues()
    }

    // MARK: - Actions

    func update(torBridges: String) {
        self.torBridges = torBridges
        updateValues()
    }

    func connect() {
        Tari.shared.update(torBridges: torBridges)
        updateValues()
        endFlow = true
    }

    private func updateValues() {
        let isTorBridgesEmpty = torBridges?.isEmpty ?? true
        isConnectionPossible = !isUsingCustomBridges || (!isTorBridgesEmpty && self.usedTorBridges != torBridges)
    }
}
