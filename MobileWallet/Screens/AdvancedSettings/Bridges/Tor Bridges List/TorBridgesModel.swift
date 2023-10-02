//  TorBridgesModel.swift

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

final class TorBridgesModel {

    enum BridgesType {
        case noBridges
        case customBridges
    }

    enum Action {
        case setupCustomBridges(bridges: String?)
    }

    // MARK: - View Model

    @Published private(set) var isConnectionPossible = false
    @Published private(set) var areCustomBridgesSelected = false
    @Published private(set) var selectedBridgesType: BridgesType = .noBridges
    @Published private(set) var action: Action?

    // MARK: - Properties

    private var isUsingCustomBridges: Bool { Tari.shared.isUsingCustomBridges }

    // MARK: - Actions

    func updateStatus() {
        updateStatus(areCustomBridgesSelected: isUsingCustomBridges)
    }

    func update(areCustomBridgesSelected: Bool) {
        self.areCustomBridgesSelected = areCustomBridgesSelected
        updateStatus(areCustomBridgesSelected: areCustomBridgesSelected)
        guard areCustomBridgesSelected else { return }
        action = .setupCustomBridges(bridges: Tari.shared.torBridges)
    }

    func connect() {
        switch selectedBridgesType {
        case .noBridges:
            Tari.shared.update(torBridges: nil)
            update(areCustomBridgesSelected: false)
        case .customBridges:
            break
        }
    }

    private func updateStatus(areCustomBridgesSelected: Bool) {
        selectedBridgesType = areCustomBridgesSelected ? .customBridges : .noBridges
        isConnectionPossible = areCustomBridgesSelected != isUsingCustomBridges
    }
}
