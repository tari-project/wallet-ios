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
        case invalidData
    }

    // MARK: - Constants

    private let rssiThreshold = -40

    // MARK: - Properties

    private let manager = CBCentralManager()
    private let configuration: Configuration

    private var connectedPeripheral: CBPeripheral?
    private var findProcessSubject: PassthroughSubject<Void, BLECentralError>?
    private var readProcessSubject: PassthroughSubject<[Data], BLECentralError>?
    private var writeProcessSubject: PassthroughSubject<Void, BLECentralError>?
    private var cache: [CBUUID: [Data]] = [:]

    // MARK: - Initialisers

    init(configuration: Configuration) {
        self.configuration = configuration
        super.init()
        log(message: "Init", level: .info)
        setupManager()
    }

    // MARK: - Setups

    private func setupManager() {
        manager.delegate = self
    }

    // MARK: - Actions

    func findDeviceProcess() -> AnyPublisher<Void, BLECentralError> {
        resetService()
        let publisher = makeFindProcessSubject()
        handle(centralManagerState: manager.state)
        return publisher
    }

    func readProcess() -> AnyPublisher<[Data], BLECentralError> {

        interruptCurrentProcess()

        let subject = PassthroughSubject<[Data], BLECentralError>()
        readProcessSubject = subject

        do {
            try read(serviceID: configuration.service, characteristicID: configuration.characteristic)
            return subject.eraseToAnyPublisher()
        } catch {
            let bleError: BLECentralError = error as? BLECentralError ?? .unknown
            return Fail<[Data], BLECentralError>(error: bleError).eraseToAnyPublisher()
        }
    }

    func writeProcess(payload: Data) -> AnyPublisher<Void, BLECentralError> {

        interruptCurrentProcess()

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

    private func interruptCurrentProcess() {
        readProcessSubject?.send(completion: .failure(.processInterrupted))
        writeProcessSubject?.send(completion: .failure(.processInterrupted))
    }

    private func read(serviceID: CBUUID, characteristicID: CBUUID) throws {
        let characteristic = try findCharacteristic(serviceID: serviceID, characteristicID: characteristicID)
        connectedPeripheral?.readValue(for: characteristic)
    }

    private func write(payload: Data, serviceID: CBUUID, characteristicID: CBUUID) throws {
        let characteristic = try findCharacteristic(serviceID: serviceID, characteristicID: characteristicID)
        connectedPeripheral?.writeValue(payload, for: characteristic, type: .withResponse)
    }

    private func makeFindProcessSubject() -> AnyPublisher<Void, BLECentralError> {
        let subject = PassthroughSubject<Void, BLECentralError>()
        findProcessSubject = subject
        return subject.eraseToAnyPublisher()
    }

    private func startScanning() {
        guard !manager.isScanning else { return }
        manager.scanForPeripherals(withServices: [configuration.service], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        log(message: "Scanning: Start", level: .info)
    }

    private func stopScanning() {
        manager.stopScan()
        log(message: "Scanning: Stop", level: .info)
    }

    private func disconnectPeripheral() {
        guard let connectedPeripheral else { return }
        manager.cancelPeripheralConnection(connectedPeripheral)
    }

    private func resetService() {
        findProcessSubject?.send(completion: .failure(.processInterrupted))
        findProcessSubject = nil
        disconnectPeripheral()
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

    private func handleReadSuccess(data: [Data]) {
        readProcessSubject?.send(data)
        readProcessSubject?.send(completion: .finished)
    }

    private func handleReadFailure(error: Error) {
        readProcessSubject?.send(completion: .failure(.connectionError(error: error)))
    }

    private func handleWriteSuccess() {
        writeProcessSubject?.send(completion: .finished)
    }

    private func handleWriteFailure(error: Error) {
        writeProcessSubject?.send(completion: .failure(.connectionError(error: error)))
    }

    private func handle(centralManagerState: CBManagerState) {
        switch centralManagerState {
        case .poweredOn:
            startScanning()
        case .poweredOff:
            handleDiscoveryFailure(error: .turnedOff)
        case .unauthorized:
            handleDiscoveryFailure(error: .unauthorized)
        case .unsupported:
            handleDiscoveryFailure(error: .unsupported)
        case .resetting, .unknown:
            break
        @unknown default:
            handleDiscoveryFailure(error: .unknown)
        }
    }

    // MARK: - Helpers

    private func findCharacteristic(serviceID: CBUUID, characteristicID: CBUUID) throws -> CBCharacteristic {
        guard let characteristic = connectedPeripheral?.services?.first(where: { $0.uuid == serviceID })?.characteristics?.first(where: { $0.uuid == characteristicID }) else {
            throw BLECentralError.writeFailedCharacteristicNotFound
        }
        return characteristic
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
        handle(centralManagerState: central.state)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {

        log(message: "Discovered: \(peripheral.identifier) | RSSI: \(RSSI)", level: .verbose)

        guard RSSI.intValue >= rssiThreshold else { return }

        connectedPeripheral = peripheral
        peripheral.delegate = self
        central.connect(peripheral)

        stopScanning()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log(message: "Connected to: \(peripheral.identifier)", level: .info)
        guard peripheral == connectedPeripheral else { return }
        peripheral.discoverServices([configuration.service])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log(message: "Did fail to connect: \(peripheral.identifier) | Error: \(error.debugDescription)", level: .warning)
        guard peripheral == connectedPeripheral else { return }
        connectedPeripheral = nil
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log(message: "Disconnected from: \(peripheral.identifier) | Error: \(error.debugDescription)", level: .info)
        guard peripheral == connectedPeripheral else { return }
        connectedPeripheral = nil
    }
}

extension BLECentralManager: CBPeripheralDelegate {

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

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        log(message: "Did Read: \(error == nil)", level: .info)

        if let error {
            handleReadFailure(error: error)
            return
        }

        guard let value = characteristic.value, value.isBLEChunk else {
            handleReadFailure(error: BLECentralError.invalidData)
            return
        }

        var chunks = cache[characteristic.uuid] ?? []
        chunks.append(value)
        cache[characteristic.uuid] = chunks

        guard value.bleChunkType == .last else {
            peripheral.readValue(for: characteristic)
            return
        }

        handleReadSuccess(data: chunks)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {

        log(message: "Did Write: \(error == nil)", level: .info)

        if let error {
            handleWriteFailure(error: error)
            return
        }

        handleWriteSuccess()
    }
}

extension BLECentralManager.BLECentralError {

    var errorMessage: String? {
        switch self {
        case .turnedOff:
            return localized("error.ble.central.turned_off")
        case .unauthorized:
            return localized("error.ble.central.unauthorized")
        case .unsupported:
            return localized("error.ble.central.unsupported")
        case .unknown:
            return localized("error.ble.central.unknown")
        case .connectionError:
            return localized("error.ble.central.connection_error")
        case .processInterrupted:
            return localized("error.ble.central.process_interrupted")
        case .writeFailedCharacteristicNotFound:
            return localized("error.ble.central.write_failed_characteristic_not_found")
        case .invalidData:
            return localized("error.ble.central.invalid_data")
        }
    }
}
