//  BluetoothSettingsModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 20/04/2023
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

final class BluetoothSettingsModel {

    struct Section {
        let header: String?
        let items: [Item]
    }

    struct Item: Identifiable {
        let id: UUID
        let title: String?
        let isSelected: Bool
    }

    // MARK: - Constants

    private let bleTurnedOffID = UUID()
    private let bleForegroundID = UUID()
    private let bleAlwaysOn = UUID()

    // MARK: - Properties

    @Published private(set) var sections: [Section] = []

    // MARK: - Initialisers

    init() {
        setupSections()
    }

    // MARK: - Setups

    private func setupSections() {

        let advertisingMode = BLEPeripheralManager.shared.advertisingMode

        sections = [
            Section(
                header: localized("bluetooth_settings.table.ble.header"),
                items: [
                    Item(id: bleTurnedOffID, title: localized("bluetooth_settings.table.ble.row.title.ble_always_off"), isSelected: advertisingMode == .turnedOff),
                    Item(id: bleForegroundID, title: localized("bluetooth_settings.table.ble.row.title.ble_foreground"), isSelected: advertisingMode == .onlyOnForeground),
                    Item(id: bleAlwaysOn, title: localized("bluetooth_settings.table.ble.row.title.ble_always_on"), isSelected: advertisingMode == .alwaysOn)
                ]
            )
        ]
    }

    // MARK: - Actions

    func selectRow(uuid: UUID) {
        handle(selectedID: uuid)
        setupSections()
    }

    // MARK: - Handlers

    private func handle(selectedID: UUID) {

        switch selectedID {
        case bleTurnedOffID:
            BLEPeripheralManager.shared.advertisingMode = .turnedOff
        case bleForegroundID:
            BLEPeripheralManager.shared.advertisingMode = .onlyOnForeground
        case bleAlwaysOn:
            BLEPeripheralManager.shared.advertisingMode = .alwaysOn
        default:
            return
        }
    }
}
