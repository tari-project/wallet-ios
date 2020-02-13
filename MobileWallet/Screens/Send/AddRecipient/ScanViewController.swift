//  ScanViewController.swift

/*
	Package MobileWallet
	Created by Gabriel Lupu on 22/01/2020
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

import UIKit
import AVFoundation

protocol ScanViewControllerDelegate {
    func found(code: String)
}

class ScanViewController: UIViewController {

    // MARK: - Variables and constants
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var delegate: ScanViewControllerDelegate?
    private let darkenFillLayer = CAShapeLayer()

    let widthRectanglePath: CGFloat = CGFloat(276)
    let heightRectanglePath: CGFloat = CGFloat(259)
    let distanceToTitleLabel: CGFloat = CGFloat(80)
    let heightTitleLabel: CGFloat = CGFloat(44)

    // MARK: - Outlets
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var middleView: UIView!
    @IBOutlet weak var topLeftWhiteView: UIView!
    @IBOutlet weak var topRightWhiteView: UIView!
    @IBOutlet weak var bottomLeftWhiteView: UIView!
    @IBOutlet weak var bottomRightWhiteView: UIView!

    // MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()

        setupScanner()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        customizeScanner()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }

        customizeViews()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    // MARK: - Private functions
    private func customizeViews() {
        self.titleLabel.text = NSLocalizedString("Scan Tari QR code in the box below to a send Tari to receipient.", comment: "Scan contact camera view")
        topLeftWhiteView.addTopBorder(with: Theme.shared.colors.qrButtonBackground, andWidth: 11)
        topLeftWhiteView.addLeftBorder(with: Theme.shared.colors.qrButtonBackground, andWidth: 11)
        topRightWhiteView.addTopBorder(with: Theme.shared.colors.qrButtonBackground, andWidth: 11)
        topRightWhiteView.addRightBorder(with: Theme.shared.colors.qrButtonBackground, andWidth: 11)
        bottomLeftWhiteView.addLeftBorder(with: Theme.shared.colors.qrButtonBackground, andWidth: 11)
        bottomLeftWhiteView.addBottomBorder(with: Theme.shared.colors.qrButtonBackground, andWidth: 11)
        bottomRightWhiteView.addBottomBorder(with: Theme.shared.colors.qrButtonBackground, andWidth: 11)
        bottomRightWhiteView.addRightBorder(with: Theme.shared.colors.qrButtonBackground, andWidth: 11)
    }

    private func setupScanner() {
        view.backgroundColor = .black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 0)

        captureSession.startRunning()

    }

    private func customizeScanner() {
        let originTitleLabel = titleLabel.frame.origin.y
        let xPositionTitleLabel = (UIScreen.main.bounds.width - widthRectanglePath) / 2
        let yPositionPath = originTitleLabel + distanceToTitleLabel + heightTitleLabel
        let path = UIBezierPath(rect: CGRect(x: 0,
                                             y: 0,
                                             width: self.view.bounds.size.width,
                                             height: self.view.bounds.size.height))
        let rectanglePath = UIBezierPath(rect: CGRect(x: xPositionTitleLabel,
                                                      y: yPositionPath,
                                                      width: widthRectanglePath,
                                                      height: heightRectanglePath))

        path.append(rectanglePath)
        path.usesEvenOddFillRule = true

        darkenFillLayer.path = path.cgPath
        darkenFillLayer.fillRule = .evenOdd
        darkenFillLayer.fillColor = UIColor.black.cgColor
        view.layer.insertSublayer(darkenFillLayer, below: backButton.layer)
        darkenFillLayer.opacity = 0 //TODO change back to 0.7 if it can be faded in
    }

    private func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    private func found(code: String) {
        self.delegate?.found(code: code)
    }

// MARK: - Actions

    @IBAction func onBackAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension ScanViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }

        dismiss(animated: true)
    }
}
