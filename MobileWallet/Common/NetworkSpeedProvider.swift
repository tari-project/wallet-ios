//  NetworkSpeedProvider.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 24.07.2020
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

class NetworkSpeedProvider: NSObject {

    typealias SpeedTestCompletion = (_ megabytesPerSecond: Float, _ error: Error?) -> Void

    private var startTime = CFAbsoluteTime()
    private var stopTime = CFAbsoluteTime()
    private var bytesReceived: Float = 0
    private var speedTestCompletionHandler: SpeedTestCompletion?

    func testSpeed(completion:  @escaping SpeedTestCompletion) {
        testDownloadSpeed(withTimout: 5.0, completionHandler: completion)
    }
}

extension NetworkSpeedProvider: URLSessionDataDelegate, URLSessionDelegate {
    func testDownloadSpeed(withTimout timeout: TimeInterval, completionHandler: @escaping SpeedTestCompletion) {
        let urlForSpeedTest = URL(string: "https://images.apple.com/v/imac-with-retina/a/images/overview/5k_image.jpg")
        startTime = CFAbsoluteTimeGetCurrent()
        stopTime = startTime
        bytesReceived = 0
        speedTestCompletionHandler = completionHandler
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)

        guard let checkedUrl = urlForSpeedTest else { return }

        session.dataTask(with: checkedUrl).resume()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        bytesReceived += Float(data.count)
        stopTime = CFAbsoluteTimeGetCurrent()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let elapsed = (stopTime - startTime) // as? CFAbsoluteTime
        let speed: Float = elapsed != 0 ? bytesReceived / (Float(CFAbsoluteTimeGetCurrent() - startTime)) / 1024.0 / 1024.0 : -1.0
        // treat timeout as no error (as we're testing speed, not worried about whether we got entire resource or not
        if error == nil || ((((error as NSError?)?.domain) == NSURLErrorDomain) && (error as NSError?)?.code == NSURLErrorTimedOut) {
            speedTestCompletionHandler?(speed, nil)
        } else {
            speedTestCompletionHandler?(speed, error)
        }
    }
}
