//  SeedPhraseViewController.swift

/*
	Package MobileWallet
	Created by S.Shovkoplyas on 29.05.2020
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

class SeedPhraseViewController: SettingsParentViewController {
    private let descriptionLabel = UILabel()
    private let continueButton = ActionButton()
    private let agreementContainer = UIView()

    private let phraseContainer = UIView()
    private var collectionView: UICollectionView?
    private let fadeOverlayView = FadedOverlayView()

    private let cellIdentifier = "SeedPhraseCell"

    private var seedWords = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        if let walletSeedWords = TariLib.shared.tariWallet?.seedWords.0 {
            seedWords.removeAll()
            seedWords.append(contentsOf: walletSeedWords)
            collectionView?.reloadData()
        } else {
            UserFeedback.showError(
                title: localized("seed_phrase.error.title"),
                description: localized("seed_phrase.error.description")
            ) {
                [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fadeOverlayView.applyFade(
            Theme.shared.colors.appBackground!,
            locations: [0.3, 1]
        )
    }

}

extension SeedPhraseViewController: UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: cellIdentifier,
                for: indexPath as IndexPath
        ) as? SeedPhraseCell else {
            return UICollectionViewCell()
        }
        var actualIndex = indexPath.row / 2
        if indexPath.row % 2 != 0 {
            actualIndex = actualIndex + seedWords.count / 2
        }
        let seedWord = seedWords[actualIndex]
        cell.configure(number: "\(actualIndex + 1)", word: seedWord)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return seedWords.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
        let width = collectionView.bounds.width - layout.sectionInset.left - layout.sectionInset.right - layout.minimumLineSpacing
        return CGSize(width: width/2, height: 20)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isModalInPresentation = true // Disabling dismiss controller with swipe down on scroll view
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isModalInPresentation = false
    }
}

extension SeedPhraseViewController {
    override func setupViews() {
        super.setupViews()

        setupHeader()
        setupContinueButton()
        setupAgreementContainer()
        setupPhraseContainer()
        setupCollectionView()
    }

    override func setupNavigationBar() {
        super.setupNavigationBar()
        navigationBar.title = localized("seed_phrase.title")
    }

    private func setupHeader() {
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = Theme.shared.fonts.settingsSeedPhraseDescription
        descriptionLabel.textColor = Theme.shared.colors.settingsViewDescription
        descriptionLabel.text = localized("seed_phrase.header")

        view.addSubview(descriptionLabel)

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 25).isActive = true
        descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25).isActive = true
    }

    private func setupAgreementContainer() {
        agreementContainer.backgroundColor = .clear

        view.addSubview(agreementContainer)
        agreementContainer.translatesAutoresizingMaskIntoConstraints = false
        agreementContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25).isActive = true
        agreementContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25).isActive = true
        agreementContainer.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -25).isActive = true
        agreementContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 25).isActive = true

        let checkbox = CheckBox()
        checkbox.addTarget(self, action: #selector(checkBoxAction(_:)), for: .touchUpInside)
        agreementContainer.addSubview(checkbox)

        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.widthAnchor.constraint(equalToConstant: 25).isActive = true
        checkbox.heightAnchor.constraint(equalToConstant: 25).isActive = true
        checkbox.leadingAnchor.constraint(equalTo: agreementContainer.leadingAnchor).isActive = true
        checkbox.topAnchor.constraint(equalTo: agreementContainer.topAnchor, constant: 3.0).isActive = true

        let agreementLabel = UILabel()
        agreementLabel.numberOfLines = 0
        agreementLabel.textAlignment = .left

        agreementContainer.addSubview(agreementLabel)

        agreementLabel.text = localized("seed_phrase.agreement")
        agreementLabel.font = Theme.shared.fonts.settingsSeedPhraseAgreement
        agreementLabel.textColor = Theme.shared.colors.settingsSeedPhraseAgreement!

        agreementLabel.translatesAutoresizingMaskIntoConstraints = false
        agreementLabel.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 18.0).isActive = true
        agreementLabel.topAnchor.constraint(equalTo: agreementContainer.topAnchor).isActive = true
        agreementLabel.bottomAnchor.constraint(equalTo: agreementContainer.bottomAnchor).isActive = true
        agreementLabel.trailingAnchor.constraint(equalTo: agreementContainer.trailingAnchor).isActive = true
    }

    private func setupContinueButton() {
        continueButton.setTitle(localized("seed_phrase.verify_seed_phrase"), for: .normal)
        continueButton.addTarget(self, action: #selector(continueButtonAction), for: .touchUpInside)
        continueButton.variation = .disabled
        view.addSubview(continueButton)
        continueButton.translatesAutoresizingMaskIntoConstraints = false

        continueButton.leadingAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.leadingAnchor,
            constant: Theme.shared.sizes.appSidePadding
        ).isActive = true
        continueButton.trailingAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.trailingAnchor,
            constant: -Theme.shared.sizes.appSidePadding
        ).isActive = true
        continueButton.centerXAnchor.constraint(
            equalTo: view.centerXAnchor,
            constant: 0
        ).isActive = true

        let continueButtonConstraint = continueButton.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor
        )
        continueButtonConstraint.priority = UILayoutPriority(rawValue: 999)
        continueButtonConstraint.isActive = true

        let continueButtonSecondConstraint = continueButton.bottomAnchor.constraint(
            lessThanOrEqualTo: view.bottomAnchor,
            constant: -20
        )
        continueButtonSecondConstraint.priority = UILayoutPriority(rawValue: 1000)
        continueButtonSecondConstraint.isActive = true
    }

    private func setupPhraseContainer() {
        phraseContainer.backgroundColor = Theme.shared.colors.settingsVerificationPhraseViewBackground
        phraseContainer.layer.cornerRadius = 10.0
        phraseContainer.layer.masksToBounds = true

        view.addSubview(phraseContainer)

        phraseContainer.translatesAutoresizingMaskIntoConstraints = false
        phraseContainer.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20).isActive = true
        phraseContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25).isActive = true
        phraseContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25).isActive = true
        phraseContainer.bottomAnchor.constraint(equalTo: agreementContainer.topAnchor, constant: -20).isActive = true

        phraseContainer.addSubview(fadeOverlayView)
        fadeOverlayView.isUserInteractionEnabled = false
        fadeOverlayView.translatesAutoresizingMaskIntoConstraints = false

        fadeOverlayView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        fadeOverlayView.leadingAnchor.constraint(equalTo: phraseContainer.leadingAnchor).isActive = true
        fadeOverlayView.trailingAnchor.constraint(equalTo: phraseContainer.trailingAnchor).isActive = true
        fadeOverlayView.bottomAnchor.constraint(equalTo: phraseContainer.bottomAnchor).isActive = true
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 25
        layout.minimumInteritemSpacing = 25
        layout.sectionInset = UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)

        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)

        collectionView?.register(SeedPhraseCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView?.backgroundColor = .clear

        phraseContainer.insertSubview(collectionView!, belowSubview: fadeOverlayView)

        collectionView?.translatesAutoresizingMaskIntoConstraints = false
        collectionView?.leadingAnchor.constraint(equalTo: phraseContainer.leadingAnchor).isActive = true
        collectionView?.trailingAnchor.constraint(equalTo: phraseContainer.trailingAnchor).isActive = true
        collectionView?.bottomAnchor.constraint(equalTo: phraseContainer.bottomAnchor).isActive = true
        collectionView?.topAnchor.constraint(equalTo: phraseContainer.topAnchor).isActive = true

        collectionView?.delegate = self
        collectionView?.dataSource = self
    }

    @objc private func checkBoxAction(_ sender: CheckBox) {
        continueButton.variation = sender.isChecked ? .normal : .disabled
    }

    @objc private func continueButtonAction() {
        let verifyPhraseViewController = VerifyPhraseViewController()
        verifyPhraseViewController.seedWords = seedWords
        navigationController?.pushViewController(
            verifyPhraseViewController,
            animated: true
        )
    }
}

private class SeedPhraseCell: UICollectionViewCell {
    private let numberLabel = UILabel()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLabels()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(number: String, word: String) {
        numberLabel.text = number
        titleLabel.text = word
    }

    private func setupLabels() {
        numberLabel.font = Theme.shared.fonts.settingsSeedPhraseCellNumber
        numberLabel.textColor = Theme.shared.colors.cettingsSeedPhraseCellTitle?.withAlphaComponent(0.5)

        contentView.addSubview(numberLabel)
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        numberLabel.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        numberLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        titleLabel.font = Theme.shared.fonts.settingsSeedPhraseCellTitle
        titleLabel.textColor = Theme.shared.colors.cettingsSeedPhraseCellTitle

        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraint(equalTo: numberLabel.trailingAnchor, constant: 10).isActive = true
        titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
}
