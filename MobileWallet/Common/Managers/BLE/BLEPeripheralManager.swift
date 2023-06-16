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

    var isEnabled = false {
        didSet { setupManager() }
    }

    var advertisingMode: UserSettings.BLEAdvertisementMode {
        get { UserSettingsManager.bleAdvertisementMode }
        set {
            UserSettingsManager.bleAdvertisementMode = newValue
            updateAdvertisingState(advertisingMode: newValue)
        }
    }

    private let userProfileCharacteristic = CBMutableCharacteristic(type: BLEConstants.contactBookService.characteristics.transactionData, properties: [.read], value: nil, permissions: [.readable])

    private lazy var manager = CBPeripheralManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    private override init() {
        super.init()
        configure()
    }

    // MARK: - Setups

    private func configure() {
        updateAdvertisingState()
        setupCallbacks()
    }

    private func setupManager() {
        manager.delegate = isEnabled ? self : nil
        updateAdvertisingState()
    }

    private func setupService() {

        let contactBookService = CBMutableService(type: BLEConstants.contactBookService.uuid, primary: true)
        let contactShareCharacteristic = CBMutableCharacteristic(type: BLEConstants.contactBookService.characteristics.contactsShare, properties: [.write], value: nil, permissions: [.writeable])

        contactBookService.characteristics = [userProfileCharacteristic, contactShareCharacteristic]
        manager.add(contactBookService)
    }

    private func setupCallbacks() {

        let onMoveToForegroundPublisher = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification).onChangePublisher()
        let onMoveToBackgroundPublisher = NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification).onChangePublisher()

        Publishers.Merge(onMoveToForegroundPublisher, onMoveToBackgroundPublisher)
            .sink { [weak self] _ in self?.updateAdvertisingState() }
            .store(in: &cancellables)

        $error
            .map { $0 == nil }
            .sink { [weak self] in self?.updateAdvertisingState(isBluetoothReady: $0) }
            .store(in: &cancellables)

        $isAdvertising
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] in self?.update(isAdvertising: $0) }
            .store(in: &cancellables)

        Tari.shared.$isWalletConnected
            .filter { $0 }
            .map { [weak self] _ in self?.makeUserProfileDeeplink() }
            .sink { [weak self] in self?.update(userProfileDeeplink: $0) }
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
        Logger.log(message: "Start Advertising", domain: .blePeripherial, level: .info)
        setupService()
        manager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [BLEConstants.contactBookService.uuid]
        ])
    }

    private func stop() {
        Logger.log(message: "Stop Advertising", domain: .blePeripherial, level: .info)
        manager.stopAdvertising()
        manager.removeAllServices()
    }

    // MARK: - Handlers

    private func handle(writeRequest: CBATTRequest) {

        guard let data = writeRequest.value, let rawDeeplink = String(data: data, encoding: .utf8) else {
            manager.respond(to: writeRequest, withResult: .invalidHandle)
            return
        }

        Logger.log(message: "Write Request", domain: .blePeripherial, level: .info)

        do {
            try DeeplinkHandler.handle(rawDeeplink: rawDeeplink)
            manager.respond(to: writeRequest, withResult: .success)
        } catch {
            Logger.log(message: "Invalid write request received", domain: .blePeripherial, level: .warning)
            manager.respond(to: writeRequest, withResult: .invalidHandle)
        }
    }

    // MARK: - Updates

    private func updateAdvertisingState(advertisingMode: UserSettings.BLEAdvertisementMode? = nil, isBluetoothReady: Bool? = nil) {

        guard isEnabled else {
            isAdvertising = false
            return
        }

        let advertisingMode = advertisingMode ?? self.advertisingMode
        let isBluetoothReady = isBluetoothReady ?? (error == nil)

        Logger.log(message: "Updated Advertising Mode: \(advertisingMode) | isBluetoothReady: \(isBluetoothReady)", domain: .blePeripherial, level: .info)

        guard isBluetoothReady else {
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
            self.isAdvertising = UIApplication.shared.applicationState != .background
        }
    }

    private func update(userProfileDeeplink: URL?) {
        userProfileCharacteristic.value = userProfileDeeplink?.absoluteString.data(using: .utf8)
    }

    // MARK: - Factories

    private func makeUserProfileDeeplink() -> URL? {
        guard let alias = UserSettingsManager.name, let address = try? Tari.shared.walletAddress.byteVector.hex else { return nil }
        let model = UserProfileDeeplink(alias: alias, tariAddress: address)
        return try? DeepLinkFormatter.deeplink(model: model)
    }
}

extension BLEPeripheralManager: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {

        Logger.log(message: "Manager Status: \(peripheral.state.rawState)", domain: .blePeripherial, level: .info)

        switch peripheral.state {
        case .poweredOn:
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
