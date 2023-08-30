//  QRCodeScannerView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 11/07/2023
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

import TariCommon
import AVFoundation

final class QRCodeScannerView: UIView {

    enum ActionType {
        case normal
        case error
    }

    struct ActionViewModel {
        let title: String?
        let actionType: ActionType
    }

    // MARK: - Subviews

    private var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer()
        layer.videoGravity = .resizeAspectFill
        return layer
    }()

    @View private var closeButton: BaseButton = {
        let view = BaseButton()
        view.setImage(.icons.close, for: .normal)
        view.tintColor = .static.white
        return view
    }()

    @View private var topContentView = UIView()

    @View private var titleContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .static.popupOverlay
        view.layer.cornerRadius = 10.0
        return view
    }()

    @View private var titleLabel: UILabel = {
        let view = UILabel()
        view.text = localized("qr_code_scanner.labels.title")
        view.textAlignment = .center
        view.font = .Avenir.medium.withSize(16.0)
        view.numberOfLines = 0
        view.textColor = .static.white
        return view
    }()

    @View private var boxView = QRCodeScannerBoxView()
    @View private var bottomContentView = UIView()

    @View private var actionStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 20.0
        view.alignment = .center
        view.distribution = .equalSpacing
        return view
    }()

    @View private var actionLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.textAlignment = .center
        view.font = .Avenir.medium.withSize(14.0)
        return view
    }()

    @View private var buttonsStackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 30.0
        return view
    }()

    @View private var approveButton: RoundedButton = {
        let view = RoundedButton()
        view.setImage(.icons.checkmark, for: .normal)
        view.backgroundColor = .static.white
        view.layer.cornerRadius = 22.0
        return view
    }()

    @View private var cancelButton: RoundedButton = {
        let view = RoundedButton()
        view.setImage(.icons.close, for: .normal)
        view.backgroundColor = .static.white
        view.tintColor = .static.black
        view.layer.cornerRadius = 22.0
        return view
    }()

    @View private var bottomCenteredContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .static.popupOverlay
        view.tintColor = .static.black
        view.layer.cornerRadius = 10.0
        return view
    }()

    // MARK: - Properties

    var videoSession: AVCaptureSession? {
        get { previewLayer.session }
        set { previewLayer.session = newValue }
    }

    var onCloseButtonTap: (() -> Void)?
    var onApproveButtonTap: (() -> Void)?
    var onCancelButtonTap: (() -> Void)?

    // MARK: - Initialisers

    init() {
        super.init(frame: .zero)
        setupView()
        setupLayers()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupView() {
        backgroundColor = .static.black
    }

    private func setupLayers() {
        layer.addSublayer(previewLayer)
    }

    private func setupConstraints() {

        [topContentView, bottomContentView, boxView, closeButton].forEach(addSubview)
        topContentView.addSubview(titleContentView)
        titleContentView.addSubview(titleLabel)
        bottomContentView.addSubview(bottomCenteredContentView)
        bottomCenteredContentView.addSubview(actionStackView)
        [actionLabel, buttonsStackView].forEach(actionStackView.addArrangedSubview)
        [approveButton, cancelButton].forEach(buttonsStackView.addArrangedSubview)

        let constraints = [
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 20.0),
            closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),
            topContentView.topAnchor.constraint(equalTo: topAnchor),
            topContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            topContentView.bottomAnchor.constraint(equalTo: boxView.topAnchor),
            titleContentView.centerXAnchor.constraint(equalTo: topContentView.centerXAnchor),
            titleContentView.centerYAnchor.constraint(equalTo: topContentView.centerYAnchor),
            titleContentView.leadingAnchor.constraint(equalTo: topContentView.leadingAnchor, constant: 34.0),
            titleContentView.trailingAnchor.constraint(equalTo: topContentView.trailingAnchor, constant: -34.0),
            titleLabel.topAnchor.constraint(equalTo: titleContentView.topAnchor, constant: 10.0),
            titleLabel.leadingAnchor.constraint(equalTo: titleContentView.leadingAnchor, constant: 10.0),
            titleLabel.trailingAnchor.constraint(equalTo: titleContentView.trailingAnchor, constant: -10.0),
            titleLabel.bottomAnchor.constraint(equalTo: titleContentView.bottomAnchor, constant: -10.0),
            boxView.centerXAnchor.constraint(equalTo: centerXAnchor),
            boxView.centerYAnchor.constraint(equalTo: centerYAnchor),
            boxView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.75),
            boxView.heightAnchor.constraint(equalTo: boxView.widthAnchor),
            bottomContentView.topAnchor.constraint(equalTo: boxView.bottomAnchor),
            bottomContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomContentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomCenteredContentView.centerXAnchor.constraint(equalTo: bottomContentView.centerXAnchor),
            bottomCenteredContentView.centerYAnchor.constraint(equalTo: bottomContentView.centerYAnchor),
            bottomCenteredContentView.topAnchor.constraint(greaterThanOrEqualTo: bottomContentView.topAnchor, constant: 22.0),
            bottomCenteredContentView.leadingAnchor.constraint(equalTo: bottomContentView.leadingAnchor, constant: 34),
            bottomCenteredContentView.trailingAnchor.constraint(equalTo: bottomContentView.trailingAnchor, constant: -34.0),
            bottomCenteredContentView.bottomAnchor.constraint(lessThanOrEqualTo: bottomContentView.bottomAnchor, constant: -22.0),
            actionStackView.topAnchor.constraint(equalTo: bottomCenteredContentView.topAnchor, constant: 15.0),
            actionStackView.leadingAnchor.constraint(equalTo: bottomCenteredContentView.leadingAnchor, constant: 15.0),
            actionStackView.trailingAnchor.constraint(equalTo: bottomCenteredContentView.trailingAnchor, constant: -15.0),
            actionStackView.bottomAnchor.constraint(equalTo: bottomCenteredContentView.bottomAnchor, constant: -15.0),
            approveButton.heightAnchor.constraint(equalToConstant: 44.0),
            approveButton.widthAnchor.constraint(equalToConstant: 44.0),
            cancelButton.heightAnchor.constraint(equalToConstant: 44.0),
            cancelButton.widthAnchor.constraint(equalToConstant: 44.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        closeButton.onTap = { [weak self] in
            self?.onCloseButtonTap?()
        }

        approveButton.onTap = { [weak self] in
            self?.onApproveButtonTap?()
        }

        cancelButton.onTap = { [weak self] in
            self?.onCancelButtonTap?()
        }
    }

    // MARK: - Updates

    func update(actionViewModel: ActionViewModel?) {
        Task {
            await hideActionView()
            showActionView(model: actionViewModel)
        }
    }

    private func updateActionLabel(actionType: ActionType) {
        switch actionType {
        case .normal:
            self.actionLabel.textColor = .static.white
        case .error:
            self.actionLabel.textColor = .static.red
        }
    }

    // MARK: - Actions

    private func hideActionView() async {
        await withCheckedContinuation { continuation in
            UIView.animate(withDuration: 0.2,
                           animations: { self.bottomCenteredContentView.alpha = 0.0 },
                           completion: { _ in continuation.resume() }
            )
        }
    }

    private func showActionView(model: ActionViewModel?) {

        buttonsStackView.isHidden = model?.actionType == .error

        UIView.animate(withDuration: 0.2) {
            self.bottomCenteredContentView.alpha = model != nil ? 1.0 : 0.0

            guard let model else { return }

            self.actionLabel.text = model.title
            self.updateActionLabel(actionType: model.actionType)
        }
    }

    // MARK: - Autolayout

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}
