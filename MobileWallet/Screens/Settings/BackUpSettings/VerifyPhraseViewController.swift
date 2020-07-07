//  VerifyPhraseViewController.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 02.06.2020
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

class VerifyPhraseViewController: SettingsParentViewController {
    private let stackView = UIStackView()

    private let continueButton = ActionButton()
    private let headerLabel = UILabel()
    private var selectablePhraseView: WordsFlexView!

    private let fillablePhraseContainer = UIView()
    private var fillablePhraseView: WordsFlexView!
    private let fillableContainerDescription = UILabel()

    private let warningView = UIView()
    private let successView = UIImageView()

    private var success: Bool = false {
        didSet {
            let isFillableContainerFull = selectablePhraseView.words.count == fillablePhraseView.words.count

            warningView.isHidden = !isFillableContainerFull || success
            successView.isHidden = !isFillableContainerFull || !success

            showResultWithAnimation()

            continueButton.variation = success ? .normal : .disabled
        }
    }
}

extension VerifyPhraseViewController {
    override func setupViews() {
        super.setupViews()
        setupContinueButton()
        setupScrollView()
        setupHeaderLabel()
        setupFillableView()
        setupSelectableView()
        setupWarningView()
        setupSuccessView()
    }

    override func setupNavigationBar() {
        super.setupNavigationBar()
        navigationBar.title = NSLocalizedString("verify_phrase.title", comment: "VerifyPhrase view")
    }

