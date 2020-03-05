//  SendingTariViewController.swift

/*
	Package MobileWallet
	Created by Gabriel Lupu on 27/02/2020
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
import Lottie

class SendingTariViewController: UIViewController {

    // MARK: - Variables and constants
    private var player: AVQueuePlayer!
    private var playerLayer: AVPlayerLayer!
    private var playerItem: AVPlayerItem!
    private var playerLooper: AVPlayerLooper!

    var titleLabelTopConstraint: NSLayoutConstraint?
    var animationContainer: AnimationView!
    var createWalletButton: ActionButton!
    var titleLabel: UILabel!
    var videoView: UIView!
    var bottomView = UIView()

    var tariAmount: MicroTari?

    var animationStarted: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        updateConstraintsVideoView()
        updateConstraintsAnimationContainer()
        updateConstraintsTitleLabel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLayoutSubviews() {
        if !animationStarted {
            setupVideoAnimation()
            loadAnimation()
            startAnimation()
        }
    }

    // MARK: - Private functions
    private func setupVideoAnimation() {
        if let path = Bundle.main.path(forResource: "sending-background", ofType: "mp4") {

            _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: .default, options: .mixWithOthers)
            let pathURL = URL(fileURLWithPath: path)
            let duration = Int64( ( (Float64(CMTimeGetSeconds(AVAsset(url: pathURL).duration)) *  10.0) - 1) / 10.0 )

            player = AVQueuePlayer()
            playerLayer = AVPlayerLayer(player: player)
            playerItem = AVPlayerItem(url: pathURL)
            playerLooper = AVPlayerLooper(player: player,
                                          templateItem: playerItem,
                                          timeRange: CMTimeRange(start: CMTime.zero, end: CMTimeMake(value: duration, timescale: 1)))
            playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
            playerLayer.frame = videoView.layer.bounds
            player.play()
            videoView.layer.insertSublayer(playerLayer, at: 0)
            videoView.clipsToBounds = true
        }
    }

    private func setupView() {
        self.view.backgroundColor = Theme.shared.colors.sendingTariBackground!
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func updateConstraintsVideoView() {
        videoView = UIView()
        view.addSubview(videoView)
        videoView.translatesAutoresizingMaskIntoConstraints = false

        videoView.topAnchor.constraint(equalTo: view.topAnchor,
                                       constant: 0).isActive = true
        videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                           constant: 0).isActive = true
        videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
    }

    private func updateConstraintsAnimationContainer() {
        animationContainer = AnimationView()
        view.addSubview(animationContainer)
        animationContainer.translatesAutoresizingMaskIntoConstraints = false
        animationContainer.widthAnchor.constraint(equalToConstant: 55).isActive = true
        animationContainer.heightAnchor.constraint(equalToConstant: 55).isActive = true
        animationContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor,
                                                    constant: 0).isActive = true
        animationContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor,
                                                    constant: 0).isActive = true

    }

    private func updateConstraintsBottomView() {
        bottomView.backgroundColor = Theme.shared.colors.sendingTariBackground
        view.addSubview(bottomView)
        bottomView.translatesAutoresizingMaskIntoConstraints = false

        bottomView.topAnchor.constraint(equalTo: animationContainer.bottomAnchor,
                                       constant: 50).isActive = true
        bottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                           constant: 0).isActive = true
        bottomView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        bottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
    }

    private func updateConstraintsTitleLabel() {
        titleLabel = UILabel()
        view.addSubview(titleLabel)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true

        titleLabelTopConstraint = titleLabel.topAnchor.constraint(equalTo: animationContainer.bottomAnchor, constant: 20)
        titleLabelTopConstraint?.isActive = true

        let sendingString = String(format: NSLocalizedString("Sending %@ Tari…", comment: "Title Label on the sending tari screen"), tariAmount?.formatted ?? "")

        let attributedString = NSMutableAttributedString(
            string: sendingString,
            attributes: [
                .font: Theme.shared.fonts.sendingTariTitleLabelFirst!,
                .foregroundColor: Theme.shared.colors.sendingTariTitle!,
                .kern: -0.33
        ])

        //TODO this is broken, need to use the char positons and not just hardcoded ranges
        attributedString.addAttribute(.font, value: Theme.shared.fonts.sendingTariTitleLabelSecond!, range: NSRange(location: 0, length: 7))
        attributedString.addAttribute(.font, value: Theme.shared.fonts.sendingTariTitleLabelThird!, range: NSRange(location: 16, length: 1))

        titleLabel.attributedText = attributedString
    }

    private func loadAnimation() {
        let animation = Animation.named("sendingTariAnimation")
        animationContainer.animation = animation
    }

    private func runTitleLabelAnimation() {
        self.titleLabelTopConstraint?.constant = 20
        UIView.animate(withDuration: 1, animations: { [weak self] in
            guard let self = self else { return }
            self.view.layoutIfNeeded()
        }) { [weak self] _ in
            guard let self = self else { return }
            self.bottomView.alpha = 0.0
        }
    }

    private func startAnimation() {
        self.animationContainer.play(
            fromProgress: 0,
            toProgress: 1,
            loopMode: .playOnce,
            completion: { [weak self] (_) in
                guard let self = self else { return }
                self.removeTitleAnimation()
            }
        )
    }

    private func removeTitleAnimation() {
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let self = self else { return }
            self.titleLabel.alpha = 0.0
            self.view.layoutIfNeeded()
        }) { [weak self] (_) in
            guard let self = self else { return }
            self.navigationController?.popToRootViewController(animated: false)
        }
    }
}
