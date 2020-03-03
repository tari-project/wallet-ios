//  OnionConnecter.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2020/03/02
	Using Swift 5.0
	Running on macOS 10.15

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

import Foundation

public final class OnionConnector {
    public enum OnionError: Error {
        case connectionError
    }

    private var progress: ((Int) -> Void)?
    private var completion: ((Result<URLSessionConfiguration, OnionError>) -> Void)?

    public init() {}

    public func start(progress: ((Int) -> Void)?, completion: @escaping (Result<URLSessionConfiguration, OnionError>) -> Void) {
        self.progress = progress
        self.completion = completion
        OnionManager.shared.startTor(delegate: self)
    }
}

extension OnionConnector: OnionManagerDelegate {
    func torConnProgress(_ progress: Int) {
        self.progress?(progress)
    }

    func torConnFinished(configuration: URLSessionConfiguration) {
        // TODO: this is a fix for Tor 400.5.2. Can be removed once there is a
        // new release on github.
        configuration.connectionProxyDictionary = [
            kCFProxyTypeKey: kCFProxyTypeSOCKS,
            kCFStreamPropertySOCKSProxyHost: "localhost",
            kCFStreamPropertySOCKSProxyPort: 39059
        ]
        if #available(iOSApplicationExtension 13.0, *) {
            configuration.tlsMaximumSupportedProtocolVersion = .TLSv12
        } else {
            configuration.tlsMinimumSupportedProtocol = .tlsProtocol12
        }
        completion?(.success(configuration))
    }

    func torConnError() {
        print("Tor connection error")
        completion?(.failure(.connectionError))
    }
}
