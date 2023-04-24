//  BLEPeripheralManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 14/04/2023
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

import CoreBluetooth
import UIKit
import Combine

final class BLEPeripheralManager: NSObject {

    enum BLEPeripheralError: Error {
        case turnedOff
        case unauthorized
        case unsupported
        case unknown
    }

    // MARK: - Properties

    static let shared = BLEPeripheralManager()

    @Published private(set) var error: BLEPeripheralError? = .unknown
    @Published private var isAdvertising = false

    var advertisingMode: UserSettings.BLEAdvertisementMode {
        get { UserSettingsManager.bleAdvertisementMode }
        set {
            UserSettingsManager.bleAdvertisementMode = newValue
            updateAdvertisingMode(advertisingMode: newValue)
        }
    }

    private lazy var manager = CBPeripheralManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    private override init() {
        super.init()
    }

    // MARK: - Setups

    func configure() {
        updateAdvertisingMode()
        setupCallbacks()
    }

    private func setupManager() {
        manager.delegate = self
    }

    private func setupService() {
        let contactBookService = CBMutableService(type: BLEConstants.contactBookService.uuid, primary: true)
        let contactShareCharacteristic = CBMutableCharacteristic(type: BLEConstants.contactBookService.characteristics.contactsShare, properties: [.write], value: nil, permissions: [.writeable])
        contactBookService.characteristics = [contactShareCharacteristic]
        manager.add(contactBookService)
    }

    private func setupCallbacks() {

        let onMoveToForegroundPublisher = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification).onChangePublisher()
        let onMoveToBackgroundPublisher = NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification).onChangePublisher()

        Tari.shared.$isWalletConnected
            .sink { [weak self] in self?.updateAdvertisingMode(isWalletConnected: $0) }
            .store(in: &cancellables)

        Publishers.Merge(onMoveToForegroundPublisher, onMoveToBackgroundPublisher)
            .sink { [weak self] _ in self?.updateAdvertisingMode() }
            .store(in: &cancellables)

        $error
            .map { $0 == nil }
            .sink { [weak self] in self?.updateAdvertisingMode(isBluetoothReady: $0) }
            .store(in: &cancellables)

        $isAdvertising
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] in self?.update(isAdvertising: $0) }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    private func update(isAdvertising: Bool) {

        Logger.log(message: "Update isAdvertising: \(isAdvertising)", domain: .blePeripherial, level: .info)

        if isAdvertising {
            start()
        } else {
            stop()
        }
    }

    private func start() {

        isAdvertising = true

        Logger.log(message: "Start Advertising", domain: .blePeripherial, level: .info)
        setupManager()
        manager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [BLEConstants.contactBookService.uuid]
        ])

        setupService()
    }

    private func stop() {
        Logger.log(message: "Stop Advertising", domain: .blePeripherial, level: .info)
        manager.stopAdvertising()
        manager.removeAllServices()
    }

    // MARK: - Handlers

    private func handle(writeRequest: CBATTRequest) {

        guard let data = writeRequest.value, let rawDeeplink = String(data: data, encoding: .utf8) else { return }

        Logger.log(message: "Write Request", domain: .blePeripherial, level: .info)

        do {
            try DeeplinkHandler.handle(rawDeeplink: rawDeeplink)
        } catch {
            Logger.log(message: "Invalid write rquest receiverd", domain: .blePeripherial, level: .warning)
        }
    }

    // MARK: - Updates

    private func updateAdvertisingMode(advertisingMode: UserSettings.BLEAdvertisementMode? = nil, isWalletConnected: Bool? = nil, isBluetoothReady: Bool? = nil) {

        let advertisingMode = advertisingMode ?? self.advertisingMode
        let isWalletConnected = isWalletConnected ?? Tari.shared.isWalletConnected
        let isBluetoothReady = error == nil

        Logger.log(message: "Updated Advertising Mode: \(advertisingMode) | isWalletConnected: \(isWalletConnected) | isBluetoothReady: \(isBluetoothReady)", domain: .blePeripherial, level: .info)

        guard isWalletConnected, isBluetoothReady else {
            isAdvertising = false
            return
        }

        switch advertisingMode {
        case .turnedOff:
            isAdvertising = false
        case .onlyOnForeground:
            updateAdvertisingStateForForegroundOnlyMode()
        case .alwaysOn:
            isAdvertising = true
        }
    }

    private func updateAdvertisingStateForForegroundOnlyMode() {

        guard advertisingMode == .onlyOnForeground else { return }

        DispatchQueue.main.async {
            self.isAdvertising = UIApplication.shared.applicationState == .background
        }
    }
}

extension BLEPeripheralManager: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {

        Logger.log(message: "Manager Status: \(peripheral.state.rawState)", domain: .blePeripherial, level: .info)

        switch peripheral.state {
        case .poweredOn:
            updateAdvertisingMode()
            error = nil
        case .poweredOff:
            error = .turnedOff
        case .unauthorized:
            error = .unauthorized
        case .unsupported:
            error = .unsupported
        case .resetting, .unknown:
            error = .unknown
        @unknown default:
            error = .unknown
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        Logger.log(message: "Write request received", domain: .blePeripherial, level: .info)
        requests.forEach { self.handle(writeRequest: $0) }
    }
}
