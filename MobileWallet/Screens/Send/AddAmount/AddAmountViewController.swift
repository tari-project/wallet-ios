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
    private var buttons = [UIButton]()
    private let continueButton = ActionButton(frame: .zero)
    private let amountLabel = AnimatedBalanceLabel()
    private let keypadContainerStackView = UIStackView()
    private let warningView = UIView()
    private let warningLabel = UILabel()
    private let warningBalanceLabel = UILabel()
    private let transactionViewContainer = UIView()
    private let animationDuration = 0.2
    private var balanceCheckTimer: Timer?
    private let transactionFeeLabel = UILabel()
    private let gemImageString: NSAttributedString = {
        let gemAttachment = NSTextAttachment()
        gemAttachment.image = Theme.shared.images.currencySymbol?.withTintColor(Theme.shared.colors.amountLabel!)
        gemAttachment.bounds = CGRect(x: 0, y: 0, width: 21, height: 21)
        return NSAttributedString(attachment: gemAttachment)
    }()

    var rawInput = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.shared.colors.appBackground
        overrideUserInterfaceStyle = .light
        setup()
        updateLabelText()

        Tracker.shared.track("/home/send_tari/add_amount", "Send Tari - Add Amount")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        styleNavigatorBar(isHidden: false)

        guard let pubKey = publicKey else { return }

        do {
            try showNavbarEmojies(pubKey)
        } catch {
            UserFeedback.shared.error(
                title: NSLocalizedString("Public key error", comment: "Add amount view"),
                description: NSLocalizedString("Failed to get Emoji ID from user's contact", comment: "Add amount view"),
                error: error
            )
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        hideNavbarEmojis()

        balanceCheckTimer?.invalidate()
        balanceCheckTimer = nil
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
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
                title: NSLocalizedString("Available Balance error", comment: "Amount screen"),
                description: NSLocalizedString("Failed to get the available balance.", comment: "Amount screen"),
                error: totalMicroTariError
            )
            return
        }

        guard totalMicroTari!.rawValue != 0 else {
            continueButton.variation = .disabled
            return
        }

        if totalMicroTari!.rawValue < microTariAmount.rawValue {
            showBalanceExceeded(balance: totalMicroTari!.formatted)
            continueButton.variation = .disabled
        } else {
            continueButton.variation = .normal
        }

        showTransactionFee(microTariAmount)
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

            addCharacater(value)
        } else {
            deleteCharacter()
        }
    }

    //Shouldn't ever really be used but just in case
    private func showInvalidNumberError(_ error: Error?) {
        UserFeedback.shared.error(
            title: NSLocalizedString("Invalid number", comment: "Add amount screen"),
            description: "",
            error: error
        )
    }

    private func deleteCharacter() {
        guard !rawInput.isEmpty else {
            return
        }

        let updatedInput = String(rawInput.dropLast())
        guard isValidNumber(string: updatedInput, finalNumber: false) else {
            return
        }

        rawInput = updatedInput
        updateLabelText()
    }

    private func addCharacater(_ value: String) {
        var updatedText = rawInput + value

        if rawInput.isEmpty && value == MicroTari.decimalSeparator {
            updatedText = "0" + updatedText
        } else if rawInput == "0" && value != MicroTari.decimalSeparator {
            updatedText = value
        }

        guard isValidNumber(string: updatedText, finalNumber: false) else {
            return
        }

        rawInput = updatedText
        updateLabelText()
    }

    private func updateLabelText() {
        let amountAttributedText = NSMutableAttributedString(
            string: convertRawToFormattedString() ?? "0",
            attributes: [
                NSAttributedString.Key.font: Theme.shared.fonts.amountLabel!,
                NSAttributedString.Key.foregroundColor: Theme.shared.colors.amountLabel!
            ]
        )

        amountAttributedText.insert(gemImageString, at: 0)
        amountLabel.attributedText = amountAttributedText

        hideBalanceExceeded()
        hideTransactionFee()
        continueButton.isEnabled = false

        if balanceCheckTimer != nil {
            balanceCheckTimer?.invalidate()
        }
        if isValidNumber(string: rawInput, finalNumber: true) {
            balanceCheckTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(checkAvailableBalance), userInfo: nil, repeats: false)
        }
    }

    private func isValidNumber(string: String, finalNumber: Bool) -> Bool {
        if !finalNumber && string.isEmpty {
            return true
        }

        guard string == "0" || (string.first == "0" && String(string[string.index(string.startIndex, offsetBy: 1)]) == MicroTari.decimalSeparator) || string.first != "0" else {
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

        if str == "0" && finalNumber {
            return false
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
            title: NSLocalizedString("Where does the fee go?", comment: "Transaction detail view"),
            description: NSLocalizedString("The transaction fee is distributed to the thousands of computers (also known as “miners”) who ensure that your Tari transactions are fast and secure.", comment: "Transaction detail view"))
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

    private func showTransactionFee(_ amount: MicroTari) {
        guard let wallet = TariLib.shared.tariWallet else { return }
        let fee = wallet.calculateTransactionFee(amount)

        transactionViewContainer.alpha = 0.0
        transactionFeeLabel.text = fee.formattedPreciseWithOperator
        let moveAnimation: CATransition = CATransition()
        moveAnimation.timingFunction = CAMediaTimingFunction(name:
                CAMediaTimingFunctionName.easeIn)
        moveAnimation.type = CATransitionType.push
        moveAnimation.subtype = .fromTop
        moveAnimation.duration = animationDuration
        UIView.animate(withDuration: animationDuration) { [weak self] in
            guard let self = self else {return}
            self.transactionViewContainer.alpha = 1.0
            self.transactionViewContainer.layer.add(moveAnimation, forKey: CATransitionType.push.rawValue)
        }
    }

    private func hideTransactionFee() {
        transactionViewContainer.alpha = 0.0
    }

    @objc private func continueButtonTapped() {
        //Check the actual available balance first, to see if we have enough mined transactions
        guard let wallet = TariLib.shared.tariWallet else { return }
        let (availableBalance, availableBalanceError) = wallet.availableBalance
        guard availableBalanceError == nil else {
            UserFeedback.shared.error(
                title: NSLocalizedString("Available balance error", comment: "Add amount view"),
                description: NSLocalizedString("Could not get available balance from wallet", comment: "Add amount view"),
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
        if amount.rawValue + wallet.calculateTransactionFee(amount).rawValue  > availableBalance {
            UserFeedback.shared.info(
                title: NSLocalizedString("Hold your horses! 🐴", comment: "Add amount view"),
                description: NSLocalizedString("Sorry, you can’t send this much Tari at once. Please wait for your other transaction to be completed and then try again.", comment: "Add amount view")
            )
            return
        }

        let noteVC = AddNoteViewController()
        noteVC.publicKey = publicKey
        noteVC.amount = tariAmount

        navigationController?.pushViewController(noteVC, animated: true)
    }
}

extension AddAmountViewController {
    private func setup() {
        //contiue button
        view.addSubview(continueButton)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 25).isActive = true
        continueButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -25).isActive = true
        continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        continueButton.setTitle(NSLocalizedString("Continue", comment: "Continue button on the amount screen"), for: .normal)
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        continueButton.isEnabled = false
        setupKeypad()

        //amount label
        view.addSubview(amountLabel)
        amountLabel.animation = .type
        amountLabel.textAlignment = .center
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        let amountTopLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(amountTopLayoutGuide)
        amountTopLayoutGuide.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        amountTopLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        let amountBottomLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(amountBottomLayoutGuide)
        amountBottomLayoutGuide.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        amountBottomLayoutGuide.bottomAnchor.constraint(equalTo: keypadContainerStackView.topAnchor).isActive = true
        amountBottomLayoutGuide.heightAnchor.constraint(equalTo: amountTopLayoutGuide.heightAnchor).isActive = true
        amountLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -8).isActive = true
        amountLabel.topAnchor.constraint(equalTo: amountTopLayoutGuide.bottomAnchor).isActive = true
        amountLabel.bottomAnchor.constraint(equalTo: amountBottomLayoutGuide.topAnchor).isActive = true
        amountLabel.heightAnchor.constraint(equalToConstant: 75).isActive = true
        amountLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 8).isActive = true

        //warning view
        view.addSubview(warningView)
        warningView.isHidden = true
        warningView.translatesAutoresizingMaskIntoConstraints = false
        warningView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -50).isActive = true
        warningView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        warningView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 25).isActive = true
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
        warningStackView.widthAnchor.constraint(equalTo: warningView.widthAnchor, constant: -24).isActive = true
        warningStackView.heightAnchor.constraint(equalTo: warningView.heightAnchor, constant: -24).isActive = true
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

        warningStackView.addArrangedSubview(warningLabel)
        warningLabel.font = Theme.shared.fonts.amountWarningLabel
        warningLabel.textColor = Theme.shared.colors.amountWarningLabel
        warningLabel.text = NSLocalizedString("Not enough Tari in your available balance", comment: "Balance amount error")
        warningLabel.textAlignment = .center
        warningLabel.heightAnchor.constraint(equalToConstant: warningLabel.font.pointSize * 1.2).isActive = true

        //transaction fee
        transactionViewContainer.alpha = 0.0
        view.addSubview(transactionViewContainer)
        transactionViewContainer.translatesAutoresizingMaskIntoConstraints = false
        transactionViewContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        transactionViewContainer.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 12).isActive = true
        let transactionStackView = UIStackView()
        transactionStackView.translatesAutoresizingMaskIntoConstraints = false
        transactionViewContainer.addSubview(transactionStackView)
        transactionStackView.leftAnchor.constraint(equalTo: transactionViewContainer.leftAnchor).isActive = true
        transactionStackView.rightAnchor.constraint(equalTo: transactionViewContainer.rightAnchor).isActive = true
        transactionStackView.topAnchor.constraint(equalTo: transactionViewContainer.topAnchor).isActive = true
        transactionStackView.bottomAnchor.constraint(equalTo: transactionViewContainer.bottomAnchor).isActive = true
        transactionStackView.alignment = .center
        transactionStackView.axis = .vertical

        transactionFeeLabel.translatesAutoresizingMaskIntoConstraints = false
        transactionFeeLabel.font = Theme.shared.fonts.transactionFeeLabel
        transactionFeeLabel.textColor = Theme.shared.colors.transactionViewValueLabel

        let feeButton = TextButton()
        feeButton.translatesAutoresizingMaskIntoConstraints = false
        feeButton.setTitle(NSLocalizedString("Transaction Fee", comment: "Transaction view screen"), for: .normal)
        feeButton.setRightImage(Theme.shared.images.transactionFee!)
        feeButton.addTarget(self, action: #selector(feeButtonPressed), for: .touchUpInside)
        continueButton.variation = .disabled

        transactionStackView.addArrangedSubview(transactionFeeLabel)
        transactionStackView.addArrangedSubview(feeButton)
    }

    private func setupKeypad() {
        view.addSubview(keypadContainerStackView)
        keypadContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        keypadContainerStackView.axis = .vertical
        keypadContainerStackView.distribution = .equalSpacing
        keypadContainerStackView.backgroundColor = .clear
        keypadContainerStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        keypadContainerStackView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -41).isActive = true
        keypadContainerStackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        keypadContainerStackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true

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
            button.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.1).isActive = true

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
