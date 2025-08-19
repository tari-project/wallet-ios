//  VideoCaptureManager.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 12/07/2023
	Using Swift 5.0
	Running on macOS 13.4

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

import AVFoundation

final class VideoCaptureManager: NSObject {
    enum ScanResult {
        case invalid
        case validDeeplink(DeepLinkable)
        case base64Address(String)
    }

    enum SetupError: Error {
        case noValidDevice
        case cantAddInput
        case cantAddOutput
    }

    // MARK: - Properties

    let captureSession = AVCaptureSession()

    @Published private(set) var result: ScanResult?

    // MARK: - Setups

    func setupSession() throws {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { throw SetupError.noValidDevice }
        let videoInput = try AVCaptureDeviceInput(device: captureDevice)
        guard captureSession.canAddInput(videoInput) else { throw SetupError.cantAddInput }
        captureSession.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(metadataOutput) else { throw SetupError.cantAddOutput }
        captureSession.addOutput(metadataOutput)

        metadataOutput.metadataObjectTypes = [.qr]
        metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
    }

    func startSession() {
        guard !captureSession.isRunning else { return }
        DispatchQueue.global().async {
            self.captureSession.startRunning()
        }
    }

    func stopSession() {
        guard captureSession.isRunning else { return }
        DispatchQueue.global().async {
            self.captureSession.stopRunning()
        }
    }
}

extension VideoCaptureManager: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let rawData = object.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            result = .invalid
            return
        }

        do {
            if let deeplink = try DeeplinkHandler.deeplink(rawDeeplink: rawData) {
                result = .validDeeplink(deeplink)
            } else if (try? TariAddress(base58: rawData)) != nil {
                result = .base64Address(rawData)
            } else {
                result = .invalid
            }
        } catch {
            print("Failed to parse QR code data: \(error)")
            result = .invalid
        }
    }
}
