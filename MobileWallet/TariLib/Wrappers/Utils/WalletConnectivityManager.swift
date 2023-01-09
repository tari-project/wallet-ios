//  WalletConnectivityManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 09/11/2021
	Using Swift 5.0
	Running on macOS 12.0

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

final class WalletConnectivityManager {

    private static var cancellables = Set<AnyCancellable>()

    static func connectWithTor(completion: @escaping () -> Void) {
        // Handle if tor ports opened later
        TariEventBus.onMainThread(self, eventType: .torPortsOpened) { _ in
            TariEventBus.unregister(self, eventType: .torPortsOpened)
            completion()
        }
        if TariLib.shared.areTorPortsOpen {
            TariEventBus.unregister(self, eventType: .torPortsOpened)
            completion()
        }
    }

    static func startWalletIfNeeded() {
        guard TariLib.shared.walletState == .notReady else { return }
        TariLib.shared.startWallet(seedWords: nil)
    }

    static func waitForWallet(result: @escaping (Result<Void, WalletError>) -> Void) {

        var cancel: AnyCancellable?

        cancel = TariLib.shared.walletStatePublisher
            .receive(on: RunLoop.main)
            .sink { walletState in
                switch walletState {
                case .started:
                    cancel?.cancel()
                    result(.success(Void()))
                case let .startFailed(error):
                    cancel?.cancel()
                    result(.failure(error))
                case .notReady, .starting:
                    break
                }
            }

        cancel?.store(in: &cancellables)
    }

    static func startWallet(result: @escaping (Result<Void, WalletError>) -> Void) {

        let dispatchGroup = DispatchGroup()
        var startWalletResult: Result<Void, WalletError>?

        dispatchGroup.enter()
        connectWithTor {
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        waitForWallet {
            startWalletResult = $0
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {

            guard let startWalletResult = startWalletResult else {
                result(.failure(.unknown))
                return
            }

            switch startWalletResult {
            case .success:
                result(.success(Void()))
            case let .failure(error):
                result(.failure(error))
            }
        }

        startWalletIfNeeded()
    }
}
