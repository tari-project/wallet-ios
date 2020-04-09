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
    var animationContainer = AnimationView()
    var createWalletButton = ActionButton()
    var titleLabel = UILabel()
    var videoView = UIView()
    var bottomView = UIView()
    var debugLabel = UILabel()
    var debugMessage = "" {
        didSet {
            debugLabel.text = "DEBUG STATUS: \(debugMessage)"
        }
    }

    var tariAmount: MicroTari?

    var animationStarted: Bool = false

    private var isDiscoveryComplete = false
    private var onDiscoveryComplete: ((Bool) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraintsVideoView()
        setupConstraintsAnimationContainer()
        setupTitleLabel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.setupDebugLabel()
    }

    override func viewDidLayoutSubviews() {
        if !animationStarted {
            animationStarted = true
            setupVideoAnimation()
            loadAnimation()
            handleSendingComplete()
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
            playerLooper = AVPlayerLooper(
                player: player,
                templateItem: playerItem,
                timeRange: CMTimeRange(
                    start: CMTime.zero,
                    end: CMTimeMake(value: duration, timescale: 1)
                )
            )
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

    private func setupConstraintsVideoView() {
        view.addSubview(videoView)
        videoView.translatesAutoresizingMaskIntoConstraints = false

        videoView.topAnchor.constraint(equalTo: view.topAnchor,
                                       constant: 0).isActive = true
        videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                           constant: 0).isActive = true
        videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
    }

    private func setupConstraintsAnimationContainer() {
        view.addSubview(animationContainer)
        animationContainer.translatesAutoresizingMaskIntoConstraints = false
        animationContainer.widthAnchor.constraint(equalToConstant: 55).isActive = true
        animationContainer.heightAnchor.constraint(equalToConstant: 55).isActive = true
        animationContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor,
                                                    constant: 0).isActive = true
        animationContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor,
                                                    constant: 0).isActive = true
    }

    private func setupConstraintsBottomView() {
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

    private func setupTitleLabel() {
        view.addSubview(titleLabel)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true

        titleLabelTopConstraint = titleLabel.topAnchor.constraint(equalTo: animationContainer.bottomAnchor, constant: 20)
        titleLabelTopConstraint?.isActive = true

        let sendingString = String(format: NSLocalizedString("Sending %@ Tari...", comment: "Title Label on the sending tari screen"), tariAmount?.formatted ?? "")

        let attributedString = NSMutableAttributedString(
            string: sendingString,
            attributes: [
                .font: Theme.shared.fonts.sendingTariTitleLabelSecond!,
                .foregroundColor: Theme.shared.colors.sendingTariTitle!,
                .kern: -0.33
        ])

        attributedString.addAttribute(.font, value: Theme.shared.fonts.sendingTariTitleLabelFirst!, range: NSRange(location: 0, length: 7)) //"Sending"
        if let elipsesPosition = sendingString.indexDistance(of: "...") {
            attributedString.addAttribute(.font, value: Theme.shared.fonts.sendingTariTitleLabelFirst!, range: NSRange(location: elipsesPosition, length: 3)) // "..."
        }

        titleLabel.attributedText = attributedString
    }

    //Small label at the bottom of the view, only visible when app is running in debug mode
    private func setupDebugLabel() {
        if TariSettings.shared.isDebug {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }

                self.view.addSubview(self.debugLabel)
                self.view.bringSubviewToFront(self.debugLabel)
                self.debugLabel.textAlignment = .center
                self.debugLabel.font = Theme.shared.fonts.sendingTariTitleLabelFirst!.withSize(12)
                self.debugLabel.translatesAutoresizingMaskIntoConstraints = false
                self.debugLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
                self.debugLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true
                self.debugLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 5).isActive = true
            }
        }
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

    //If a discovery has not happened, start listening so we know when to finish this send animation
    func startListeningForDiscovery() {
        TariLogger.info("Waiting for discovery callback")
        TariEventBus.onMainThread(self, eventType: .discoveryProcessComplete) { [weak self] (result) in
            guard let self = self else { return }

            self.isDiscoveryComplete = true

            //TODO check which tx we're listening for once added to the callback in Wallet.swift
            var isSuccess = true //Assume true
            if let success: Bool = result?.object as? Bool {
                isSuccess = success
            }

            if let callback = self.onDiscoveryComplete {
                callback(isSuccess)
            }
        }
    }

    private func checkDiscoveryComplete(_ onComplete: @escaping (Bool) -> Void) {
        if isDiscoveryComplete {
            onComplete(true)
        } else {
            self.onDiscoveryComplete = onComplete
        }
    }

    private func animateSuccess(from: AnimationProgressTime, to: AnimationProgressTime, onComplete: @escaping () -> Void) {
        self.animationContainer.play(fromProgress: from, toProgress: to, loopMode: .playOnce) { (_) in
            onComplete()
        }
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

    private func handleSendingComplete() {
        let pauseAnimationAt: AnimationProgressTime = 0.2

        //1. Start the animation
        //2. Wait till discovery is complete
        //3. Complete the animation if successful, else just go straight back without the success animation

        debugMessage = isDiscoveryComplete ? "Discovery complete" : "Discovery in progress..."

        animateSuccess(from: 0, to: pauseAnimationAt) { [weak self] () in
            guard let self = self else { return }

            self.checkDiscoveryComplete { [weak self] (discoverySuccess) in
                guard let self = self else { return }

                if discoverySuccess {
                    self.debugMessage = "Peer discovered successfully"
                    TariLogger.info("Peer discovered successfully")
                    //Success animation
                    self.animateSuccess(from: pauseAnimationAt, to: 1) { [weak self] () in
                        guard let self = self else { return }
                        self.removeTitleAnimation()

                        Tracker.shared.track("/home/send_tari/successful", "Send Tari - Successful")
                    }
                } else {
                    self.debugMessage = "Failed to discover peer"
                    TariLogger.error("Failed to discover peer")
                    //No success animation, just go home and display an error
                    self.removeTitleAnimation()

                    UserFeedback.shared.error(
                        title: NSLocalizedString("Sorry, you can't send Tari to offline users", comment: "Discovery failed when sending a tx"),
                        description: NSLocalizedString("Please make sure your recipient has a reliable internet connection and has the Aurora app open on their device, and then try again. If that doesn't work, please verify you have the correct Emoji ID.", comment: "Discovery failed when sending a tx")
                    )
                }
            }
        }
    }
}
