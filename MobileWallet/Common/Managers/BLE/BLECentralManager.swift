//  BLECentralManager.swift

/*
    Package MobileWallet
    Created by Adrian Truszczyński on 13/04/2023
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
    documentation and/or other materials provided` with the distribution.

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
import Combine

final class BLECentralManager: NSObject {

    struct Configuration {
        let service: CBUUID
        let characteristic: CBUUID
    }

    enum BLECentralError: Error {
        case turnedOff
        case unauthorized
        case unsupported
        case unknown
        case connectionError(error: Error)
        case processInterrupted
        case writeFailedCharacteristicNotFound
    }

    // MARK: - Constants

    private let proximyCheckTimeInterval: TimeInterval = 1.0
    private let rssiThreshold = -40

    // MARK: - Properties

    private let manager = CBCentralManager()
    private let configuration: Configuration

    private var connectedPeripherals: [CBPeripheral] = []
    private var selectedPeripheral: CBPeripheral?
    private var findProcessSubject: PassthroughSubject<Void, BLECentralError>?
    private var writeProcessSubject: PassthroughSubject<Void, BLECentralError>?

    // MARK: - Initialisers

    init(configuration: Configuration) {
        self.configuration = configuration
        super.init()
        log(message: "Init", level: .info)
        setupManager()
        setupProximityCheck()
    }

    // MARK: - Setups

    private func setupManager() {
        manager.delegate = self
    }

    private func setupProximityCheck() {
        Timer.scheduledTimer(withTimeInterval: proximyCheckTimeInterval, repeats: true) { [weak self] _ in self?.checkRSSIs() }
    }

    // MARK: - Actions

    func findDeviceProcess() -> AnyPublisher<Void, BLECentralError> {
        resetService()
        return startFindProcess()
    }

    func writeProcess(payload: Data) -> AnyPublisher<Void, BLECentralError> {
        writeProcessSubject?.send(completion: .failure(.processInterrupted))
        let subject = PassthroughSubject<Void, BLECentralError>()
        writeProcessSubject = subject
        do {
            try write(payload: payload, serviceID: configuration.service, characteristicID: configuration.characteristic)
            return subject.eraseToAnyPublisher()
        } catch {
            let bleError: BLECentralError = error as? BLECentralError ?? .unknown
            return Fail<Void, BLECentralError>(error: bleError).eraseToAnyPublisher()
        }
    }

    func stop() {
        stopScanning()
        resetService()
    }

    private func write(payload: Data, serviceID: CBUUID, characteristicID: CBUUID) throws {
        guard let characteristic = selectedPeripheral?.services?.first(where: { $0.uuid == serviceID })?.characteristics?.first(where: { $0.uuid == characteristicID }) else {
            throw BLECentralError.writeFailedCharacteristicNotFound
        }

        selectedPeripheral?.writeValue(payload, for: characteristic, type: .withResponse)
    }

    private func startFindProcess() -> AnyPublisher<Void, BLECentralError> {

        let subject = PassthroughSubject<Void, BLECentralError>()
        findProcessSubject = subject
        return subject.eraseToAnyPublisher()
    }

    private func startScanning() {
        guard !manager.isScanning else { return }
        manager.scanForPeripherals(withServices: [configuration.service])
        log(message: "Scanning: Start", level: .info)
    }

    private func stopScanning() {
        manager.stopScan()
        log(message: "Scanning: Stop", level: .info)
    }

    private func checkRSSIs() {
        connectedPeripherals
            .filter { $0.state == .connected }
            .forEach { $0.readRSSI() }
    }

    private func select(peripheral: CBPeripheral) -> Bool {
        guard let index = connectedPeripherals.firstIndex(of: peripheral) else { return false }
        connectedPeripherals.remove(at: index)
        selectedPeripheral = peripheral
        disconnectFromPeripherals()
        return true
    }

    private func disconnectFromPeripherals() {
        connectedPeripherals.forEach { self.manager.cancelPeripheralConnection($0) }
        log(message: "Disconnected from Peripherals", level: .info)
    }

    private func disconnectSelectedPeripheral() {
        guard let selectedPeripheral else { return }
        manager.cancelPeripheralConnection(selectedPeripheral)
    }

    private func resetService() {
        findProcessSubject?.send(completion: .failure(.processInterrupted))
        findProcessSubject = nil
        disconnectFromPeripherals()
        disconnectSelectedPeripheral()
    }

    // MARK: - Handle

    private func handleDiscoveryFailure(error: Error) {
        findProcessSubject?.send(completion: .failure(.connectionError(error: error)))
    }

    private func handleDiscoveryFailure(error: BLECentralError) {
        findProcessSubject?.send(completion: .failure(error))
    }

    private func handleDiscoverySuccess() {
        findProcessSubject?.send(completion: .finished)
    }

    private func handleWriteSuccess() {
        writeProcessSubject?.send(completion: .finished)
    }

    private func handleWriteFailure(error: Error) {
        writeProcessSubject?.send(completion: .failure(.connectionError(error: error)))
    }

    private func log(message: String, level: Logger.Level) {
        Logger.log(message: "\(hashValue) | \(message)", domain: .bleCentral, level: level)
    }

    // MARK: - Deinitaliser

    deinit {
        log(message: "Deinit", level: .info)
    }
}

extension BLECentralManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScanning()
        case .poweredOff:
            handleDiscoveryFailure(error: .turnedOff)
        case .unauthorized:
            handleDiscoveryFailure(error: .unauthorized)
        case .unsupported:
            handleDiscoveryFailure(error: .unsupported)
        case .resetting, .unknown:
            handleDiscoveryFailure(error: .unknown)
        @unknown default:
            handleDiscoveryFailure(error: .unknown)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {

        log(message: "Found: \(peripheral.identifier)", level: .info)

        guard !connectedPeripherals.contains(where: { $0.identifier == peripheral.identifier }) else { return }

        connectedPeripherals.append(peripheral)
        peripheral.delegate = self
        central.connect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log(message: "Connected to: \(peripheral.identifier)", level: .info)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log(message: "Did fail to connect: \(peripheral.identifier) | Error: \(error.debugDescription)", level: .warning)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {

        log(message: "Disconnected from: \(peripheral.identifier) | Error: \(error.debugDescription)", level: .info)

        if let index = connectedPeripherals.firstIndex(of: peripheral) {
            connectedPeripherals.remove(at: index)
        } else if peripheral == selectedPeripheral {
            selectedPeripheral = nil
        }
    }
}

extension BLECentralManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        log(message: "RSSI: \(peripheral.identifier) | \(RSSI.intValue)", level: .verbose)
        guard RSSI.intValue >= rssiThreshold, select(peripheral: peripheral) else { return }
        peripheral.discoverServices([configuration.service])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {

        if let error {
            handleDiscoveryFailure(error: error)
            return
        }

        guard let service = peripheral.services?.first(where: { $0.uuid == configuration.service }) else { return }
        peripheral.discoverCharacteristics([configuration.characteristic], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {

        if let error {
            handleDiscoveryFailure(error: error)
            return
        }

        handleDiscoverySuccess()
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {

        if let error {
            handleWriteFailure(error: error)
            return
        }

        handleWriteSuccess()
    }
}
