//  AddAmountViewController.swift

/*
	Package MobileWallet
	Created by Semih Cihan on 12.02.2020
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

class AddAmountViewController: UIViewController {
    var publicKey: PublicKey?
    var deepLinkParams: DeepLinkParams?
    private var buttons = [UIButton]()
    private let navigationBar = NavigationBar()
    private let continueButton = ActionButton(frame: .zero)
    private let amountLabel = AnimatedBalanceLabel()
    private let keypadContainerStackView = UIStackView()
    private let warningView = UIView()
    private let warningLabel = UILabel()
    private let warningBalanceLabel = UILabel()
    private let txViewContainer = UIView()
    private let animationDuration = 0.2
    private var balanceCheckTimer: Timer?
    private let txFeeLabel = UILabel()
    private let gemImageString: NSAttributedString = {
        let gemAttachment = NSTextAttachment()
        gemAttachment.image = Theme.shared.images.currencySymbol?.withTintColor(Theme.shared.colors.amountLabel!)
        gemAttachment.bounds = CGRect(x: 0, y: 0, width: 21, height: 21)
        return NSAttributedString(attachment: gemAttachment)
    }()

    var rawInput = ""
    private var txFeeIsVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.shared.colors.appBackground
        overrideUserInterfaceStyle = .light
        setup()
        displayAliasOrEmojiId()
        updateLabelText()

        //Deep link value
        if let params = deepLinkParams {
            if params.amount.rawValue > 0 {
                addCharacter(params.amount.formatted)
            }
        }

        Tracker.shared.track("/home/send_tari/add_amount", "Send Tari - Add Amount")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        balanceCheckTimer?.invalidate()
        balanceCheckTimer = nil
    }

    private func displayAliasOrEmojiId() {
        guard let wallet = TariLib.shared.tariWallet, let pubKey = publicKey else {
            return
        }

        do {
            guard let contact = try wallet.contacts.0?.find(publicKey: pubKey) else { return }

            if contact.alias.0.trimmingCharacters(in: .whitespaces).isEmpty {
                try navigationBar.showEmojiId(pubKey, inViewController: self)
            } else {
                navigationBar.title = contact.alias.0
            }
        } catch {
            do {
                try navigationBar.showEmojiId(pubKey, inViewController: self)
            } catch {
                UserFeedback.shared.error(
                    title: NSLocalizedString("navigation_bar.error.show_emoji.title", comment: "Navigation bar"),
                    description: NSLocalizedString("navigation_bar.error.show_emoji.description", comment: "Navigation bar"),
                    error: error
                )
            }
        }
    }

    @objc private func checkAvailableBalance() {
        var microTariAmount = MicroTari(0)

        do {
            microTariAmount = try MicroTari(tariValue: rawInput)
        } catch {
            continueButton.variation = .disabled
            showInvalidNumberError(error)
            return
        }

        guard let wallet = TariLib.shared.tariWallet else {
            return
        }

        let (totalMicroTari, totalMicroTariError) = wallet.totalMicroTari
        guard totalMicroTariError == nil else {
            UserFeedback.shared.error(
                title: NSLocalizedString("add_amount.error.available_balance.title", comment: "Add amount view"),
                description: NSLocalizedString("add_amount.error.available_balance.description", comment: "Add amount view"),
                error: totalMicroTariError
            )
            return
        }

        var fee: MicroTari
        do {
            fee = try wallet.estimateTxFee(
                amount: microTariAmount,
                gramFee: Wallet.defaultGramFee,
                kernelCount: Wallet.defaultKernelCount,
                outputCount: Wallet.defaultOutputCount
            )
        } catch {
            switch error {
            case WalletErrors.notEnoughFunds:
                showBalanceExceeded(balance: totalMicroTari!.formatted)
                continueButton.variation = .disabled
                hideTxFee()
            default:
                break
            }
            return
        }

        if totalMicroTari!.rawValue < (microTariAmount.rawValue + fee.rawValue) {
            showBalanceExceeded(balance: totalMicroTari!.formatted)
            continueButton.variation = .disabled
        } else {
            continueButton.variation = .normal
        }

        showTxFee(fee)
    }

    @objc private func keypadButtonTapped(_ sender: UIButton) {
        if sender.tag != 12 {
            let value: String = {
                if sender.tag < 10 {
                    return String(sender.tag)
                } else if sender.tag == 11 {
                    return "0"
                } else {
                    return String(MicroTari.decimalSeparator)
                }
            }()

            addCharacter(value)
        } else {
            deleteCharacter()
        }
    }

    //Shouldn't ever really be used but just in case
    private func showInvalidNumberError(_ error: Error?) {
        UserFeedback.shared.error(
            title: NSLocalizedString("add_amount.error.invalid_number", comment: "Add amount view"),
            description: "",
            error: error
        )
    }

    private func deleteCharacter() {
        guard !rawInput.isEmpty else {
            return
        }

        let updatedInput = String(rawInput.dropLast())

        rawInput = updatedInput
        updateLabelText()
    }

    private func addCharacter(_ value: String) {
        var updatedText = rawInput + value

        if rawInput.isEmpty && value == MicroTari.decimalSeparator {
            updatedText = "0" + updatedText
        } else if rawInput == "0" && value != MicroTari.decimalSeparator {
            updatedText = value
        }

        if value == MicroTari.decimalSeparator && rawInput.contains(MicroTari.decimalSeparator) {
            return
        }

        if numberOfDecimals(in: updatedText) > MicroTari.ROUNDED_FRACTION_DIGITS {
            return
        }

        if MicroTari.checkValue(updatedText) {
            rawInput = updatedText
            updateLabelText()
        }
    }

    private func updateLabelText() {
        let amountAttributedText = NSMutableAttributedString(
            string: convertRawToFormattedString() ?? "0",
            attributes: [
                NSAttributedString.Key.font: Theme.shared.fonts.amountLabel,
                NSAttributedString.Key.foregroundColor: Theme.shared.colors.amountLabel!
            ]
        )

        amountAttributedText.insert(gemImageString, at: 0)
        amountAttributedText.insert(NSAttributedString(string: "  "), at: 1)
        amountLabel.attributedText = amountAttributedText

        hideBalanceExceeded()

        let isValidValue = isValidNumber(string: rawInput, finalNumber: true)

        if balanceCheckTimer != nil {
            balanceCheckTimer?.invalidate()
        }
        if isValidValue == true {
            balanceCheckTimer = Timer.scheduledTimer(
                timeInterval: 0.2,
                target: self,
                selector: #selector(checkAvailableBalance),
                userInfo: nil,
                repeats: false
            )
        } else {
            hideTxFee()
            continueButton.variation = .disabled
        }
    }

    private func isValidNumber(string: String, finalNumber: Bool) -> Bool {
        if !finalNumber && string.isEmpty {
            return true
        }

        guard string == "0"
            || (string.first == "0" && String(string[string.index(string.startIndex, offsetBy: 1)]) == MicroTari.decimalSeparator)
            || string.first != "0" else {
            return false
        }

        guard string.filter({$0 == MicroTari.decimalSeparator.first}).count < 2 else {
            return false
        }

        guard numberOfDecimals(in: string) <= MicroTari.ROUNDED_FRACTION_DIGITS else {
            return false
        }

        var str = string
        if !finalNumber && string.last == MicroTari.decimalSeparator.first {
            str = String(str.dropLast())
        }

        do {
            let mt = try MicroTari(tariValue: str)
            return mt.rawValue > 0
        } catch {
            return false
        }
    }

    private func convertRawToFormattedString() -> String? {
        var decimalRemovedIfAtEndRawInput = rawInput
        var decimalRemoved = false
        if rawInput.last == MicroTari.decimalSeparator.first {
            decimalRemovedIfAtEndRawInput = String(rawInput.dropLast())
            decimalRemoved = true
        }

        guard let number = MicroTari.convertToNumber(decimalRemovedIfAtEndRawInput) else {
            return nil
        }

        guard let formattedNumberString = MicroTari.convertToString(number, minimumFractionDigits: numberOfDecimals(in: decimalRemovedIfAtEndRawInput)) else {
            return nil
        }

        return formattedNumberString + (decimalRemoved ? MicroTari.decimalSeparator : "")
    }

    private func numberOfDecimals(in string: String) -> Int {
        if let groupIndex = string.indexDistance(of: MicroTari.decimalSeparator) {
            return max(string.count - groupIndex - 1, 0)
        }

        return 0
    }

    @objc private func feeButtonPressed(_ sender: UIButton) {
        UserFeedback.shared.info(
            title: NSLocalizedString("common.fee_info.title", comment: "Common"),
            description: NSLocalizedString("common.fee_info.description", comment: "Common"))
    }

    private func showBalanceExceeded(balance: String) {
        UINotificationFeedbackGenerator().notificationOccurred(.error)

        warningBalanceLabel.text = balance
        warningView.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        UIView.animate(withDuration: animationDuration, animations: { [weak self] in
            guard let self = self else {return}
            self.warningView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.warningView.isHidden = false
        }, completion: nil)

        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = animationDuration / 4
        animation.repeatCount = 2
        animation.autoreverses = true
        animation.fromValue = CGPoint(x: amountLabel.center.x - 10, y: amountLabel.center.y)
        animation.toValue = CGPoint(x: amountLabel.center.x + 10, y: amountLabel.center.y)
        amountLabel.layer.add(animation, forKey: "position")
    }

    private func hideBalanceExceeded() {
        warningView.isHidden = true
    }

    private func showTxFee(_ fee: MicroTari) {
        txFeeLabel.text = fee.formattedPreciseWithOperator
        if txFeeIsVisible { return }
        txViewContainer.alpha = 0.0
        let moveAnimation: CATransition = CATransition()
        moveAnimation.timingFunction = CAMediaTimingFunction(name:
                CAMediaTimingFunctionName.easeIn)
        moveAnimation.type = CATransitionType.push
        moveAnimation.subtype = .fromTop
        moveAnimation.duration = animationDuration
        UIView.animate(withDuration: animationDuration) { [weak self] in
            guard let self = self else {return}
            self.txViewContainer.alpha = 1.0
            self.txViewContainer.layer.add(moveAnimation, forKey: CATransitionType.push.rawValue)
        }
        self.txFeeIsVisible = true
    }

    private func hideTxFee() {
        UIView.animate(withDuration: animationDuration) { [weak self] in
            guard let self = self else {return}
            self.txViewContainer.alpha = 0.0
        }
        self.txFeeIsVisible = false
    }

    @objc private func continueButtonTapped() {
        //Check the actual available balance first, to see if we have enough mined transactions
        guard let wallet = TariLib.shared.tariWallet else { return }
        let (availableBalance, availableBalanceError) = wallet.availableBalance
        guard availableBalanceError == nil else {
            UserFeedback.shared.error(
                title: NSLocalizedString("add_amount.error.available_balance.title", comment: "Add amount view"),
                description: NSLocalizedString("add_amount.error.available_balance.description", comment: "Add amount view"),
                error: availableBalanceError
            )
            return
        }

        var tariAmount: MicroTari?
        do {
            tariAmount = try MicroTari(tariValue: rawInput)
        } catch {
            showInvalidNumberError(error)
        }

        guard let amount = tariAmount else { return }

        var fee = MicroTari(0)
        do {
            fee = try wallet.estimateTxFee(
                amount: amount,
                gramFee: Wallet.defaultGramFee,
                kernelCount: Wallet.defaultKernelCount,
                outputCount: Wallet.defaultOutputCount
            )
        } catch {
            return
        }

        if amount.rawValue + fee.rawValue  > availableBalance {
            UserFeedback.shared.info(
                title: NSLocalizedString("add_amount.info.wait_completion_previous_tx.title", comment: "Add amount view"),
                description: NSLocalizedString("add_amount.info.wait_completion_previous_tx.descrption", comment: "Add amount view")
            )
            return
        }

        let noteVC = AddNoteViewController()
        noteVC.publicKey = publicKey
        noteVC.amount = tariAmount
        noteVC.deepLinkParams = deepLinkParams

        navigationController?.pushViewController(noteVC, animated: true)
    }
}

extension AddAmountViewController {
    private func setup() {
        // navigationBar
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationBar)
        navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        navigationBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        navigationBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        navigationBar.heightAnchor.constraint(equalToConstant: 44).isActive = true

        //contiue button
        view.addSubview(continueButton)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        continueButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true

        let continueButtonConstraint = continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        continueButtonConstraint.priority = UILayoutPriority(rawValue: 999)
        continueButtonConstraint.isActive = true

        let continueButtonSecondConstraint = continueButton.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -Theme.shared.sizes.appSidePadding)
        continueButtonSecondConstraint.priority = UILayoutPriority(rawValue: 1000)
        continueButtonSecondConstraint.isActive = true

        continueButton.setTitle(NSLocalizedString("common.continue", comment: "Common"), for: .normal)
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        continueButton.isEnabled = false
        setupKeypad()

        //amount container
        let amountContainer = UIView()
        amountContainer.backgroundColor = .clear
        view.addSubview(amountContainer)
        amountContainer.translatesAutoresizingMaskIntoConstraints = false
        amountContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        amountContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        amountContainer.topAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
        amountContainer.bottomAnchor.constraint(equalTo: keypadContainerStackView.topAnchor).isActive = true

        //amount label
        view.addSubview(amountLabel)
        amountLabel.animation = .type
        amountLabel.textAlignment = .center(inset: -30)
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.trailingAnchor.constraint(equalTo: amountContainer.trailingAnchor, constant: -25).isActive = true
        amountLabel.leadingAnchor.constraint(equalTo: amountContainer.leadingAnchor, constant: 25).isActive = true
        amountLabel.centerYAnchor.constraint(equalTo: amountContainer.centerYAnchor).isActive = true
        amountLabel.heightAnchor.constraint(equalToConstant: 75).isActive = true

        //warning view
        view.addSubview(warningView)
        warningView.isHidden = true
        warningView.translatesAutoresizingMaskIntoConstraints = false
        warningView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -50).isActive = true
        warningView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        warningView.topAnchor.constraint(greaterThanOrEqualTo: navigationBar.bottomAnchor, constant: 5).isActive = true
        warningView.topAnchor.constraint(lessThanOrEqualTo: navigationBar.bottomAnchor, constant: 20).isActive = true
        warningView.bottomAnchor.constraint(lessThanOrEqualTo: amountLabel.topAnchor, constant: -5).isActive = true

        warningView.layer.cornerRadius = 12
        warningView.layer.masksToBounds = true
        warningView.layer.borderWidth = 1
        warningView.layer.borderColor = Theme.shared.colors.warningBoxBorder?.cgColor
        warningView.setContentCompressionResistancePriority(.required, for: .vertical)

        let warningStackView = UIStackView()
        warningView.addSubview(warningStackView)
        warningStackView.alignment = .center
        warningStackView.axis = .vertical
        warningStackView.spacing = 4
        warningStackView.translatesAutoresizingMaskIntoConstraints = false
        warningStackView.widthAnchor.constraint(greaterThanOrEqualTo: warningView.widthAnchor, constant: -26).isActive = true
        warningStackView.heightAnchor.constraint(equalTo: warningView.heightAnchor, constant: -26).isActive = true
        warningStackView.centerXAnchor.constraint(equalTo: warningView.centerXAnchor).isActive = true
        warningStackView.centerYAnchor.constraint(equalTo: warningView.centerYAnchor).isActive = true

        let warningBalanceStackView = UIStackView()
        warningBalanceStackView.alignment = .center
        warningStackView.addArrangedSubview(warningBalanceStackView)
        warningBalanceStackView.spacing = 4
        let warningBalanceIcon = UIImageView(image: Theme.shared.images.currencySymbol?.withRenderingMode(.alwaysTemplate))
        warningBalanceIcon.translatesAutoresizingMaskIntoConstraints = false
        warningBalanceIcon.widthAnchor.constraint(equalToConstant: 11).isActive = true
        warningBalanceIcon.heightAnchor.constraint(equalToConstant: 11).isActive = true
        warningBalanceIcon.contentMode = .scaleAspectFit
        warningBalanceIcon.tintColor = Theme.shared.colors.warningBoxBorder
        warningBalanceStackView.addArrangedSubview(warningBalanceIcon)
        warningBalanceStackView.addArrangedSubview(warningBalanceLabel)
        warningBalanceLabel.font = Theme.shared.fonts.warningBoxTitleLabel
        warningBalanceLabel.textColor = Theme.shared.colors.warningBoxBorder
        warningBalanceLabel.text = "0.0"

        warningStackView.addArrangedSubview(warningLabel)
        warningLabel.font = Theme.shared.fonts.amountWarningLabel
        warningLabel.textColor = Theme.shared.colors.amountWarningLabel
        warningLabel.text = NSLocalizedString("add_amount.warning.not_enough_tari", comment: "Add amount view")
        warningLabel.textAlignment = .center
        warningLabel.heightAnchor.constraint(equalToConstant: warningLabel.font.pointSize * 1.2).isActive = true

        //tx fee
        txViewContainer.alpha = 0.0
        view.addSubview(txViewContainer)
        txViewContainer.translatesAutoresizingMaskIntoConstraints = false
        txViewContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        txViewContainer.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 12).isActive = true
        let txStackView = UIStackView()
        txStackView.translatesAutoresizingMaskIntoConstraints = false
        txViewContainer.addSubview(txStackView)
        txStackView.leftAnchor.constraint(equalTo: txViewContainer.leftAnchor).isActive = true
        txStackView.rightAnchor.constraint(equalTo: txViewContainer.rightAnchor).isActive = true
        txStackView.topAnchor.constraint(equalTo: txViewContainer.topAnchor).isActive = true
        txStackView.bottomAnchor.constraint(equalTo: txViewContainer.bottomAnchor).isActive = true
        txStackView.alignment = .center
        txStackView.axis = .vertical

        txFeeLabel.translatesAutoresizingMaskIntoConstraints = false
        txFeeLabel.font = Theme.shared.fonts.txFeeLabel
        txFeeLabel.textColor = Theme.shared.colors.txViewValueLabel

        let feeButton = TextButton()
        feeButton.translatesAutoresizingMaskIntoConstraints = false
        feeButton.setTitle(NSLocalizedString("common.fee", comment: "Common"), for: .normal)
        feeButton.setRightImage(Theme.shared.images.txFee!)
        feeButton.addTarget(self, action: #selector(feeButtonPressed), for: .touchUpInside)
        continueButton.variation = .disabled

        txStackView.addArrangedSubview(txFeeLabel)
        txStackView.addArrangedSubview(feeButton)
    }

    private func setupKeypad() {
        view.addSubview(keypadContainerStackView)
        keypadContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        keypadContainerStackView.axis = .vertical
        keypadContainerStackView.distribution = .equalSpacing
        keypadContainerStackView.spacing = min(26, view.frame.height * 0.032)
        keypadContainerStackView.backgroundColor = .clear
        keypadContainerStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        let keypadContainerStackViewConstraint = keypadContainerStackView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -10)
        keypadContainerStackViewConstraint.priority = UILayoutPriority(rawValue: 249)
        keypadContainerStackViewConstraint.isActive = true

        let keypadContainerStackViewSecondConstraint = keypadContainerStackView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -40)
        keypadContainerStackViewSecondConstraint.priority = UILayoutPriority(rawValue: 250)
        keypadContainerStackViewSecondConstraint.isActive = true

        keypadContainerStackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: Theme.shared.sizes.appSidePadding).isActive = true
        keypadContainerStackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -Theme.shared.sizes.appSidePadding).isActive = true

        let rows = [UIStackView(), UIStackView(), UIStackView(), UIStackView()]
        rows.forEach({
            $0.axis = .horizontal
            $0.distribution = .fillEqually
            keypadContainerStackView.addArrangedSubview($0)
        })

        for i in 0..<12 {
            let button = UIButton(type: .system)
            button.addTarget(self, action: #selector(keypadButtonTapped(_:)), for: .touchUpInside)
            button.tag = i + 1
            button.setTitleColor(Theme.shared.colors.keypadButton, for: .normal)
            button.tintColor = Theme.shared.colors.keypadButton
            button.titleLabel?.font = Theme.shared.fonts.keypadButton
            rows[i / (rows.count - 1)].addArrangedSubview(button)
            button.heightAnchor.constraint(equalToConstant: 35).isActive = true

            if i < 9 {
                button.setTitle("\(i + 1)", for: .normal)
            } else if i == 9 {
                button.setTitle(String(MicroTari.decimalSeparator), for: .normal)
            } else if i == 10 {
                button.setTitle("0", for: .normal)
            } else if i == 11 {
                button.setImage(Theme.shared.images.delete, for: .normal)
            }
        }
    }

}
