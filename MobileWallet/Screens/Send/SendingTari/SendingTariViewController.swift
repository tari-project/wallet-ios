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

    private enum CompletionStatus {
        case internetConnectionError
        // tor or base node sync timeout
        case networkConnectionTimeout
        case sendError(error: Error?)
        case directSendSuccessful
        case storeAndForwardSendSuccessful
    }

    private enum Step {
        case initialized
        case connectionCheck
        case discovery
        case sent

        // top line and bottom line in a tuple
        var titleLines: (String, String) {
            switch self {
            case .initialized:
                return ("", "")
            case .connectionCheck:
                return (
                    NSLocalizedString("sending_tari.connecting", comment: "SendingTari view"),
                    NSLocalizedString("sending_tari.network", comment: "SendingTari view")
                )
            case .discovery:
                return (
                    NSLocalizedString("sending_tari.searching", comment: "SendingTari view"),
                    NSLocalizedString("sending_tari.recipient", comment: "SendingTari view")
                )
            case .sent:
                return (
                    NSLocalizedString("sending_tari.sent", comment: "SendingTari view"),
                    NSLocalizedString("sending_tari.transaction_is_on_its_way", comment: "SendingTari view")
                )
            }
        }
    }

    // MARK: - Variables and constants
    private var player: AVQueuePlayer!
    private var playerLayer: AVPlayerLayer!
    private var playerItem: AVPlayerItem!
    private var playerLooper: AVPlayerLooper!

    private let animationView = AnimationView()
    private let createWalletButton = ActionButton()

    // title labels - 2 lines
    private let titleLine1ContainerView = UIView()
    private let titleLine1Label = UILabel()
    private var titleLine1LabelTopConstraint: NSLayoutConstraint!
    private let titleLine2ContainerView = UIView()
    private let titleLine2Label = UILabel()
    private var titleLine2LabelTopConstraint: NSLayoutConstraint!

    // progress bars
    private let progressBar1View = UIView()
    private let progressBar1ProgressView = UIView()
    private var progress1WidthConstraint: NSLayoutConstraint!
    private let progressBar2View = UIView()
    private let progressBar2ProgressView = UIView()
    private var progress2WidthConstraint: NSLayoutConstraint!
    private let progressBar3View = UIView()
    private let progressBar3ProgressView = UIView()
    private var progress3WidthConstraint: NSLayoutConstraint!

    private let videoView = UIView()
    private let debugLabel = UILabel()
    private var debugMessage = "" {
        didSet {
            debugLabel.text = "DEBUG STATUS: \(debugMessage)"
        }
    }

    // should be set by previous view controller
    var recipientPubKey: PublicKey!
    var amount: MicroTari!
    var note: String!

    // will be set when tx is sent
    var txId: UInt64!

    var animationStarted: Bool = false

    private var currentStep = Step.initialized
    private var currentProgressBarWidthConstraint: NSLayoutConstraint!
    private var currentStepAnimRepeatCount = 0
    private let activeProgressBarBackgroundColor =
        Theme.shared.colors.sendingTariActiveProgressBackground

    private var connectionCheckStartDate: Date!
    private let connectionTimeoutSec = 30

    private let progressBarWidth = CGFloat(55)
    private let progressBarHeight = CGFloat(4)

    private let pauseLottieAnimationAt: AnimationProgressTime = 0.2

    private var completionStatus: CompletionStatus?
    private var storeAndForwardSendHasFailed = false
    private var directSendHasFailed = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraintsVideoView()
        setupConstraintsAnimationContainer()
        setupTitleLabel(
            label: titleLine1Label,
            containerView: titleLine1ContainerView,
            topView: animationView,
            topMargin: 30,
            font: Theme.shared.fonts.sendingTariTitleLabelFirst
        )
        titleLine1LabelTopConstraint = titleLine1Label.topAnchor.constraint(
            equalTo: titleLine1ContainerView.topAnchor,
            constant: 0
        )
        titleLine1LabelTopConstraint.isActive = true
        setupTitleLabel(
            label: titleLine2Label,
            containerView: titleLine2ContainerView,
            topView: titleLine1ContainerView,
            topMargin: 4,
            font: Theme.shared.fonts.sendingTariTitleLabelSecond
        )
        titleLine2LabelTopConstraint = titleLine2Label.topAnchor.constraint(
            equalTo: titleLine2ContainerView.topAnchor,
            constant: 0
        )
        titleLine2LabelTopConstraint.isActive = true
        setupProgressBars()
        // hide progres bars initially
        progressBar1View.alpha = 0
        progressBar2View.alpha = 0
        progressBar3View.alpha = 0

        Tracker.shared.track("/home/send_tari/finalize", "Send Tari - Finalize")
    }

    override func viewDidLayoutSubviews() {
        if !animationStarted {
            animationStarted = true
            setupVideoAnimation()
            // video takes a while to start - delay the rest of the UI to sync
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                [weak self] in
                self?.loadAnimation()
                self?.proceedToNextStep()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.setupDebugLabel()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    // MARK: - Private functions
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
        videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                            constant: 0).isActive = true
        videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                          constant: 0).isActive = true
    }

    private func setupConstraintsAnimationContainer() {
        view.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.widthAnchor.constraint(equalToConstant: 55).isActive = true
        animationView.heightAnchor.constraint(equalToConstant: 55).isActive = true
        animationView.centerXAnchor.constraint(
            equalTo: view.centerXAnchor,
            constant: 0
        ).isActive = true
        animationView.centerYAnchor.constraint(
            equalTo: view.centerYAnchor,
            constant: -70
        ).isActive = true
    }

    private func setupTitleLabel(label: UILabel,
                                 containerView: UIView,
                                 topView: UIView,
                                 topMargin: Int,
                                 font: UIFont?) {
        view.addSubview(containerView)
        containerView.clipsToBounds = true
        containerView.addSubview(label)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.centerXAnchor.constraint(
            equalTo: view.centerXAnchor,
            constant: 0
        ).isActive = true
        containerView.topAnchor.constraint(
            equalTo: topView.bottomAnchor,
            constant: CGFloat(topMargin)
        ).isActive = true
        containerView.heightAnchor.constraint(
            equalTo: label.heightAnchor,
            constant: 0
        ).isActive = true
        containerView.widthAnchor.constraint(
            equalTo: label.widthAnchor,
            constant: 0
        ).isActive = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = font
    }

    private func setupProgressBars() {
        // middle bar
        view.addSubview(progressBar2View)
        progressBar2View.translatesAutoresizingMaskIntoConstraints = false
        progressBar2View.backgroundColor = Theme.shared.colors.sendingTariPassiveProgressBackground
        progressBar2View.widthAnchor.constraint(equalToConstant: progressBarWidth).isActive = true
        progressBar2View.heightAnchor.constraint(equalToConstant: progressBarHeight).isActive = true
        progressBar2View.centerXAnchor.constraint(
            equalTo: view.centerXAnchor,
            constant: 0
        ).isActive = true
        progressBar2View.topAnchor.constraint(
            equalTo: titleLine2ContainerView.bottomAnchor,
            constant: 40
        ).isActive = true
        // progress
        progress2WidthConstraint = setupProgressBarProgressView(
            progressBarView: progressBar2View,
            progressBarProgressView: progressBar2ProgressView
        )

        // left bar
        view.addSubview(progressBar1View)
        progressBar1View.translatesAutoresizingMaskIntoConstraints = false
        progressBar1View.backgroundColor = Theme.shared.colors.sendingTariPassiveProgressBackground
        progress1WidthConstraint = progressBar1View.widthAnchor.constraint(equalToConstant: progressBarWidth)
        progress1WidthConstraint.isActive = true
        progressBar1View.heightAnchor.constraint(equalToConstant: progressBarHeight).isActive = true
        progressBar1View.trailingAnchor.constraint(
            equalTo: progressBar2View.leadingAnchor,
            constant: -6
        ).isActive = true
        progressBar1View.topAnchor.constraint(
            equalTo: progressBar2View.topAnchor,
            constant: 0
        ).isActive = true
        // progress
        progress1WidthConstraint = setupProgressBarProgressView(
            progressBarView: progressBar1View,
            progressBarProgressView: progressBar1ProgressView
        )

        // right bar
        view.addSubview(progressBar3View)
        progressBar3View.translatesAutoresizingMaskIntoConstraints = false
        progressBar3View.backgroundColor = Theme.shared.colors.sendingTariPassiveProgressBackground
        progress3WidthConstraint = progressBar3View.widthAnchor.constraint(equalToConstant: progressBarWidth)
        progress3WidthConstraint.isActive = true
        progressBar3View.heightAnchor.constraint(equalToConstant: progressBarHeight).isActive = true
        progressBar3View.leadingAnchor.constraint(
            equalTo: progressBar2View.trailingAnchor,
            constant: 6
        ).isActive = true
        progressBar3View.topAnchor.constraint(
            equalTo: progressBar2View.topAnchor,
            constant: 0
        ).isActive = true
        // progress
        progress3WidthConstraint = setupProgressBarProgressView(
            progressBarView: progressBar3View,
            progressBarProgressView: progressBar3ProgressView
        )
    }

    private func setupProgressBarProgressView(progressBarView: UIView,
                                              progressBarProgressView: UIView) -> NSLayoutConstraint {
        progressBarView.addSubview(progressBarProgressView)
        progressBarProgressView.translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = progressBarProgressView.widthAnchor.constraint(equalToConstant: 0)
        widthConstraint.isActive = true
        progressBarProgressView.heightAnchor.constraint(equalToConstant: progressBarHeight).isActive = true
        progressBarProgressView.backgroundColor = Theme.shared.colors.sendingTariProgress
        progressBarProgressView.leadingAnchor.constraint(
            equalTo: progressBarView.leadingAnchor,
            constant: 0
        ).isActive = true
        progressBarProgressView.topAnchor.constraint(
            equalTo: progressBarView.topAnchor,
            constant: 0
        ).isActive = true
        return widthConstraint
    }

    private func setupVideoAnimation() {
        if let path = Bundle.main.path(forResource: "sending-background", ofType: "mp4") {
            _ = try? AVAudioSession.sharedInstance().setCategory(
                AVAudioSession.Category.playback,
                mode: .default,
                options: .mixWithOthers
            )
            let pathURL = URL(fileURLWithPath: path)
            let duration = Int64(
                ((Float64(CMTimeGetSeconds(AVAsset(url: pathURL).duration)) *  10.0) - 1) / 10.0
            )

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
            playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            playerLayer.frame = videoView.layer.bounds
            player.play()
            videoView.layer.insertSublayer(playerLayer, at: 0)
            videoView.clipsToBounds = true
        }
    }

    //Small label at the bottom of the view, only visible when app is running in debug mode
    private func setupDebugLabel() {
        if TariSettings.shared.environment == .debug {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }

                self.view.addSubview(self.debugLabel)
                self.view.bringSubviewToFront(self.debugLabel)
                self.debugLabel.textAlignment = .center
                self.debugLabel.font = Theme.shared.fonts.sendingTariTitleLabelFirst.withSize(12)
                self.debugLabel.translatesAutoresizingMaskIntoConstraints = false
                self.debugLabel.leadingAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.leadingAnchor,
                    constant: Theme.shared.sizes.appSidePadding
                ).isActive = true
                self.debugLabel.trailingAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.trailingAnchor,
                    constant: -Theme.shared.sizes.appSidePadding
                ).isActive = true
                self.debugLabel.topAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.bottomAnchor,
                    constant: 5
                ).isActive = true
            }
        }
    }

    private func loadAnimation() {
        let animation = Animation.named("sendingTariAnimation")
        animationView.animation = animation
        animationView.play(
            fromProgress: 0,
            toProgress: pauseLottieAnimationAt,
            loopMode: .playOnce
        )
    }

    // Progress to the next step if possible, otherwise repeat progress animation.
    private func proceedToNextStep() {
        // check if it has failed already
        if let completionStatus = completionStatus {
            switch completionStatus {
            case .internetConnectionError, .networkConnectionTimeout, .sendError:
                DispatchQueue.main.async {
                    [weak self] in
                    self?.fail()
                }
                return
            default:
                break
            }
        }
        switch currentStep {
        case .initialized:
            currentStep = .connectionCheck
            currentStepAnimRepeatCount = 0
            progressBar1View.backgroundColor = activeProgressBarBackgroundColor
            currentProgressBarWidthConstraint = progress1WidthConstraint
            displayCurrentStep {
                [weak self] in
                self?.connectionCheckStartDate = Date()
                self?.animateCurrentStep()
            }
        case .connectionCheck:
            if checkConnection {
                hideTitleLabels {
                    [weak self] in
                    guard let self = self else { return }
                    self.currentStep = .discovery
                    self.progressBar2View.backgroundColor = self.activeProgressBarBackgroundColor
                    self.currentStepAnimRepeatCount = 0
                    self.currentProgressBarWidthConstraint = self.progress2WidthConstraint
                    self.displayCurrentStep {
                        [weak self] in
                        self?.animateCurrentStep()
                    }
                    self.sendTransaction()
                }
            } else {
                animateCurrentStep()
            }
        case .discovery:
            if let completionStatus = completionStatus {
                switch completionStatus {
                case .storeAndForwardSendSuccessful, .directSendSuccessful:
                    hideTitleLabels {
                        [weak self] in
                        guard let self = self else { return }
                        self.currentStep = .sent
                        self.progressBar3View.backgroundColor = self.activeProgressBarBackgroundColor
                        self.currentStepAnimRepeatCount = 0
                        self.currentProgressBarWidthConstraint = self.progress3WidthConstraint
                        self.displayCurrentStep {
                            [weak self] in
                            self?.animateCurrentStep()
                        }
                    }
                default:
                    animateCurrentStep()
                }
            } else {
                animateCurrentStep()
            }
        case .sent:
            DispatchQueue.main.async {
                [weak self] in
                self?.complete()
            }
        }
    }

    private var checkConnection: Bool {
        let connectionState = ConnectionMonitor.shared.state
        // check internet connection
        switch connectionState.reachability {
        case .offline, .unknown:
            completionStatus = .internetConnectionError
            return false
        default:
            break
        }
        // check for timeout
        let secondsElapsed = Int(Date().timeIntervalSince(connectionCheckStartDate))
        if secondsElapsed > connectionTimeoutSec {
            completionStatus = .networkConnectionTimeout
            return false
        }
        // check tor and base node connection
        switch connectionState.torStatus {
        case .connected:
            if connectionState.torBootstrapProgress == 100 {
                return true
            }
        default:
            break
        }
        return false
    }

    private func hideTitleLabels(_ completion: @escaping () -> Void) {
        UIView.animate(withDuration: 1, animations: { [weak self] in
            guard let self = self else { return }
            self.titleLine1Label.alpha = 0
            self.titleLine2Label.alpha = 0
        }) { _ in
            completion()
        }
    }

    private func displayCurrentStep(completion: @escaping () -> Void) {
        switch currentStep {
        case .connectionCheck:
            // display progress bars
            UIView.animate(
                withDuration: 0.5,
                animations: {
                    [weak self] in
                    self?.progressBar1View.alpha = 1
                    self?.progressBar2View.alpha = 1
                    self?.progressBar3View.alpha = 1
                }
            )
        default:
            break
        }

        titleLine1Label.text = currentStep.titleLines.0
        titleLine2Label.text = currentStep.titleLines.1
        runTitleLabelRevealAnimation(
            label: titleLine1Label,
            container: titleLine1ContainerView,
            topConstraint: titleLine1LabelTopConstraint
        ) {

        }
        runTitleLabelRevealAnimation(
            label: titleLine2Label,
            container: titleLine2ContainerView,
            topConstraint: titleLine2LabelTopConstraint,
            delay: 0.1
        ) {
            completion()
        }
    }

    private func runTitleLabelRevealAnimation(
        label: UILabel,
        container: UIView,
        topConstraint: NSLayoutConstraint,
        delay: TimeInterval = 0,
        completion: @escaping (() -> Void)
    ) {
        view.layoutIfNeeded()
        topConstraint.constant = label.frame.height
        view.layoutIfNeeded()
        label.alpha = 1
        topConstraint.constant = 0
        UIView.animate(
            withDuration: 0.5,
            delay: delay,
            options: [],
            animations: {
                [weak self] in
                self?.view.layoutIfNeeded()
            }
        ) { _ in
            completion()
        }
    }

    private func animateCurrentStep() {
        if currentProgressBarWidthConstraint.constant == progressBarWidth {
            currentProgressBarWidthConstraint.constant = 0
        } else {
            currentProgressBarWidthConstraint.constant = progressBarWidth
        }
        currentStepAnimRepeatCount += 1
        UIView.animate(
            withDuration: 0.85,
            delay: 0.1,
            options: [],
            animations: {
                [weak self] in
                self?.view.layoutIfNeeded()
            }
        ) {
            [weak self] _ in
            guard let self = self else { return }
            if self.currentStepAnimRepeatCount >= 3
                && self.currentStepAnimRepeatCount % 2 == 1 {
                self.proceedToNextStep()
            } else {
                self.animateCurrentStep()
            }
        }
    }

    private func sendTransaction() {
        let wallet = TariLib.shared.tariWallet!
        do {
            txId = try wallet.sendTransaction(
                destination: recipientPubKey,
                amount: amount,
                fee: wallet.calculateTransactionFee(amount),
                message: note
            )
            startListeningForWalletEvents()
        } catch {
            completionStatus = .sendError(error: error)
        }
    }

    //Start listening for when store and forward completes so we know when to finish this send animation
    private func startListeningForWalletEvents() {
        TariLogger.info("Waiting for wallet events.")
        TariEventBus.onMainThread(self, eventType: .directSend) {
            [weak self]
            (result) in
            guard let self = self else { return }
            guard let txResult = result?.object as? CallbackTxResult,
                txResult.id == self.txId else {
                return
            }

            if txResult.success {
                TariLogger.info("Direct send successful.")
                self.sendPushNotificationToRecipient()
                Tracker.shared.track(
                    eventWithCategory: "Transaction",
                    action: "Transaction Accepted - Synchronous"
                )
                TariEventBus.unregister(self)
                // direct send successful
                self.completionStatus = .directSendSuccessful
            } else {
                self.directSendHasFailed = true
                self.checkForCombinedFailure()
            }
        }
        TariEventBus.onMainThread(self, eventType: .storeAndForwardSend) {
            [weak self]
            (result) in
            guard let self = self else { return }
            guard let txResult = result?.object as? CallbackTxResult,
                txResult.id == self.txId else {
                return
            }

            if txResult.success {
                TariLogger.info("Store and forward send successful.")
                self.sendPushNotificationToRecipient()
                Tracker.shared.track(
                    eventWithCategory: "Transaction",
                    action: "Transaction Stored"
                )
                TariEventBus.unregister(self)
                // store and forward send successful
                self.completionStatus = .storeAndForwardSendSuccessful
            } else {
                self.storeAndForwardSendHasFailed = true
                self.checkForCombinedFailure()
            }
        }
    }

    private func sendPushNotificationToRecipient() {
        if let toPublicKey = recipientPubKey {
            do {
                try NotificationManager.shared.sendToRecipient(toPublicKey, onSuccess: {
                    TariLogger.info("Recipient has been notified")
                }) { (error) in
                    TariLogger.error("Failed to notify recipient", error: error)
                }
            } catch {
                TariLogger.error("Failed to notify recipient", error: error)
            }
        }
    }

    private func checkForCombinedFailure() {
        if directSendHasFailed && storeAndForwardSendHasFailed {
            TariEventBus.unregister(self)
            // failure
            completionStatus = .sendError(error: nil)
        }
    }

    // Failed - display error and return to home.
    private func fail() {
        // rollback Lottie animation
        animationView.play(
            fromProgress: pauseLottieAnimationAt,
            toProgress: 0,
            loopMode: .playOnce
        )
        // fade out title views and progress bars
        UIView.animate(
            withDuration: 1.0,
            delay: 0,
            options: [],
            animations: {
                [weak self] in
                self?.titleLine1Label.alpha = 0
                self?.titleLine2Label.alpha = 0
                self?.progressBar1View.alpha = 0
                self?.progressBar2View.alpha = 0
                self?.progressBar3View.alpha = 0
            }
        ) {
            [weak self] _ in
            // display error
            self?.displayErrorFeedbackAndTrackEvent()
            // return to home
            self?.navigationController?.popToRootViewController(animated: false)
        }
    }

    private func displayErrorFeedbackAndTrackEvent() {
        guard let completionStatus = completionStatus else { return }
        switch completionStatus {
        case .internetConnectionError:
            UserFeedback.shared.error(
                title: NSLocalizedString(
                    "sending_tari.error.interwebs_connection.title",
                    comment: "SendingTari view"
                ),
                description: NSLocalizedString(
                    "sending_tari.error.interwebs_connection.description",
                    comment: "SendingTari view"
                )
            )
            Tracker.shared.track(
                eventWithCategory: "Transaction",
                action: "Transaction Failed - Tor Issue"
            )
        case .networkConnectionTimeout, .sendError:
            UserFeedback.shared.error(
                title: NSLocalizedString(
                    "sending_tari.error.no_connection.title",
                    comment: "SendingTari view"
                ),
                description: NSLocalizedString(
                    "sending_tari.error.no_connection.description",
                    comment: "SendingTari view"
                )
            )
            Tracker.shared.track(
                eventWithCategory: "Transaction",
                action: "Transaction Failed - Node Issue"
            )
        default:
            break
        }
    }

    // Finished successfully - return to home.
    private func complete() {
        // animate Lottie to completion
        animationView.play(
            fromProgress: pauseLottieAnimationAt,
            toProgress: 1,
            loopMode: .playOnce
        )
        // fade out title views and progress bars
        UIView.animate(
            withDuration: 1,
            delay: 3.7,
            options: [],
            animations: {
                [weak self] in
                self?.titleLine1Label.alpha = 0
                self?.titleLine2Label.alpha = 0
                self?.progressBar1View.alpha = 0
                self?.progressBar2View.alpha = 0
                self?.progressBar3View.alpha = 0
            }
        ) {
            [weak self] _ in
            // return to home
            self?.navigationController?.dismiss(animated: true, completion: {
                UIApplication.shared.menuTabBarController()?.setTab(.home)
            })
        }
    }

}
