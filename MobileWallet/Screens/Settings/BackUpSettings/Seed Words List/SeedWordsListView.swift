//  SeedWordsListView.swift

/*
	Package MobileWallet
	Created by Adrian Truszczynski on 07/03/2022
	Using Swift 5.0
	Running on macOS 12.2

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

final class SeedWordsListView: BaseNavigationContentView {

    // MARK: - Subviews

    @View private var descriptionLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.shared.fonts.settingsSeedPhraseDescription
        view.text = localized("seed_phrase.header")
        view.numberOfLines = 0
        return view
    }()

    @View private var seedWordsBackgroundView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = 10.0
        return view
    }()

    @View private var seedWordsContentView = UIView()
    @View private var firstSeedWordsContentView = UIView()
    @View private var secondSeedWordsContentView = UIView()

    @View private var firstSeedWordsStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 5.0
        return view
    }()

    @View private var secondSeedWordsStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 5.0
        return view
    }()

    @View private var checkBox = CheckBox()

    @View private var agreementLabel: UILabel = {
        let view = UILabel()
        view.text = localized("seed_phrase.agreement")
        view.font = Theme.shared.fonts.settingsSeedPhraseAgreement
        view.numberOfLines = 0
        return view
    }()

    @View private(set) var continueButton: ActionButton = {
        let view = ActionButton()
        view.setTitle(localized("seed_phrase.verify_seed_phrase"), for: .normal)
        return view
    }()

    @View private var expandListButton = ExpandButton()

    private let fadeOutMask: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
        return layer
    }()

    // MARK: - Properties

    var seedWords: [String] = [] {
        didSet { updateSeedWords() }
    }

    var isContinueButtonEnabled: Bool = false {
        didSet { continueButton.variation = isContinueButtonEnabled ? .normal : .disabled }
    }

    var isAnimationEnabled: Bool = false
    var onCheckBoxStateChanged: ((Bool) -> Void)?

    private var collapsedListConstraints: [NSLayoutConstraint] = []
    private var expandedListConstraints: [NSLayoutConstraint] = []

    private var isListExpanded = false {
        didSet { updateListComponents() }
    }

    private var animationTime: TimeInterval { isAnimationEnabled ? 1.0 : 0.0 }

    private var isContentFitSpace: Bool {
        let firstColumnHeight = firstSeedWordsStackView.bounds.height
        let secondColumnHeight = secondSeedWordsStackView.bounds.height
        let avaiableSpace = seedWordsContentView.bounds.height
        return firstColumnHeight <= avaiableSpace || secondColumnHeight <= avaiableSpace
    }

    // MARK: - Initialisers

    override init() {
        super.init()
        setupViews()
        setupConstraints()
        setupCallbacks()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setups

    private func setupViews() {
        navigationBar.title = localized("seed_phrase.title")
        seedWordsBackgroundView.layer.mask = fadeOutMask
    }

    private func setupConstraints() {

        [descriptionLabel, checkBox, agreementLabel, continueButton, seedWordsBackgroundView, expandListButton].forEach(addSubview)
        seedWordsBackgroundView.addSubview(seedWordsContentView)
        [firstSeedWordsContentView, secondSeedWordsContentView].forEach(seedWordsContentView.addSubview)
        firstSeedWordsContentView.addSubview(firstSeedWordsStackView)
        secondSeedWordsContentView.addSubview(secondSeedWordsStackView)

        let contentViewBottomConstraints = [
            firstSeedWordsContentView.bottomAnchor.constraint(equalTo: seedWordsContentView.bottomAnchor),
            secondSeedWordsContentView.bottomAnchor.constraint(equalTo: seedWordsContentView.bottomAnchor)
        ]

        contentViewBottomConstraints.forEach { $0.priority = .defaultLow }

        collapsedListConstraints = [
            seedWordsBackgroundView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20.0),
            seedWordsBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            seedWordsBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            seedWordsContentView.topAnchor.constraint(equalTo: seedWordsBackgroundView.topAnchor, constant: 30.0),
            seedWordsContentView.bottomAnchor.constraint(equalTo: seedWordsBackgroundView.bottomAnchor, constant: -30.0),
            agreementLabel.topAnchor.constraint(greaterThanOrEqualTo: seedWordsBackgroundView.bottomAnchor, constant: 33.0),
            expandListButton.bottomAnchor.constraint(equalTo: seedWordsBackgroundView.bottomAnchor, constant: -14.0)
        ]

        collapsedListConstraints += contentViewBottomConstraints

        expandedListConstraints = [
            seedWordsBackgroundView.topAnchor.constraint(equalTo: topAnchor),
            seedWordsBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            seedWordsBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            seedWordsBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            seedWordsContentView.centerXAnchor.constraint(equalTo: centerXAnchor),
            seedWordsContentView.centerYAnchor.constraint(equalTo: centerYAnchor),
            firstSeedWordsContentView.bottomAnchor.constraint(equalTo: seedWordsContentView.bottomAnchor),
            secondSeedWordsContentView.bottomAnchor.constraint(equalTo: seedWordsContentView.bottomAnchor),
            expandListButton.topAnchor.constraint(equalTo: seedWordsBackgroundView.topAnchor, constant: 58.0)
        ]

        let constraints = [
            descriptionLabel.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 25.0),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            seedWordsContentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 65.0),
            seedWordsContentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -65.0),
            firstSeedWordsContentView.topAnchor.constraint(equalTo: seedWordsContentView.topAnchor),
            firstSeedWordsContentView.leadingAnchor.constraint(equalTo: seedWordsContentView.leadingAnchor),
            secondSeedWordsContentView.topAnchor.constraint(equalTo: seedWordsContentView.topAnchor),
            secondSeedWordsContentView.leadingAnchor.constraint(equalTo: firstSeedWordsContentView.trailingAnchor, constant: 30.0),
            secondSeedWordsContentView.trailingAnchor.constraint(equalTo: seedWordsContentView.trailingAnchor),
            secondSeedWordsContentView.widthAnchor.constraint(equalTo: firstSeedWordsContentView.widthAnchor),
            firstSeedWordsStackView.topAnchor.constraint(equalTo: firstSeedWordsContentView.topAnchor),
            firstSeedWordsStackView.leadingAnchor.constraint(equalTo: firstSeedWordsContentView.leadingAnchor),
            firstSeedWordsStackView.trailingAnchor.constraint(equalTo: firstSeedWordsContentView.trailingAnchor),
            firstSeedWordsStackView.bottomAnchor.constraint(equalTo: firstSeedWordsContentView.bottomAnchor),
            secondSeedWordsStackView.topAnchor.constraint(equalTo: secondSeedWordsContentView.topAnchor),
            secondSeedWordsStackView.leadingAnchor.constraint(equalTo: secondSeedWordsContentView.leadingAnchor),
            secondSeedWordsStackView.trailingAnchor.constraint(equalTo: secondSeedWordsContentView.trailingAnchor),
            secondSeedWordsStackView.bottomAnchor.constraint(equalTo: secondSeedWordsContentView.bottomAnchor),
            checkBox.topAnchor.constraint(equalTo: agreementLabel.topAnchor, constant: 3.0),
            checkBox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25.0),
            checkBox.heightAnchor.constraint(equalToConstant: 25.0),
            checkBox.widthAnchor.constraint(equalToConstant: 25.0),
            agreementLabel.leadingAnchor.constraint(equalTo: checkBox.trailingAnchor, constant: 18.0),
            agreementLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25.0),
            continueButton.topAnchor.constraint(equalTo: agreementLabel.bottomAnchor, constant: 25.0),
            continueButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22.0),
            continueButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22.0),
            continueButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20.0),
            expandListButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8.0 - 25.0)
        ]

        NSLayoutConstraint.activate(constraints + collapsedListConstraints)
    }

    private func setupCallbacks() {
        expandListButton.onTap = { [weak self] in
            self?.isListExpanded.toggle()
        }

        checkBox.addTarget(self, action: #selector(onCheckBoxAction(_:)), for: .touchUpInside)
    }

    // MARK: - Updates

    override func update(theme: ColorTheme) {
        super.update(theme: theme)

        descriptionLabel.textColor = theme.text.body
        seedWordsBackgroundView.backgroundColor = theme.backgrounds.secondary
        agreementLabel.textColor = theme.text.body
    }

    private func updateSeedWords() {

        firstSeedWordsStackView.arrangedSubviews.forEach(firstSeedWordsStackView.removeArrangedSubview)
        secondSeedWordsStackView.arrangedSubviews.forEach(secondSeedWordsStackView.removeArrangedSubview)

        let dividePoint = seedWords.count / 2

        seedWords
            .enumerated()
            .forEach { [weak self] index, seedWord in
                guard let self = self else { return }

                let stackView = dividePoint > index ? self.firstSeedWordsStackView : self.secondSeedWordsStackView

                let element = SeedWordListElementView()
                element.index = String(index + 1)
                element.text = seedWord
                stackView.addArrangedSubview(element)
            }
    }

    // MARK: - Actions

    private func updateListComponents() {

        if isListExpanded {
            NSLayoutConstraint.deactivate(collapsedListConstraints)
            NSLayoutConstraint.activate(expandedListConstraints)
        } else {
            NSLayoutConstraint.deactivate(expandedListConstraints)
            NSLayoutConstraint.activate(collapsedListConstraints)
        }

        UIView.animate(withDuration: animationTime, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.0, options: [], animations: { [weak self] in
            guard let self = self else { return }
            self.expandListButton.areArrowsPointedInside = self.isListExpanded
            self.layoutIfNeeded()
        }, completion: nil)
    }

    private func updateFadeOutMask() {
        let fadeOutEnabled = !isListExpanded && !isContentFitSpace
        let maskFinalColor = fadeOutEnabled ? UIColor.clear.cgColor : UIColor.black.cgColor
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationTime / 2.0)
        fadeOutMask.frame = CGRect(x: 0.0, y: 0.0, width: bounds.width, height: seedWordsBackgroundView.bounds.height)
        fadeOutMask.colors = [UIColor.black.cgColor, UIColor.black.cgColor, maskFinalColor]
        CATransaction.commit()
    }

    private func updateExpandButton() {
        let isButtonVisible = isListExpanded || !isContentFitSpace
       expandListButton.isHidden = !isButtonVisible
    }

    // MARK: - Action Targets

    @objc private func onCheckBoxAction(_ sender: CheckBox) {
        onCheckBoxStateChanged?(sender.isChecked)
    }

    // MARK: - Autolayout

    override func layoutSubviews() {
        super.layoutSubviews()
        DispatchQueue.main.async {
            self.updateFadeOutMask()
            self.updateExpandButton()
        }
    }
}
