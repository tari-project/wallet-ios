//  BLECentralTask.swift

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

import Combine
import CoreBluetooth

final class BLECentralTask {

    // MARK: - Properties

    private let manager: BLECentralManager
    private let cancelSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(service: CBUUID, characteristic: CBUUID) {
        self.manager = BLECentralManager(configuration: BLECentralManager.Configuration(service: service, characteristic: characteristic))
    }

    // MARK: - Actions

    func findAndRead() async throws -> Data? {
        guard try await findDevice() else { return nil }
        return try await read()
    }

    func findAndWrite(payload: Data) async throws -> Bool {
        guard try await findDevice(), try await write(payload: payload) else { return false }
        return true
    }

    func cancel() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        manager.stop()
    }

    private func findDevice() async throws -> Bool {

        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else { return }

            self.manager.findDeviceProcess()
                .handleEvents(receiveCancel: { continuation.resume(returning: false) })
                .sink { completion in
                    switch completion {
                    case .finished:
                        continuation.resume(returning: true)
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                } receiveValue: {}
                .store(in: &self.cancellables)
        }
    }

    private func read() async throws -> Data? {

        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else { return }

            self.manager.readProcess()
                .handleEvents(receiveCancel: { continuation.resume(returning: nil) })
                .sink { completion in
                    switch completion {
                    case .finished:
                        return
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                } receiveValue: { continuation.resume(returning: $0) }
                .store(in: &self.cancellables)
        }
    }

    private func write(payload: Data) async throws -> Bool {

        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else { return }

            self.manager.writeProcess(payload: payload)
                .handleEvents(receiveCancel: { continuation.resume(returning: false) })
                .sink { completion in
                    switch completion {
                    case .finished:
                        continuation.resume(returning: true)
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                } receiveValue: {}
                .store(in: &self.cancellables)
        }
    }

    deinit {
        manager.stop()
    }
}
