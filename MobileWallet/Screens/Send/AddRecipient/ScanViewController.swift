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

protocol ScanViewControllerDelegate: class {
    func onAdd(publicKey: PublicKey)
    func onAdd(string: String)
}

extension ScanViewControllerDelegate {
    func onAdd(publicKey: PublicKey) { }
    func onAdd(string: String) { }
}

class ScanViewController: UIViewController {

    enum ScanResourceType {
        case publicKey
        case bridges
    }

    // MARK: - Variables and constants
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    weak var actionDelegate: ScanViewControllerDelegate?
    private let darkenFillLayer = CAShapeLayer()
    private let scanResourceType: ScanResourceType

    let widthRectanglePath: CGFloat = CGFloat(276)
    let heightRectanglePath: CGFloat = CGFloat(259)
    let distanceToTitleLabel: CGFloat = CGFloat(80)
    let heightTitleLabel: CGFloat = CGFloat(44)

    // MARK: - Outlets
    var backButton: UIButton!
    var titleLabel: UILabel!
    var middleView: UIView!
    var topLeftWhiteView: UIView!
    var topRightWhiteView: UIView!
    var bottomLeftWhiteView: UIView!
    var bottomRightWhiteView: UIView!

    init(scanResourceType: ScanResourceType) {
        self.scanResourceType = scanResourceType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        updateConstraintsBackButton()
        updateConstraintsTitleLabel()
        updateConstraintsMiddleView()
        updateConstraintsTopLeftView()
        updateConstraintsTopRightView()
        updateConstraintsBottomLeftView()
        updateConstraintsBottomRightView()
        setupScanner()

        if scanResourceType == .publicKey {
            Tracker.shared.track("/home/send_tari/add_recipient/qr_scan", "Send Tari - Add Recipient - Scan QR Code")
        }
    }

    private func updateConstraintsBackButton() {
        backButton = UIButton(type: .system)
        backButton.setImage(Theme.shared.images.close!, for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(onBackAction), for: .touchUpInside)
        view.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false

        backButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
        backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                             constant: 20).isActive = true
        backButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor,
                                         constant: 20).isActive = true
    }

    private func updateConstraintsTitleLabel() {
        titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                            constant: 64).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                             constant: -64).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        titleLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor,
                                        constant: 76.5).isActive = true
    }

    private func updateConstraintsMiddleView() {
        middleView = UIView()
        middleView.backgroundColor = .clear
        view.addSubview(middleView)
        middleView.translatesAutoresizingMaskIntoConstraints = false
        middleView.centerXAnchor.constraint(equalTo: view.centerXAnchor,
                                                constant: 0).isActive = true
        middleView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                            constant: 80).isActive = true
        middleView.widthAnchor.constraint(equalToConstant: 276).isActive = true
        middleView.heightAnchor.constraint(equalToConstant: 259).isActive = true

    }

    private func updateConstraintsTopLeftView() {
        topLeftWhiteView = UIView()
        topLeftWhiteView.backgroundColor = .clear
        view.addSubview(topLeftWhiteView)
        topLeftWhiteView.translatesAutoresizingMaskIntoConstraints = false
        topLeftWhiteView.topAnchor.constraint(equalTo: middleView.topAnchor,
                                            constant: 0).isActive = true
        topLeftWhiteView.leftAnchor.constraint(equalTo: middleView.leftAnchor,
                                               constant: 0).isActive = true
        topLeftWhiteView.widthAnchor.constraint(equalToConstant: 72).isActive = true
        topLeftWhiteView.heightAnchor.constraint(equalToConstant: 69).isActive = true

    }

    private func updateConstraintsTopRightView() {
        topRightWhiteView = UIView()
        topRightWhiteView.backgroundColor = .clear
        view.addSubview(topRightWhiteView)
        topRightWhiteView.translatesAutoresizingMaskIntoConstraints = false
        topRightWhiteView.topAnchor.constraint(equalTo: middleView.topAnchor,
                                            constant: 0).isActive = true
        topRightWhiteView.rightAnchor.constraint(equalTo: middleView.rightAnchor,
                                               constant: 0).isActive = true
        topRightWhiteView.widthAnchor.constraint(equalToConstant: 72).isActive = true
        topRightWhiteView.heightAnchor.constraint(equalToConstant: 69).isActive = true
    }

    private func updateConstraintsBottomLeftView() {
        bottomLeftWhiteView = UIView()
        bottomLeftWhiteView.backgroundColor = .clear
        view.addSubview(bottomLeftWhiteView)
        bottomLeftWhiteView.translatesAutoresizingMaskIntoConstraints = false
        bottomLeftWhiteView.bottomAnchor.constraint(equalTo: middleView.bottomAnchor,
                                            constant: 0).isActive = true
        bottomLeftWhiteView.leftAnchor.constraint(equalTo: middleView.leftAnchor,
                                               constant: 0).isActive = true
        bottomLeftWhiteView.widthAnchor.constraint(equalToConstant: 72).isActive = true
        bottomLeftWhiteView.heightAnchor.constraint(equalToConstant: 69).isActive = true
    }

    private func updateConstraintsBottomRightView() {
        bottomRightWhiteView = UIView()
        bottomRightWhiteView.backgroundColor = .clear
        view.addSubview(bottomRightWhiteView)
        bottomRightWhiteView.translatesAutoresizingMaskIntoConstraints = false
        bottomRightWhiteView.bottomAnchor.constraint(equalTo: middleView.bottomAnchor,
                                            constant: 0).isActive = true
        bottomRightWhiteView.rightAnchor.constraint(equalTo: middleView.rightAnchor,
                                               constant: 0).isActive = true
        bottomRightWhiteView.widthAnchor.constraint(equalToConstant: 72).isActive = true
        bottomRightWhiteView.heightAnchor.constraint(equalToConstant: 69).isActive = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        customizeScanner()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if captureSession?.isRunning == false {
            captureSession.startRunning()
        }

        customizeViews()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if captureSession?.isRunning == true {
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
        var title: String

        switch scanResourceType {
        case .publicKey:
            title = String(format: NSLocalizedString("scan_view.scan_qr_to_send.with_param", comment: "Scan view"),
                TariSettings.shared.network.currencyDisplayTicker)
        case .bridges:
            title = NSLocalizedString("scan_view.scan_qr_to_set_bridges", comment: "Scan view")
        }
        self.titleLabel.text = title
        self.titleLabel.textColor = Theme.shared.colors.scannerTitle
        self.titleLabel.font = Theme.shared.fonts.scannerTitleLabel
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

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
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

    private func foundQR(qrText: String) {
        switch scanResourceType {
        case .publicKey:
            do {
                let publicKey = try PublicKey(deeplink: qrText)

                self.actionDelegate?.onAdd(publicKey: publicKey)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                UserFeedback.shared.error(
                    title: NSLocalizedString("scan_view.error.title", comment: "Scan view"),
                    description: NSLocalizedString("scan_view.error.public_key.description", comment: "Scan view"),
                    error: error
                )
            }
        case .bridges:
            if let bridges = qrText.findBridges() {
                actionDelegate?.onAdd(string: bridges)
            } else {
                UserFeedback.shared.error(
                    title: NSLocalizedString("scan_view.error.title", comment: "Scan view"),
                    description: NSLocalizedString("scan_view.error.bridges.description", comment: "Scan view"),
                    error: nil
                )
            }

        }

        dismiss(animated: true)
    }

// MARK: - Actions

    @objc func onBackAction() {
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
            foundQR(qrText: stringValue)
        }
    }
}
