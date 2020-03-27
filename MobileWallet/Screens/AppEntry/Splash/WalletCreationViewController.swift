//  WalletCreationViewController.swift

/*
	Package MobileWallet
	Created by Gabriel Lupu on 29/01/2020
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
import Lottie
import LocalAuthentication
import AVFoundation

enum WalletCreationState {
    case createEmojiId
    case showEmojiId
    case localAuthentification
    case enableNotifications
}

class WalletCreationViewController: UIViewController {
    // MARK: - Variables and constants
    var state: WalletCreationState = .createEmojiId
    var player: AVQueuePlayer!
    var playerLayer: AVPlayerLayer!
    var playerItem: AVPlayerItem!
    var playerLooper: AVPlayerLooper!

    // MARK: - Outlets
    var createEmojiButtonConstraint: NSLayoutConstraint?
    var createEmojiButtonSecondConstraint: NSLayoutConstraint?
    var firstLabelTopConstraint: NSLayoutConstraint?
    var secondLabelTopConstaint: NSLayoutConstraint?
    var secondLabelBottomConstaint: NSLayoutConstraint?
    var thirdLabelLeadingConstaint: NSLayoutConstraint?
    var thirdLabelTrailingConstaint: NSLayoutConstraint?
    var faceIdWidthConstaint: NSLayoutConstraint?
    var faceIdHeightConstaint: NSLayoutConstraint?
    var faceIdDistanceToLabel: NSLayoutConstraint?
    var firstLabel: UILabel!
    var secondLabelTop: UILabel!
    var secondLabelBottom: UILabel!
    var thirdLabel: UILabel!
    var topWhiteView: UIView!
    var bottomWhiteView: UIView!
    var animationView: AnimationView!
    var emojiWheelView: AnimationView!
    var nerdAnimationView: AnimationView!
    var videoView: UIView!
    var createEmojiButton: ActionButton!
    var userEmojiContainer: EmoticonView!
    var faceIDView: AnimationView!

    // MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        firstLabelAnimation()
        setupVideoAnimation()
    }

    // MARK: - Private functions

    private func updateConstraintsTopWhiteView() {
        topWhiteView = UIView()
        topWhiteView.backgroundColor = Theme.shared.colors.creatingWalletBackground
        view.addSubview(topWhiteView)
        topWhiteView.translatesAutoresizingMaskIntoConstraints = false
        topWhiteView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: 0).isActive = true
        topWhiteView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: 0).isActive = true
        topWhiteView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                          constant: 0).isActive = true
    }

    private func updateConstraintsNerdAnimationView() {
        nerdAnimationView = AnimationView()
        view.addSubview(nerdAnimationView)
        nerdAnimationView.translatesAutoresizingMaskIntoConstraints = false
        nerdAnimationView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        nerdAnimationView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        nerdAnimationView.heightAnchor.constraint(equalToConstant: 80).isActive = true
    }

    private func updateConstraintsVideoView() {
        videoView = UIView()
        view.addSubview(videoView)
        videoView.translatesAutoresizingMaskIntoConstraints = false
        videoView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        videoView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        videoView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        videoView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
    }

    private func updateConstraintsFirstLabel() {
        firstLabel = UILabel()
        firstLabel.numberOfLines = 1
        firstLabel.textAlignment = .center
        view.addSubview(firstLabel)
        firstLabel.translatesAutoresizingMaskIntoConstraints = false
        firstLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
    }

    private func updateConstraintsSecondLabelTop() {
        secondLabelTop = UILabel()
        secondLabelTop.numberOfLines = 1
        secondLabelTop.alpha = 1.0
        secondLabelTop.textAlignment = .center
        view.addSubview(secondLabelTop)
        secondLabelTop.translatesAutoresizingMaskIntoConstraints = false
        secondLabelTop.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        secondLabelTop.heightAnchor.constraint(equalTo: firstLabel.heightAnchor, multiplier: 1).isActive = true
        secondLabelTop.topAnchor.constraint(equalTo: nerdAnimationView.bottomAnchor, constant: 0).isActive = true
    }

    private func updateConstraintsSecondLabelBottom() {
        secondLabelBottom = UILabel()
        secondLabelBottom.numberOfLines = 0
        secondLabelBottom.alpha = 1.0
        secondLabelBottom.textAlignment = .center
        view.addSubview(secondLabelBottom)
        secondLabelBottom.translatesAutoresizingMaskIntoConstraints = false
        secondLabelBottom.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
    }

    private func updateConstraintsAnimationView() {
        animationView = AnimationView()
        view.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        animationView.widthAnchor.constraint(equalToConstant: 43.75).isActive = true
        animationView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        animationView.topAnchor.constraint(equalTo: bottomWhiteView.topAnchor, constant: -50).isActive = true
    }

    private func updateConstraintsBottomWhiteView() {
        bottomWhiteView = UIView()
        view.addSubview(bottomWhiteView)
        bottomWhiteView.backgroundColor = Theme.shared.colors.creatingWalletBackground
        bottomWhiteView.translatesAutoresizingMaskIntoConstraints = false
        bottomWhiteView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: 0).isActive = true
        bottomWhiteView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: 0).isActive = true
        bottomWhiteView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                          constant: -52).isActive = true
        bottomWhiteView.topAnchor.constraint(equalTo: topWhiteView.bottomAnchor, constant: 0).isActive = true
        firstLabelTopConstraint = firstLabel.topAnchor.constraint(equalTo: bottomWhiteView.topAnchor, constant: 8)
        firstLabelTopConstraint?.isActive = true
        secondLabelTopConstaint = secondLabelTop.topAnchor.constraint(equalTo: bottomWhiteView.topAnchor, constant: 8)
        secondLabelTopConstaint?.isActive = true
        secondLabelBottomConstaint = secondLabelBottom.topAnchor.constraint(equalTo: bottomWhiteView.topAnchor, constant: 8)
        secondLabelBottomConstaint?.isActive = true

        bottomWhiteView.heightAnchor.constraint(equalTo: topWhiteView.heightAnchor, multiplier: 0.705).isActive = true
    }

    func updateConstraintsThirdLabel() {
        thirdLabel = UILabel()
        thirdLabel.numberOfLines = 0
        thirdLabel.alpha = 0.0
        thirdLabel.textAlignment = .center
        view.addSubview(thirdLabel)
        thirdLabel.translatesAutoresizingMaskIntoConstraints = false
        thirdLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor,
                                            constant: 0).isActive = true
        thirdLabelLeadingConstaint = thirdLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: 10)
        thirdLabelLeadingConstaint?.isActive = true
        thirdLabelTrailingConstaint = thirdLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: -10)
        thirdLabelTrailingConstaint?.isActive = true
        thirdLabel.topAnchor.constraint(equalTo: secondLabelBottom.bottomAnchor, constant: 18).isActive = true
    }

    private func updateConstraintsEmojiButton() {
        createEmojiButton = ActionButton()
        createEmojiButton.addTarget(self, action: #selector(onNavigateNext), for: .touchUpInside)
        createEmojiButton.alpha = 0.0
        view.addSubview(createEmojiButton)
        createEmojiButton.translatesAutoresizingMaskIntoConstraints = false
        createEmojiButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: Theme.shared.sizes.appSidePadding).isActive = true
        createEmojiButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: -Theme.shared.sizes.appSidePadding).isActive = true
        createEmojiButton.centerXAnchor.constraint(equalTo: view.centerXAnchor,
        constant: 0).isActive = true
        createEmojiButtonConstraint = createEmojiButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 70)
        createEmojiButtonConstraint?.isActive = true
        createEmojiButtonConstraint?.priority = UILayoutPriority(rawValue: 999)

        createEmojiButtonSecondConstraint = view.bottomAnchor.constraint(greaterThanOrEqualTo: createEmojiButton.bottomAnchor, constant: 20)
        createEmojiButtonSecondConstraint?.priority = UILayoutPriority(rawValue: 1000)
        createEmojiButtonSecondConstraint?.isActive = false

    }

    private func updateConstraintsEmojiWheelView() {
        emojiWheelView = AnimationView()
        view.addSubview(emojiWheelView)
        emojiWheelView.translatesAutoresizingMaskIntoConstraints = false
        emojiWheelView.centerXAnchor.constraint(equalTo: view.centerXAnchor,
        constant: 0).isActive = true
        emojiWheelView.centerYAnchor.constraint(equalTo: view.centerYAnchor,
        constant: 0).isActive = true
        emojiWheelView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: 0).isActive = true
        emojiWheelView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: 0).isActive = true
        emojiWheelView.widthAnchor.constraint(equalTo: emojiWheelView.heightAnchor, multiplier: 1.0/1.0).isActive = true

    }

    private func updateConstraintsFaceIDView() {
        faceIDView = AnimationView()
        view.addSubview(faceIDView)
        faceIDView.translatesAutoresizingMaskIntoConstraints = false
        faceIDView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        faceIdWidthConstaint = faceIDView.widthAnchor.constraint(equalToConstant: 238)
        faceIdWidthConstaint?.isActive = true
        faceIdHeightConstaint = faceIDView.heightAnchor.constraint(equalToConstant: 238)
        faceIdHeightConstaint?.isActive = true
        faceIdDistanceToLabel = secondLabelBottom.topAnchor.constraint(equalTo: faceIDView.bottomAnchor, constant: -30)
        faceIdDistanceToLabel?.isActive = true
    }

    private func updateConstraintsUserEmojiContainer() {
        userEmojiContainer = EmoticonView()
        userEmojiContainer.alpha = 0.0
        view.addSubview(userEmojiContainer)
        userEmojiContainer.translatesAutoresizingMaskIntoConstraints = false
        userEmojiContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: Theme.shared.sizes.appSidePadding).isActive = true
        userEmojiContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: -Theme.shared.sizes.appSidePadding).isActive = true
        secondLabelTop.topAnchor.constraint(equalTo: userEmojiContainer.bottomAnchor, constant: 20).isActive = true
        userEmojiContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
    }

    func setupVideoAnimation() {
        if let path = Bundle.main.path(forResource: "loader", ofType: "mp4") {
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
            playerLayer.shouldRasterize = true
            playerLayer.rasterizationScale = UIScreen.main.scale
            player.play()
            videoView.layer.insertSublayer(playerLayer, at: 0)
            videoView.clipsToBounds = true
        }
    }

    private func setupView() {
        updateConstraintsTopWhiteView()
        updateConstraintsNerdAnimationView()
        updateConstraintsFirstLabel()
        updateConstraintsSecondLabelTop()
        updateConstraintsSecondLabelBottom()
        updateConstraintsBottomWhiteView()
        updateConstraintsAnimationView()
        updateConstraintsThirdLabel()
        updateConstraintsEmojiButton()
        updateConstraintsEmojiWheelView()
        updateConstraintsFaceIDView()
        updateConstraintsUserEmojiContainer()
        updateConstraintsVideoView()

        firstLabel.text = NSLocalizedString("Hello, Friend", comment: "First label on wallet creation")
        firstLabel.font = Theme.shared.fonts.createWalletFirstLabel
        firstLabel.textColor = Theme.shared.colors.creatingWalletFirstLabel

        thirdLabel.text = NSLocalizedString("Your Emoji ID is your wallet address.\n It’s how your friends can find you and send you Tari.", comment: "Third label on wallet creation")
        thirdLabel.font = Theme.shared.fonts.createWalletThirdLabel
        thirdLabel.textColor = Theme.shared.colors.creatingWalletThirdLabel

        secondLabelTop.text = NSLocalizedString("Hold on a sec…", comment: "Second label on wallet creation Top")
        secondLabelTop.font = Theme.shared.fonts.createWalletSecondLabelFirstText
        secondLabelTop.textColor = Theme.shared.colors.creatingWalletSecondLabel

        secondLabelBottom.text = NSLocalizedString("We’re creating your wallet.", comment: "Second label on wallet creation Bottom")
        secondLabelBottom.font = Theme.shared.fonts.createWalletSecondLabelSecondText
        secondLabelBottom.textColor = Theme.shared.colors.creatingWalletSecondLabel

        createEmojiButton.setTitle(NSLocalizedString("Create Your Emoji ID", comment: "Create button on wallet creation"), for: .normal)

        self.view.backgroundColor = Theme.shared.colors.creatingWalletBackground
    }

    private func firstLabelAnimation() {
        firstLabelTopConstraint?.constant = -50.0

        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let self = self else { return }
            self.view.layoutIfNeeded()
        }) { (_) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self = self else { return }
                self.removeFirstLabelAnimation()
            }
        }
    }

    private func removeFirstLabelAnimation() {
        UIView.animate(withDuration: 2, animations: { [weak self] in
            guard let self = self else { return }
            self.firstLabel.alpha = 0.0
            self.view.layoutIfNeeded()
        }) { [weak self] (_) in
            guard let self = self else { return }
            self.displaySecondLabelAnimation()
        }
    }

    private func displaySecondLabelAnimation() {
        secondLabelTopConstaint?.constant = -50
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let self = self else { return }
            self.view.layoutIfNeeded()
        }) { [weak self] (_) in
            guard let self = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self = self else { return }
                self.removeSecondLabelAnimation()
            }
        }

        secondLabelBottomConstaint?.constant = -25
        UIView.animate(withDuration: 0.75, animations: { [weak self] in
            guard let self = self else { return }
            self.view.layoutIfNeeded()
        })
    }

    private func removeSecondLabelAnimation() {
        UIView.animate(withDuration: 1, animations: { [weak self] in
            guard let self = self else { return }
            self.secondLabelTop.alpha = 0.0
            self.secondLabelBottom.alpha = 0.0
            self.view.layoutIfNeeded()
        }) { [weak self] (_) in
            guard let self = self else { return }

            self.secondLabelTopConstaint?.constant = 8
            self.secondLabelBottomConstaint?.constant = 8
            self.secondLabelTop.text = NSLocalizedString("We’re off to a great start!", comment: "Second label on wallet creation Top")
            self.secondLabelBottom.text = NSLocalizedString("Now, let’s create your Emoji ID.", comment: "Second label on wallet creation Bottom")

            DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
                guard let self = self else { return }
                self.runCheckMarkAnimation()
                UIView.animate(withDuration: 0.5, animations: { [weak self] in
                    guard let self = self else { return }
                    self.videoView.alpha = 0.0
                    self.view.layoutIfNeeded()
                })
            }
        }
    }

    private func runCheckMarkAnimation() {
        loadCheckMarkAnimation()
        startCheckMarkAnimation()
    }

    private func loadCheckMarkAnimation() {
        let animation = Animation.named("CheckMark")
        animationView.animation = animation
    }

    private func startCheckMarkAnimation() {
        animationView.play(
            fromProgress: 0,
            toProgress: 1,
            loopMode: .playOnce,
            completion: { [weak self] (_) in
                guard let self = self else { return }
                self.showCreateYourEmojiIdScreen()
            }
        )
    }

    private func runFaceIDAnimation() {
        loadFaceIDAnimation()
        startFaceIDAnimation()
    }

    private func loadFaceIDAnimation() {
        let animation = Animation.named("FaceID")
        faceIDView.animation = animation
    }

    private func startFaceIDAnimation() {
        faceIDView.play(
            fromProgress: 0,
            toProgress: 1,
            loopMode: .playOnce,
            completion: nil)
    }

    private func runTouchIdAnimation() {
        loadTouchIdAnimation()
        startTouchIdAnimation()
    }

    private func loadTouchIdAnimation() {
        let animation = Animation.named("TouchIdAnimation")
        faceIDView.animation = animation
    }

    private func startTouchIdAnimation() {
        faceIDView.play(
            fromProgress: 0,
            toProgress: 1,
            loopMode: .playOnce,
            completion: nil)
    }

    private func runNotificationAnimation() {
        loadNotificationAnimation()
        startNotificationAnimation()
    }

    private func loadNotificationAnimation() {
        let animation = Animation.named("NotificationAnimation")
        faceIDView.animation = animation
    }

    private func startNotificationAnimation() {
        faceIDView.play(
            fromProgress: 0,
            toProgress: 1,
            loopMode: .playOnce,
            completion: nil)
    }

    private func runEmojiWheelAnimation() {
        loadEmojiWheelAnimation()
        startEmojiWheelAnimation()
    }

    private func startEmojiWheelAnimation() {
        emojiWheelView.play(
            fromProgress: 0,
            toProgress: 1,
            loopMode: .playOnce,
            completion: { [weak self] (_) in
                guard let self = self else { return }
                self.showYourEmoji()
            }
        )
    }

    private func loadEmojiWheelAnimation() {
        let animation = Animation.named("EmojiWheel")
        emojiWheelView.animation = animation
    }

    private func runNerdEmojiAnimation() {
        loadNerdEmojiAnimation()
        startNerdEmojiAnimation()
    }

    private func loadNerdEmojiAnimation() {
        let animation = Animation.named("NerdEmojiAnimation")
        nerdAnimationView.animation = animation
    }

    private func startNerdEmojiAnimation() {
        nerdAnimationView.play(
            fromProgress: 0,
            toProgress: 1,
            loopMode: .playOnce,
            completion: { (_) in
            }
        )
    }

    private func showCreateYourEmojiIdScreen() {
        self.secondLabelTop.alpha = 1.0
        self.secondLabelBottom.alpha = 1.0
        createEmojiButtonConstraint?.constant = 0
        createEmojiButtonSecondConstraint?.isActive = true
        runNerdEmojiAnimation()
        secondLabelTopConstaint?.constant = -50

        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let self = self else { return }
            self.view.layoutIfNeeded()
        })

        secondLabelBottomConstaint?.constant = -25
        UIView.animate(withDuration: 0.75, animations: { [weak self] in
            guard let self = self else { return }
            self.view.layoutIfNeeded()
        })

        UIView.animate(withDuration: 1, animations: { [weak self] in
            guard let self = self else { return }
            self.thirdLabel.alpha = 1.0
            self.createEmojiButton.alpha = 1.0
            self.view.layoutIfNeeded()
        })
    }

    private func showYourEmoji() {
        createEmojiButtonConstraint?.constant = 0
        createEmojiButtonSecondConstraint?.isActive = true
        createEmojiButton.animateIn()
        secondLabelTopConstaint?.constant = -50

        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let self = self else { return }
            self.view.layoutIfNeeded()
        })

        secondLabelBottomConstaint?.constant = -25
        UIView.animate(withDuration: 0.75, animations: { [weak self] in
            guard let self = self else { return }
            self.view.layoutIfNeeded()
        })

        UIView.animate(withDuration: 1, animations: { [weak self] in
            guard let self = self else { return }
            self.secondLabelBottom.alpha = 1.0
            self.thirdLabel.alpha = 1.0
            self.userEmojiContainer.alpha = 1.0
            self.createEmojiButton.alpha = 1.0
            self.view.layoutIfNeeded()
        }) { [weak self] (_) in
            guard let self = self else { return }
            self.state = .showEmojiId
        }
    }

    private func showLocalAuthentification() {
        createEmojiButton.animateIn()

        let currentType = LAContext().biometricType
        switch currentType {
            case .faceID:
                runFaceIDAnimation()
            case .touchID:
                runTouchIdAnimation()
            case .none:
                //TODO secure with pin
                TariLogger.error("No biometrics available")
        }

        secondLabelTopConstaint?.constant = -50
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let self = self else { return }
            self.view.layoutIfNeeded()
        })

        secondLabelBottomConstaint?.constant = -25
        UIView.animate(withDuration: 0.75, animations: { [weak self] in
            guard let self = self else { return }
            self.view.layoutIfNeeded()
        })

        UIView.animate(withDuration: 1, animations: { [weak self] in
            guard let self = self else { return }
            self.secondLabelBottom.alpha = 1.0
            self.thirdLabel.alpha = 1.0
            self.createEmojiButton.alpha = 1.0
            self.view.layoutIfNeeded()
        }) { [weak self] (_) in
            guard let self = self else { return }
            self.state = .localAuthentification
        }
    }

    private func hideLocalAuthentification() {
        createEmojiButton.hideButtonWithAlpha()
        UIView.animate(withDuration: 1, animations: { [weak self] in
            guard let self = self else { return }
            self.secondLabelTop.alpha = 0.0
            self.secondLabelBottom.alpha = 0.0
            self.thirdLabel.alpha = 0.0
            self.faceIDView.alpha = 0.0
            self.view.layoutIfNeeded()
        }) { [weak self] (_) in
            guard let self = self else { return }
            self.state = .localAuthentification
            DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
                guard let self = self else { return }
                self.updateLabelsForEnablingNotifications()
                self.faceIDView.stop()
                self.showEnableNotifications()
            }
        }
    }

    private func showEnableNotifications() {
        createEmojiButton.animateIn()
        runNotificationAnimation()
        secondLabelTopConstaint?.constant = -50
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            guard let self = self else { return }
            self.view.layoutIfNeeded()
        })

        secondLabelBottomConstaint?.constant = -25
        UIView.animate(withDuration: 0.75, animations: { [weak self] in
            guard let self = self else { return }
            self.view.layoutIfNeeded()
        })

        UIView.animate(withDuration: 1, animations: { [weak self] in
            guard let self = self else { return }
            self.secondLabelTop.alpha = 1.0
            self.secondLabelBottom.alpha = 1.0
            self.thirdLabel.alpha = 1.0
            self.createEmojiButton.alpha = 1.0
            self.faceIDView.alpha = 1.0
            self.view.layoutIfNeeded()
        }) { [weak self] (_) in
            guard let self = self else { return }
            self.state = .enableNotifications
        }
    }

    private func updateLabelsForEnablingNotifications() {
        let secondLabelStringTop = NSLocalizedString("Don’t miss out when people", comment: "Splash EnableNotifications")
        let secondLabelStringBottom = NSLocalizedString("send you money.", comment: "Splash EnableNotifications")
        self.secondLabelTop.font = Theme.shared.fonts.createWalletNotificationsFirstLabel
        self.secondLabelBottom.font = Theme.shared.fonts.createWalletNotificationsSecondLabel
        self.secondLabelTop.text = secondLabelStringTop
        self.secondLabelBottom.text = secondLabelStringBottom
        self.thirdLabel.font = Theme.shared.fonts.createWalletNotificationsThirdLabel
        self.thirdLabel.text = NSLocalizedString("Enable push notifications to keep tabs on your payments.", comment: "Create Wallet enable Notifications screen")

        self.createEmojiButton.setTitle(NSLocalizedString("Turn on Notifications", comment: "Create Wallet Turn on Notifications"), for: .normal)

        secondLabelTopConstaint?.constant = 8
        secondLabelBottomConstaint?.constant = 8
        faceIdWidthConstaint?.constant = 330
        faceIdHeightConstaint?.constant = 362
        faceIdDistanceToLabel?.constant = -90
        faceIDView.layoutIfNeeded()
        secondLabelTop.layoutIfNeeded()
        secondLabelBottom.layoutIfNeeded()
    }

    private func updateLabelsForShowEmojiId() {
        let secondLabelString = NSLocalizedString("This is your Emoji ID", comment: "Splash show your emoji ID")
        let attributedString = NSMutableAttributedString(string: secondLabelString, attributes: [
            .font: Theme.shared.fonts.createWalletEmojiIDFirstText!,
          .foregroundColor: Theme.shared.colors.creatingWalletSecondLabel!,
          .kern: -0.33
        ])
        attributedString.addAttribute(.font, value: Theme.shared.fonts.createWalletEmojiIDSecondText!, range: NSRange(location: 13, length: 8))

        self.secondLabelBottom.attributedText = attributedString
        self.thirdLabel.text = NSLocalizedString("Your Emoji ID is your wallet’s address, and how others can find you and send you Tari.", comment: "Emoji Id third label on wallet creation")

        self.createEmojiButton.setTitle(NSLocalizedString("Continue", comment: "This is your emoji screen on wallet creation"), for: .normal)

        if let pubKey = TariLib.shared.tariWallet?.publicKey.0 {
            let (emojis, _) = pubKey.emojis
            self.userEmojiContainer.setUpView(emojiText: emojis,
                                              type: .normalView,
                                              textCentered: true,
                                              inViewController: self)
        }

        secondLabelTopConstaint?.constant = 8
        secondLabelBottomConstaint?.constant = 8
        secondLabelTop.layoutIfNeeded()
        secondLabelBottom.layoutIfNeeded()
    }

    private func updateLabelsForLocalAuthentification() {
        secondLabelTopConstaint?.constant = 8
        secondLabelBottomConstaint?.constant = 8
        secondLabelTop.layoutIfNeeded()
        secondLabelBottom.layoutIfNeeded()

        thirdLabelLeadingConstaint?.constant = Theme.shared.sizes.appSidePadding
        thirdLabelTrailingConstaint?.constant = -Theme.shared.sizes.appSidePadding
        thirdLabel.layoutIfNeeded()

        let secondLabelString = NSLocalizedString("🔑 Let’s secure your wallet. 🔑", comment: "Splash face/touch ID")
        let attributedString = NSMutableAttributedString(string: secondLabelString, attributes: [
          .font: Theme.shared.fonts.createWalletEmojiIDSecondText!,
          .foregroundColor: Theme.shared.colors.creatingWalletSecondLabel!,
          .kern: -0.33
        ])
        //attributedString.addAttribute(.font, value: Theme.shared.fonts.createWalletEmojiIDSecondText!, range: NSRange(location: 25, length: 7))
        self.secondLabelBottom.attributedText = attributedString

        self.thirdLabel.text = NSLocalizedString("Sleep well at night knowing you’ve taken precautions to keep your Tari wallet safe and sound.",
        comment: "Face ID third label on wallet creation")

        let currentType = LAContext().biometricType
        switch currentType {
        case .faceID:
            self.createEmojiButton.setTitle(NSLocalizedString("Secure with Face ID", comment: "Enable authentication on wallet creation"), for: .normal)
        case .touchID:
            self.createEmojiButton.setTitle(NSLocalizedString("Secure with Touch ID", comment: "Enable authentication on wallet creation"), for: .normal)
        case .none:
            self.createEmojiButton.setTitle(NSLocalizedString("Secure with Pin", comment: "Enable authentication on wallet creation"), for: .normal)
        }
    }

    // MARK: - Actions
    @objc func onNavigateNext() {
        switch state {
        case .createEmojiId:
            self.createEmojiButton.hideButtonWithAlpha()
            UIView.animate(withDuration: 1, animations: {
                self.secondLabelTop.alpha = 0.0
                self.secondLabelBottom.alpha = 0.0
                self.thirdLabel.alpha = 0.0
                self.nerdAnimationView.alpha = 0.0
                self.createEmojiButton.alpha = 0.0
                self.view.layoutIfNeeded()
            }) { [weak self] (_) in
                guard let self = self else { return }
                self.runEmojiWheelAnimation()
                self.updateLabelsForShowEmojiId()
                Tracker.shared.track("/onboarding/create_emoji_id", "Onboarding - Create Emoji Id")
            }
        case .showEmojiId:
            self.createEmojiButton.hideButtonWithAlpha()
            UIView.animate(withDuration: 1, animations: {
                self.secondLabelTop.alpha = 0.0
                self.secondLabelBottom.alpha = 0.0
                self.thirdLabel.alpha = 0.0
                self.userEmojiContainer.alpha = 0.0
                self.view.layoutIfNeeded()
            }) { [weak self] (_) in
                guard let self = self else { return }
                self.updateLabelsForLocalAuthentification()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    guard let self = self else { return }
                    self.showLocalAuthentification()
                }
            }
        case .localAuthentification:
            let context = LAContext()
            var error: NSError?

            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                         error: &error) {
                let reason = secondLabelTop.text ?? ""

                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                    [weak self] success, _ in

                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        if success {
                            self.hideLocalAuthentification()

                            Tracker.shared.track("/onboarding/enable_local_auth", "Onboarding - Enable Local Authentication")
                        } else {
                            let alert = UIAlertController(title: "There was an error",
                                                          message: "",
                                                          preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Try again",
                                                          style: .default,
                                                          handler: nil))

                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            } else {
                let alert = UIAlertController(title: "There is no biometry",
                                              message: "",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok",
                                              style: .default,
                                              handler: nil))

                self.present(alert, animated: true, completion: nil)
            }
        case .enableNotifications:
            NotificationManager.shared.requestAuthorization {_ in
                DispatchQueue.main.async {
                    Tracker.shared.track("/onboarding/enable_push_notif", "Onboarding - Enable Push Notifications")

                    let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                    if let nav = storyboard.instantiateInitialViewController() as? UINavigationController {
                        nav.modalPresentationStyle = .overFullScreen
                        self.present(nav, animated: true, completion: nil)
                    }

                    //Below code isn't being used, there's an issue with it:
                    //https://github.com/tari-project/wallet-ios/issues/186
//                    let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
//                    if let nav = storyboard.instantiateInitialViewController() as? UINavigationController {
//                        if let window = UIApplication.shared.windows.first {
//                            let overlayView = UIScreen.main.snapshotView(afterScreenUpdates: false)
//                            if let vc = nav.viewControllers.first {
//                                vc.view.addSubview(overlayView)
//                                window.rootViewController = nav
//                                UIView.animate(withDuration: 0.4, delay: 0, options: .transitionCrossDissolve, animations: {
//                                    overlayView.alpha = 0
//                                }, completion: { _ in
//                                    overlayView.removeFromSuperview()
//                                })
//                            }
//                        }
//                    }
                }
            }
        }
    }
}