    private func setupScrollView() {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false

        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: continueButton.topAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        stackView.axis = .vertical
        stackView.distribution = .fill

        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20).isActive = true
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25).isActive = true
    }

    private func setupHeaderLabel() {
        headerLabel.font = Theme.shared.fonts.settingsSeedPhraseDescription
        headerLabel.textColor = Theme.shared.colors.settingsViewDescription
        headerLabel.text = NSLocalizedString("verify_phrase.header", comment: "VerifyPhrase view")

        stackView.addArrangedSubview(headerLabel)
        stackView.setCustomSpacing(20, after: headerLabel)
    }

    private func setupFillableView() {
        fillablePhraseContainer.backgroundColor = Theme.shared.colors.settingsVerificationPhraseViewBackground
        fillablePhraseContainer.layer.cornerRadius = 10.0
        fillablePhraseContainer.layer.masksToBounds = true

        stackView.addArrangedSubview(fillablePhraseContainer)
        stackView.setCustomSpacing(25, after: fillablePhraseContainer)

        fillablePhraseContainer.translatesAutoresizingMaskIntoConstraints = false
        fillablePhraseContainer.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
        fillablePhraseContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 188).isActive = true

        fillablePhraseView = WordsFlexView(type: .fillable,
                                           minimumHeight: 17.0,
                                           maxCountInRaw: 5,
                                           horizontalSpacing: 20.0,
                                           verticalSpacing: 10,
                                           minimumInsets: UIEdgeInsets(top: 3.0, left: 1.0, bottom: 3.0, right: 1.0),
                                           showBorder: false)

        fillablePhraseView.delegate = self
        fillablePhraseContainer.addSubview(fillablePhraseView!)

        fillablePhraseView.translatesAutoresizingMaskIntoConstraints = false
        fillablePhraseView.topAnchor.constraint(equalTo: fillablePhraseContainer.topAnchor, constant: 20).isActive = true
        fillablePhraseView.leadingAnchor.constraint(equalTo: fillablePhraseContainer.leadingAnchor, constant: 20).isActive = true
        fillablePhraseView.trailingAnchor.constraint(equalTo: fillablePhraseContainer.trailingAnchor, constant: -20).isActive = true
        fillablePhraseView.bottomAnchor.constraint(lessThanOrEqualTo: fillablePhraseContainer.bottomAnchor, constant: -20).isActive = true

        fillableContainerDescription.numberOfLines = 0
        fillableContainerDescription.text = NSLocalizedString("verify_phrase.container_description", comment: "VerifyPhrase view")
        fillableContainerDescription.font = Theme.shared.fonts.settingsFillablePhraseViewDescription
        fillableContainerDescription.textColor = Theme.shared.colors.settingsFillablePhraseViewDescription
        fillableContainerDescription.textAlignment = .center

        fillablePhraseContainer.addSubview(fillableContainerDescription)

        fillableContainerDescription.translatesAutoresizingMaskIntoConstraints = false
        fillableContainerDescription.centerYAnchor.constraint(equalTo: fillablePhraseContainer.centerYAnchor).isActive = true
        fillableContainerDescription.centerXAnchor.constraint(equalTo: fillablePhraseContainer.centerXAnchor).isActive = true
        fillableContainerDescription.leadingAnchor.constraint(greaterThanOrEqualTo: fillablePhraseContainer.leadingAnchor, constant: 20).isActive = true
        fillableContainerDescription.trailingAnchor.constraint(lessThanOrEqualTo: fillablePhraseContainer.trailingAnchor, constant: -20).isActive = true

    }

    private func setupSelectableView() {
        let words = ["Aurora", "Fluffy", "Tari", "Gems", "Digital", "Emojis", "Collect", "Animo", "Aurora", "Fluffy", "Tari", "Gems", "Digital", "Emojis", "Collect", "Animo", "Aurora", "Fluffy", "Tari", "Gems", "Digital", "Emojis", "Collect", "Animo"]

        selectablePhraseView = WordsFlexView(type: .selectable, words: words.shuffled(), width: (view.bounds.width - 50))
        selectablePhraseView?.delegate = self

        stackView.addArrangedSubview(selectablePhraseView)

        selectablePhraseView.translatesAutoresizingMaskIntoConstraints = false
        selectablePhraseView.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
    }

    private func setupWarningView() {
        view.addSubview(warningView)

        warningView.isHidden = true
        warningView.translatesAutoresizingMaskIntoConstraints = false
        warningView.topAnchor.constraint(equalTo: selectablePhraseView.topAnchor).isActive = true
        warningView.widthAnchor.constraint(equalTo: fillablePhraseContainer.widthAnchor).isActive = true
        warningView.centerXAnchor.constraint(equalTo: fillablePhraseContainer.centerXAnchor).isActive = true
        warningView.heightAnchor.constraint(equalToConstant: 37).isActive = true

        warningView.layer.cornerRadius = 4
        warningView.layer.masksToBounds = true
        warningView.layer.borderWidth = 1
        warningView.layer.borderColor = Theme.shared.colors.warningBoxBorder?.cgColor

        let warningLabel = UILabel()
        warningView.addSubview(warningLabel)

        warningLabel.textColor = Theme.shared.colors.warningBoxBorder
        warningLabel.font = Theme.shared.fonts.warningBoxTitleLabel
        warningLabel.text = NSLocalizedString("verify_phrase.warning", comment: "VerifyPhrase view")

        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        warningLabel.centerXAnchor.constraint(equalTo: warningView.centerXAnchor).isActive = true
        warningLabel.centerYAnchor.constraint(equalTo: warningView.centerYAnchor).isActive = true
    }

    private func setupSuccessView() {
        successView.backgroundColor = .clear
        successView.isHidden = true
        successView.image = Theme.shared.images.successIcon

        view.addSubview(successView)

        successView.translatesAutoresizingMaskIntoConstraints = false
        successView.widthAnchor.constraint(equalToConstant: 29).isActive = true
        successView.heightAnchor.constraint(equalToConstant: 29).isActive = true
        successView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        successView.topAnchor.constraint(equalTo: selectablePhraseView.topAnchor).isActive = true
    }

    private func setupContinueButton() {
        continueButton.setTitle(NSLocalizedString("verify_phrase.complete", comment: "VerifyPhrase view"), for: .normal)
        continueButton.addTarget(self, action: #selector(continueButtonAction), for: .touchUpInside)
        continueButton.variation = .disabled

        view.addSubview(continueButton)
        continueButton.translatesAutoresizingMaskIntoConstraints = false

        continueButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                                constant: Theme.shared.sizes.appSidePadding).isActive = true
        continueButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                 constant: -Theme.shared.sizes.appSidePadding).isActive = true
        continueButton.centerXAnchor.constraint(equalTo: view.centerXAnchor,
                                                constant: 0).isActive = true

        let continueButtonConstraint = continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        continueButtonConstraint.priority = UILayoutPriority(rawValue: 999)
        continueButtonConstraint.isActive = true

        let continueButtonSecondConstraint = continueButton.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -20)
        continueButtonSecondConstraint.priority = UILayoutPriority(rawValue: 1000)
        continueButtonSecondConstraint.isActive = true
    }

    @objc private func continueButtonAction() {

    }

    private func animateWarnintView() {
        warningView.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)

        UIView.animate(withDuration: CATransaction.animationDuration(), animations: { [weak self] in
            guard let self = self else { return }
            self.warningView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.warningView.isHidden = false
        }, completion: nil)
    }

    private func showResultWithAnimation() {
        let view = success ? successView : warningView
        view.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)

        UIView.animate(withDuration: CATransaction.animationDuration(), animations: {
            view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        })
    }
}

extension VerifyPhraseViewController: WordsFlexViewDelegate {
    func didSelectWord(word: String, intId: Int, phraseView: WordsFlexView) {
        switch phraseView.type {
        case .fillable: selectablePhraseView?.restore(word: word, intId: intId)

        case .selectable: fillablePhraseView?.addWord(word, intId: intId)
        }

        success = selectablePhraseView.words == fillablePhraseView.words // here we should to compare with seed phrase, not arrays (this is just for tests)

        UIView.animate(withDuration: CATransaction.animationDuration()) {
            self.fillableContainerDescription.alpha = self.fillablePhraseView.words.isEmpty ? 1.0 : 0.0
        }
    }
}

extension VerifyPhraseViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isModalInPresentation = true // Disabling dismiss controller with swipe down on scroll view
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isModalInPresentation = false
    }
}
