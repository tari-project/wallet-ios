//  YatTransactionView.swift
	
/*
	Package MobileWallet
	Created by Adrian Truszczynski on 21/10/2021
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

import UIKit
import TariCommon
import Lottie

struct YatTransactionViewModel {
    let transactionText: String
    let yatID: String
}

final class YatTransactionView: UIView {
    
    // MARK: - Subviews
    
    @View private var transactionLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    @View private var videoView: VideoView = {
        let view = VideoView()
        view.alpha = 0.0
        return view
    }()
    
    @View private var spinnerView: AnimationView = {
        let view = AnimationView()
        view.backgroundBehavior = .pauseAndRestore
        view.animation = Animation.named(.pendingCircleAnimation)
        view.loopMode = .loop
        view.play()
        return view
    }()
    
    @View private var completionLabel: UILabel = {
        let view = UILabel()
        view.textColor = .white
        view.font = .Avenir.heavy.withSize(30.0)
        view.alpha = 0.0
        view.transform = CGAffineTransform(scaleX: 10.0, y: 10.0)
        return view
    }()
    
    private let bottomAlphaMask: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        return layer
    }()
    
    // MARK: - Properties
    
    var state: YatTransactionViewState = .idle {
        didSet { handle(state: state) }
    }
    
    var onCompletion: (() -> Void)?
    
    private var hiddenScenePath: CGPath { UIBezierPath(ovalIn: CGRect(x: center.x, y: center.y, width: 0.0, height: 0.0)).cgPath }
    private var visibleScenePath: CGPath {
        let aSide = bounds.height * 0.5
        let bSide = bounds.width * 0.5
        let radius = sqrt(aSide * aSide + bSide * bSide)
        return UIBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2.0, height: radius * 2.0)).cgPath
    }
    
    private var transactionLabelCenterConstraint: NSLayoutConstraint?
    private var transactionLabelBottomConstraint: NSLayoutConstraint?
    
    // MARK: - Initalizers
    
    init() {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setups
    
    private func setupViews() {
        backgroundColor = .black
    }
    
    private func setupConstraints() {
        [transactionLabel, videoView, spinnerView, completionLabel].forEach(addSubview)
        
        let transactionLabelCenterConstraint = transactionLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        self.transactionLabelBottomConstraint = transactionLabel.bottomAnchor.constraint(equalTo: spinnerView.topAnchor, constant: -18.0)
        
        self.transactionLabelCenterConstraint = transactionLabelCenterConstraint
        
        let constraints = [
            transactionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30.0),
            transactionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30.0),
            transactionLabelCenterConstraint,
            transactionLabel.widthAnchor.constraint(equalToConstant: 300.0),
            videoView.topAnchor.constraint(equalTo: topAnchor),
            videoView.leadingAnchor.constraint(equalTo: leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: trailingAnchor),
            videoView.bottomAnchor.constraint(equalTo: transactionLabel.topAnchor),
            spinnerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinnerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12.0),
            spinnerView.heightAnchor.constraint(equalToConstant: 32.0),
            spinnerView.widthAnchor.constraint(equalToConstant: 32.0),
            completionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            completionLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - Actions
    
    func refreshViews() {
        videoView.startPlayer()
    }
    
    private func handle(state: YatTransactionViewState) {
        switch state {
        case .idle:
            return
        case let .initial(transaction, yatID):
            startAnimation(transactionText: transaction, yatID: yatID)
        case let .playVideo(url, scaleToFill):
            playVideo(url: url, scaleToFill: scaleToFill)
        case .completion:
            showCompletionMessage(success: true)
        case .failed:
            showCompletionMessage(success: false)
        }
    }
    
    private func startAnimation(transactionText: String, yatID: String) {
        
        let text = localized("yat_transaction.label.transaction", arguments: transactionText, yatID)
        let transactionTextRange = (text as NSString).range(of: transactionText)
        let yatIdRange = (text as NSString).range(of: yatID)
        
        let font = UIFont.Avenir.heavy.withSize(30.0)
        
        let attributedText = NSMutableAttributedString(string: text.uppercased(), attributes: [
            .font: UIFont.Avenir.medium.withSize(30.0),
            .foregroundColor: UIColor.white.withAlphaComponent(0.4)
        ])
        
        [transactionTextRange, yatIdRange]
            .compactMap { $0 }
            .forEach {
                attributedText.setAttributes(
                    [
                        .font: font,
                        .foregroundColor: UIColor.white
                    ],
                    range: $0
                )
            }
        
        transactionLabel.attributedText = attributedText
        transactionLabel.textAlignment = .center
        transactionLabel.lineBreakMode = .byWordWrapping
        
        showScene()
    }
    
    private func playVideo(url: URL, scaleToFill: Bool) {

        videoView.url = url
        videoView.videoGravity = scaleToFill ? .resizeAspectFill : .resizeAspect
        videoView.layer.mask = scaleToFill ? bottomAlphaMask : nil
        transactionLabelCenterConstraint?.isActive = false
        transactionLabelBottomConstraint?.isActive = true
        
        UIView.animate(withDuration: 0.3) {
            self.videoView.alpha = 1.0
            self.layoutIfNeeded()
        }
    }
    
    private func showCompletionMessage(success: Bool) {
        
        completionLabel.text = success ? localized("yat_transaction.label.success") : localized("yat_transaction.label.failed")
        
        UIView.animate(withDuration: 1.0, delay: 0.0, options: [], animations: {
            self.videoView.alpha = 0.0
            self.transactionLabel.alpha = 0.0
            self.spinnerView.alpha = 0.0
            self.completionLabel.alpha = 1.0
            self.completionLabel.transform = .identity
        }, completion: { _ in
            self.hideScene()
        })
    }
    
    private func showScene() {
        animmateSceneSpace(fromPath: hiddenScenePath, toPath: visibleScenePath) { [weak self] in self?.removeMask() }
    }
    
    private func hideScene() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.animmateSceneSpace(fromPath: self.visibleScenePath, toPath: self.hiddenScenePath) { [weak self] in self?.onCompletion?() }
        }
    }
    
    private func animmateSceneSpace(fromPath: CGPath, toPath: CGPath, completion: @escaping () -> Void) {
        
        let maskLayer = CAShapeLayer()
        
        maskLayer.path = fromPath
        layer.mask = maskLayer
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = 0.3
        animation.fromValue = maskLayer.path
        animation.toValue = toPath
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        maskLayer.add(animation, forKey: "path")
        CATransaction.commit()
    }
    
    private func removeMask() {
        layer.mask = nil
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bottomAlphaMask.frame = videoView.bounds
        let startPoint = 100.0 / bottomAlphaMask.bounds.height
        bottomAlphaMask.locations = [0.0, startPoint, 1.0].map { NSNumber(value: $0) }
    }
}
