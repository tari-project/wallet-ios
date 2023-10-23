//  TorManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 07/01/2022
	Using Swift 5.0
	Running on macOS 12.1

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

final class TorManager {

    // MARK: - Constants

    private let controlAddress = "127.0.0.1"
    private let controlPort: UInt16 = 39069
    private let dataDirectoryUrl = TariSettings.storageDirectory.appendingPathComponent("tor", isDirectory: true)
    private lazy var authDirectoryURL = dataDirectoryUrl.appendingPathComponent("auth", isDirectory: true)
    private(set) lazy var controlServerAddress = "/ip4/\(controlAddress)/tcp/\(controlPort)"

    // MARK: - Properties

    var isUsingCustomBridges: Bool { TorManagerUserDefaults.isUsingCustomBridges ?? false }
    var bridges: String? { TorManagerUserDefaults.torBridges }

    @Published private(set) var connectionStatus: TorConnectionStatus = .disconnected
    @Published private(set) var bootstrapProgress: Int = 0
    @Published private(set) var error: TorError?

    private var containter: TorWorkingContainter?
    private var cancellables = Set<AnyCancellable>()

    func reinitiateConnection() {
        Logger.log(message: "Reinitiate connection", domain: .tor, level: .info)
        stop()
        start()
    }

    func stop() {
        Logger.log(message: "Stop", domain: .tor, level: .info)
        containter?.invalidate()
        containter = nil
    }

    private func start() {
        Logger.log(message: "Start", domain: .tor, level: .info)
        let bridges = isUsingCustomBridges ? bridges : nil
        setupContainter(bridges: bridges)
    }

    func cookie() async throws -> Data {
        guard let containter else { throw TorError.missingController }
        return try await containter.cookie()
    }

    func update(bridges: String?) {
        Logger.log(message: "Update bridges", domain: .tor, level: .info)
        TorManagerUserDefaults.isUsingCustomBridges = bridges != nil
        TorManagerUserDefaults.torBridges = bridges
        reinitiateConnection()
    }

    // MARK: - Setups

    private func setupContainter(bridges: String?) {

        let bridgesChunks = (bridges ?? "")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("//") && !$0.hasPrefix("#") }

        containter = TorWorkingContainter(bridges: bridgesChunks)

        containter?.$connectionStatus
            .assign(to: \.connectionStatus, on: self)
            .store(in: &cancellables)

        containter?.$bootstrapProgress
            .assign(to: \.bootstrapProgress, on: self)
            .store(in: &cancellables)

        containter?.$error
            .compactMap { $0 }
            .sink { [weak self] in self?.handle(error: $0) }
            .store(in: &cancellables)
    }

    // MARK: - Handlers

    private func handle(error: TorError) {

        Logger.log(message: "\(error)", domain: .tor, level: .error)

        switch error {
        case let .connectionFailed(error):
            handle(connectionError: error)
        case .authenticationFailed, .missingController, .missingCookie, .unknown:
            break
        }

        self.error = error
    }

    private func handle(connectionError: Error) {

        guard let posixError = connectionError as? PosixError else { return }

        Logger.log(message: "POSIX Error: \(posixError.code)", domain: .tor, level: .error)

        switch posixError {
        case .connectionRefused:
            Logger.log(message: "Connection Refused. Custom Tor bridged disabled.", domain: .tor, level: .warning)
            TorManagerUserDefaults.isUsingCustomBridges = false
            reinitiateConnection()
        default:
            break
        }
    }
}
