//  Logger.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 07/10/2022
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

protocol Logable {
    func log(message: String, domain: Logger.Domain, logLevel: Logger.Level)
}

extension Logable {
    static var tag: String { String(describing: self) }
}

final class Logger {

    enum Level: CaseIterable {
        case verbose
        case info
        case warning
        case error
    }

    enum Domain: CaseIterable {
        case general
        case connection
        case navigation
        case userInterface
        case stagedWalletSecurity
        case bleCentral
        case blePeripherial
        case debug
    }

    static var domains: [Domain] = []
    private static var loggers: [String: Logable] = [:]

    static func attach(logger: Logable) {
        loggers[type(of: logger).tag] = logger
    }

    static func log(message: String, domain: Domain, level: Level, tags: [String]? = nil) {

        loggers
            .filter {
                guard let tags = tags else { return true }
                return tags.contains($0.key)
            }
            .map(\.value)
            .forEach { $0.log(message: message, domain: domain, logLevel: level) }
    }
}

extension Logger.Domain {

    var name: String {
        switch self {
        case .general:
            return "General"
        case .connection:
            return "Connection"
        case .navigation:
            return "Navigation"
        case .userInterface:
            return "UI"
        case .stagedWalletSecurity:
            return "Wallet Security"
        case .bleCentral:
            return "BLE - Central"
        case .blePeripherial:
            return "BLE - Peripherial"
        case .debug:
            return "Debug"
        }
    }
}
