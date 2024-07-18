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
import TariCommon
import Combine

final class AddAmountViewController: DynamicThemeViewController {

    private let paymentInfo: PaymentInfo

    private let navigationBar = NavigationBar()
    @View private var addressView = AddressView()
    private let continueButton = ActionButton()
    private let amountLabel = AnimatedBalanceLabel()
    private let warningView = UIView()
    private let balanceExceededLabel = UILabel()
    private let balancePendingLabel = UILabel()
    private let walletBalanceIcon = UIImageView(image: Theme.shared.images.currencySymbol)
    private let walletBalanceLabel = UILabel()
    private let walletBalanceTitleLabel = UILabel()
    private let walletBalanceStackView = UIStackView()
    private let txViewContainer = UIView()
    private let animationDuration = 0.2
    private var balanceCheckTimer: Timer?
    private let gemImageString: NSAttributedString = {
        let gemAttachment = NSTextAttachment()
        gemAttachment.image = Theme.shared.images.currencySymbol
        gemAttachment.bounds = CGRect(x: 0, y: 0, width: 21, height: 21)
        return NSAttributedString(attachment: gemAttachment)
    }()

    private let isSmallScreen: Bool = UIScreen.main.nativeBounds.height <= 1334.0

    @View var amountKeyboardView: AmountKeyboardView = {
        let view = AmountKeyboardView()
        view.setup(keys: .amountKeyboard)
        return view
    }()

    @View private var feeSpinnerView: AddAmountSpinnerView = AddAmountSpinnerView()

    @View private var txStackView: UIStackView = {
        let view = UIStackView()
        view.alpha = 0.0
        view.alignment = .center
        view.axis = .vertical
        return view
    }()

    @View private var networkTrafficView = NetworkTrafficView()

    @View private var feeButton: TextButton = {
        let view = TextButton()
        view.font = .Avenir.medium.withSize(14.0)
        view.imageSpacing = 3.0
        view.image = .Icons.General.roundedQuestionMark
        return view
    }()

    @View private var modifyFeeButton: TextButton = {
        let view = TextButton()
        view.font = .Avenir.medium.withSize(14.0)
        view.setTitle(localized("add_amount.label.button.adjust_fee"), for: .normal)
        view.setContentHuggingPriority(.required, for: .vertical)
        return view
    }()

    @View private var oneSidedPaymentLabel: UILabel = {
        let view = UILabel()
        view.text = localized("add_amount.label.one_sided_payment")
        view.font = .Avenir.medium.withSize(16.0)
        return view
    }()

    @View private var oneSidedPaymentSwitch = UISwitch()

    @View private var oneSidedPaymentHelpButton: BaseButton = {
        let view = BaseButton()
        view.setImage(.Icons.General.roundedQuestionMark, for: .normal)
        return view
    }()

    @View private var oneSidedPaymentStackView: UIStackView = {
        let view = UIStackView()
        view.spacing = 18.0
        view.alignment = .center
        return view
    }()

    @View private var sliderBar: SlideView = {
        let view = SlideView()
        view.showSliderText = true
        view.labelText = localized("add_note.slide_to_send")
        view.variation = .slide
        view.alpha = 0.0
        return view
    }()

    var rawInput = ""
    private var txFeeIsVisible = false

    private let transactionFeesManager = TransactionFeesManager()
    private var selectedFeeIndex = 1 {
        didSet { updateFee(selectedIndex: selectedFeeIndex) }
    }
    private var feePerGram: MicroTari? { transactionFeesManager.feesData?.feesPerGram.fee(forIndex: selectedFeeIndex) }
    @Published private var fee: MicroTari?

    private var isBalanceExceeded = false
    private var cancellables = Set<AnyCancellable>()

    init(paymentInfo: PaymentInfo) {
        self.paymentInfo = paymentInfo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        displayAliasOrEmojiId()
        updateLabelText()
        showAvailableBalance()

        if let amount = paymentInfo.amount, amount.isGreaterThanZero {
            addCharacter(amount.formattedPrecise)
        }

        setupOneSidedPaymentElements()
        setupSliderBar()
        setupCallbacks()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        balanceCheckTimer?.invalidate()
        balanceCheckTimer = nil
    }

    private func displayAliasOrEmojiId() {
        do {
            guard let alias = try paymentInfo.alias ?? Tari.shared.contacts.findContact(uniqueIdentifier: paymentInfo.addressComponents.uniqueIdentifier)?.alias else {
                let addressComponents = paymentInfo.addressComponents
                addressView.update(viewModel: AddressView.ViewModel(prefix: addressComponents.networkAndFeatures, text: .truncated(prefix: addressComponents.spendKeyPrefix, suffix: addressComponents.spendKeySuffix), isDetailsButtonVisible: true))
                return
            }
            addressView.update(viewModel: AddressView.ViewModel(prefix: nil, text: .single(alias), isDetailsButtonVisible: true))
        } catch {
            PopUpPresenter.show(message: MessageModel(title: localized("navigation_bar.error.show_emoji.title"), message: localized("navigation_bar.error.show_emoji.description"), type: .error))
        }
    }

    @objc private func checkAvailableBalance() {
        let microTariAmount: MicroTari

        do {
            microTariAmount = try MicroTari(tariValue: rawInput)
        } catch {
            updateNextStepElements(isEnabled: false)
            showInvalidNumberError(error)
            return
        }

        transactionFeesManager.amount = microTariAmount

        guard let totalBalance = fetchTotalBalance() else { return }

        let fee = fee ?? MicroTari()

        if totalBalance.rawValue < (microTariAmount.rawValue + fee.rawValue) {
            balanceExceededLabel.isHidden = false
            balancePendingLabel.isHidden = true
            showBalanceExceeded(balance: totalBalance.formatted)
            walletBalanceStackView.isHidden = false
            updateNextStepElements(isEnabled: false)
        } else {
            showAvailableBalance()
            updateNextStepElements(isEnabled: true)
        }
        showTxFee(fee)
    }

    // Shouldn't ever really be used but just in case
    private func showInvalidNumberError(_ error: Error?) {
        PopUpPresenter.show(message: MessageModel(title: localized("add_amount.error.invalid_number"), message: nil, type: .error))
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

        if numberOfDecimals(in: updatedText) > MicroTari.maxFractionDigits {
            return
        }

        if MicroTari.checkValue(updatedText) {
            rawInput = updatedText
            updateLabelText()
        }
    }

    override func update(theme: ColorTheme) {
        super.update(theme: theme)
        mainView.backgroundColor = theme.backgrounds.primary
        oneSidedPaymentLabel.textColor = theme.text.heading
        oneSidedPaymentSwitch.onTintColor = theme.brand.purple
        oneSidedPaymentHelpButton.tintColor = theme.text.body
        warningView.layer.borderColor = theme.system.red?.cgColor
        walletBalanceTitleLabel.textColor = theme.text.body
        balanceExceededLabel.textColor = theme.system.red
        balancePendingLabel.textColor = theme.system.red

        updateAmountLabelColor(theme: theme)
        updateWalletBalanceViews(theme: theme)
    }

    private func updateAmountLabelColor(theme: ColorTheme) {

        guard let attributedText = amountLabel.attributedText, let color = theme.text.heading else { return }

        let amountText = NSMutableAttributedString(attributedString: attributedText)
        amountText.addAttributes([.foregroundColor: color], range: NSRange(location: 0, length: amountText.length))

        amountLabel.attributedText = amountText
    }

    private func updateWalletBalanceViews(theme: ColorTheme) {
        walletBalanceIcon.tintColor = isBalanceExceeded ? theme.system.red : theme.text.heading
        walletBalanceLabel.textColor = isBalanceExceeded ? theme.system.red : theme.text.heading
    }

    private func updateLabelText() {

        let font: UIFont = isSmallScreen ? .Avenir.black.withSize(60.0) : .Avenir.black.withSize(90.0)

        let amountAttributedText = NSMutableAttributedString(
            string: convertRawToFormattedString() ?? "0",
            attributes: [.font: font ]
        )

        amountAttributedText.insert(gemImageString, at: 0)
        amountAttributedText.insert(NSAttributedString(string: "  "), at: 1)
        amountLabel.attributedText = amountAttributedText
        updateAmountLabelColor(theme: theme)

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
            showAvailableBalance()
            updateNextStepElements(isEnabled: false)
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

        guard numberOfDecimals(in: string) <= MicroTari.maxFractionDigits else {
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

        guard let formattedNumberString = MicroTari.convertToString(
                number,
                minimumFractionDigits: numberOfDecimals(in: decimalRemovedIfAtEndRawInput)
        ) else {
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

    private func showTransactionFeeInfo() {
        PopUpPresenter.show(message: MessageModel(title: localized("common.fee_info.title"), message: localized("common.fee_info.description"), type: .normal))
    }

    private func showBalanceExceeded(balance: String) {
        UINotificationFeedbackGenerator().notificationOccurred(.error)

        warningView.layer.borderWidth = 1
        walletBalanceLabel.text = balance
        walletBalanceTitleLabel.isHidden = true

        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = animationDuration / 4
        animation.repeatCount = 2
        animation.autoreverses = true
        animation.fromValue = CGPoint(x: amountLabel.center.x - 10, y: amountLabel.center.y)
        animation.toValue = CGPoint(x: amountLabel.center.x + 10, y: amountLabel.center.y)
        amountLabel.layer.add(animation, forKey: "position")

        isBalanceExceeded = true
        updateWalletBalanceViews(theme: theme)
    }

    private func showAvailableBalance() {

        let totalBalance = Tari.shared.walletBalance.balance.total

        walletBalanceStackView.isHidden = false
        warningView.isHidden = false
        warningView.layer.borderWidth = 0
        walletBalanceLabel.text = MicroTari(totalBalance).formatted
        balanceExceededLabel.isHidden = true
        balancePendingLabel.isHidden = true
        walletBalanceTitleLabel.isHidden = false

        isBalanceExceeded = false
        updateWalletBalanceViews(theme: theme)
    }

    private func showTxFee(_ fee: MicroTari) {
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
        guard let paymentInfo = updatedPaymentInfo() else { return }
        let controller = AddNoteViewController(paymentInfo: paymentInfo, isOneSidedPayment: oneSidedPaymentSwitch.isOn)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func calculateAmount() -> MicroTari? {

        let availableBalance = Tari.shared.walletBalance.balance.available
        var tariAmount: MicroTari?

        do {
            tariAmount = try MicroTari(tariValue: rawInput)
        } catch {
            showInvalidNumberError(error)
        }

        guard let amount = tariAmount else { return nil }

        let fee: UInt64
        do {
            fee = try Tari.shared.fees.estimateFee(amount: amount.rawValue)
        } catch {
            return nil
        }

        if amount.rawValue + fee > availableBalance {
            PopUpPresenter.show(message: MessageModel(
                title: localized("add_amount.info.wait_completion_previous_tx.title"),
                message: localized("add_amount.info.wait_completion_previous_tx.description"),
                type: .normal
            ))
            return nil
        }

        return amount
    }

    private func updatedPaymentInfo() -> PaymentInfo? {
        guard let amount = calculateAmount(), let feePerGram = feePerGram else { return nil }
        return PaymentInfo(addressComponents: paymentInfo.addressComponents, alias: paymentInfo.alias, yatID: paymentInfo.yatID, amount: amount, feePerGram: feePerGram, note: paymentInfo.note)
    }

    private func updateNextStepElements(isEnabled: Bool) {
        continueButton.isEnabled = isEnabled
        sliderBar.isEnabled = isEnabled
    }

    private func showTransactionProgress() {
        guard let paymentInfo = updatedPaymentInfo() else { return }
        TransactionProgressPresenter.showTransactionProgress(presenter: self, paymentInfo: paymentInfo, isOneSidedPayment: oneSidedPaymentSwitch.isOn)
    }

    @objc private func onOneSidedPaymentSwitchAction() {
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.beginFromCurrentState]) {
            self.continueButton.alpha = self.oneSidedPaymentSwitch.isOn ? 0.0 : 1.0
            self.sliderBar.alpha = self.oneSidedPaymentSwitch.isOn ? 1.0 : 0.0
        }
    }

    private func updateFeeButtonText(fee: MicroTari?) {

        let text: String

        if let fee = fee {
            text = "+ \(fee.formattedPrecise) \(localized("common.fee"))"
        } else {
            text = "+ \(localized("common.fee"))"
        }

        feeButton.setTitle(text, for: .normal)
    }
}

extension AddAmountViewController {
    private func setup() {
        // navigationBar
        navigationBar.isSeparatorVisible = false
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(navigationBar)
        navigationBar.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        navigationBar.addSubview(addressView)
        
        addressView.centerXAnchor.constraint(equalTo: navigationBar.contentView.centerXAnchor).isActive = true
        addressView.centerYAnchor.constraint(equalTo: navigationBar.contentView.centerYAnchor).isActive = true

        // contiue button
        mainView.addSubview(continueButton)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.leftAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.leftAnchor,
            constant: Theme.shared.sizes.appSidePadding
        ).isActive = true
        continueButton.rightAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.rightAnchor,
            constant: -Theme.shared.sizes.appSidePadding
        ).isActive = true

        let continueButtonConstraint = continueButton.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -10
        )
        continueButtonConstraint.priority = UILayoutPriority(rawValue: 999)
        continueButtonConstraint.isActive = true

        let continueButtonSecondConstraint = continueButton.bottomAnchor.constraint(
            lessThanOrEqualTo: view.bottomAnchor,
            constant: -Theme.shared.sizes.appSidePadding
        )
        continueButtonSecondConstraint.priority = UILayoutPriority(rawValue: 1000)
        continueButtonSecondConstraint.isActive = true

        continueButton.setTitle(localized("common.continue"), for: .normal)
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        continueButton.isEnabled = false
        setupKeypad()

        // amount container
        let amountContainer = UIView()
        amountContainer.backgroundColor = .clear
        mainView.addSubview(amountContainer)
        amountContainer.translatesAutoresizingMaskIntoConstraints = false
        amountContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        amountContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        amountContainer.topAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
        amountContainer.bottomAnchor.constraint(equalTo: amountKeyboardView.topAnchor).isActive = true

        let amountHeight: CGFloat = isSmallScreen ? 50.0 : 75.0

        // amount label
        mainView.addSubview(amountLabel)
        amountLabel.animation = .type
        amountLabel.textAlignment = .center(inset: -30)
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.trailingAnchor.constraint(equalTo: amountContainer.trailingAnchor, constant: -25).isActive = true
        amountLabel.leadingAnchor.constraint(equalTo: amountContainer.leadingAnchor, constant: 25).isActive = true
        amountLabel.centerYAnchor.constraint(equalTo: amountContainer.centerYAnchor).isActive = true
        amountLabel.heightAnchor.constraint(equalToConstant: amountHeight).isActive = true

        // warning view
        mainView.addSubview(warningView)
        warningView.isHidden = true
        warningView.translatesAutoresizingMaskIntoConstraints = false
        warningView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -50).isActive = true
        warningView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        warningView.topAnchor.constraint(greaterThanOrEqualTo: navigationBar.bottomAnchor, constant: 5).isActive = true
        warningView.topAnchor.constraint(lessThanOrEqualTo: navigationBar.bottomAnchor, constant: 20).isActive = true
        warningView.bottomAnchor.constraint(lessThanOrEqualTo: amountLabel.topAnchor, constant: -5).isActive = true

        warningView.layer.cornerRadius = 12
        warningView.layer.masksToBounds = true
        warningView.layer.borderWidth = 0
        warningView.setContentCompressionResistancePriority(.required, for: .vertical)

        let warningStackView = UIStackView()
        warningView.addSubview(warningStackView)
        warningStackView.alignment = .center
        warningStackView.axis = .vertical
        warningStackView.spacing = 4
        warningStackView.translatesAutoresizingMaskIntoConstraints = false
        warningStackView.widthAnchor.constraint(greaterThanOrEqualTo: warningView.widthAnchor, constant: -16).isActive = true
        warningStackView.heightAnchor.constraint(equalTo: warningView.heightAnchor, constant: -26).isActive = true
        warningStackView.centerXAnchor.constraint(equalTo: warningView.centerXAnchor).isActive = true
        warningStackView.centerYAnchor.constraint(equalTo: warningView.centerYAnchor).isActive = true

        walletBalanceStackView.alignment = .center
        warningStackView.addArrangedSubview(walletBalanceStackView)
        walletBalanceStackView.spacing = 4
        walletBalanceIcon.translatesAutoresizingMaskIntoConstraints = false
        walletBalanceIcon.widthAnchor.constraint(equalToConstant: 11).isActive = true
        walletBalanceIcon.heightAnchor.constraint(equalToConstant: 11).isActive = true
        walletBalanceIcon.contentMode = .scaleAspectFit
        walletBalanceStackView.addArrangedSubview(walletBalanceIcon)
        walletBalanceStackView.addArrangedSubview(walletBalanceLabel)
        walletBalanceLabel.font = .Avenir.heavy.withSize(14.0)
        walletBalanceLabel.text = "0.0"

        warningStackView.addArrangedSubview(walletBalanceTitleLabel)
        walletBalanceTitleLabel.font = Theme.shared.fonts.amountWarningLabel
        walletBalanceTitleLabel.text = localized("common.wallet_balance")
        walletBalanceTitleLabel.numberOfLines = 1
        walletBalanceTitleLabel.textAlignment = .center

        warningStackView.addArrangedSubview(balanceExceededLabel)
        balanceExceededLabel.font = Theme.shared.fonts.amountWarningLabel
        balanceExceededLabel.text = localized("add_amount.warning.not_enough_tari")
        balanceExceededLabel.numberOfLines = 0
        balanceExceededLabel.textAlignment = .center
        balanceExceededLabel.lineBreakMode = .byWordWrapping

        warningStackView.addArrangedSubview(balancePendingLabel)
        balancePendingLabel.font = Theme.shared.fonts.amountWarningLabel
        balancePendingLabel.numberOfLines = 0
        balancePendingLabel.textAlignment = .center
        balancePendingLabel.lineBreakMode = .byWordWrapping
        balancePendingLabel.text = localized("add_amount.info.wait_completion_previous_tx.description")
        balancePendingLabel.sizeToFit()

        // tx fee
        txViewContainer.alpha = 0.0
        mainView.addSubview(txViewContainer)
        txViewContainer.translatesAutoresizingMaskIntoConstraints = false
        txViewContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        txViewContainer.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 12).isActive = true

        txStackView.spacing = isSmallScreen ? 0.0 : 3.0

        [txStackView, feeSpinnerView]
            .forEach {
                txViewContainer.addSubview($0)
                $0.leftAnchor.constraint(equalTo: txViewContainer.leftAnchor).isActive = true
                $0.rightAnchor.constraint(equalTo: txViewContainer.rightAnchor).isActive = true
                $0.topAnchor.constraint(equalTo: txViewContainer.topAnchor).isActive = true
                $0.bottomAnchor.constraint(equalTo: txViewContainer.bottomAnchor).isActive = true
            }

        updateNextStepElements(isEnabled: false)

        [networkTrafficView, feeButton, modifyFeeButton].forEach(txStackView.addArrangedSubview)
    }

    private func setupKeypad() {
        mainView.addSubview(amountKeyboardView)

        let constraints = [
            amountKeyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            amountKeyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]

        NSLayoutConstraint.activate(constraints)

        amountKeyboardView.onKeyTap = { [weak self] in
            switch $0 {
            case let .key(character):
                self?.addCharacter(character)
            case .delete:
                self?.deleteCharacter()
            }
        }
    }

    private func setupOneSidedPaymentElements() {

        oneSidedPaymentLabel.minimumScaleFactor = 0.5
        oneSidedPaymentLabel.adjustsFontSizeToFitWidth = true

        mainView.addSubview(oneSidedPaymentStackView)
        [oneSidedPaymentLabel, oneSidedPaymentSwitch, oneSidedPaymentHelpButton].forEach(oneSidedPaymentStackView.addArrangedSubview)

        let margin = isSmallScreen ? 8.0 : 20.0

        let constraints = [
            oneSidedPaymentStackView.topAnchor.constraint(equalTo: amountKeyboardView.bottomAnchor, constant: margin),
            oneSidedPaymentStackView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -margin),
            oneSidedPaymentStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            oneSidedPaymentHelpButton.heightAnchor.constraint(equalToConstant: 44.0),
            oneSidedPaymentHelpButton.widthAnchor.constraint(equalToConstant: 44.0)
        ]

        NSLayoutConstraint.activate(constraints)

        oneSidedPaymentHelpButton.onTap = {
            PopUpPresenter.show(message: MessageModel(title: localized("add_amount.pop_up.one_sided_payment.title"), message: localized("add_amount.pop_up.one_sided_payment.description"), type: .normal))
        }

        oneSidedPaymentSwitch.addTarget(self, action: #selector(onOneSidedPaymentSwitchAction), for: .valueChanged)
    }

    private func setupSliderBar() {

        mainView.addSubview(sliderBar)

        let constraints = [
            sliderBar.topAnchor.constraint(equalTo: continueButton.topAnchor),
            sliderBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25.0),
            sliderBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25.0)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupCallbacks() {

        feeButton.onTap = { [weak self] in
            self?.showTransactionFeeInfo()
        }

        modifyFeeButton.onTap = { [weak self] in
            self?.showModifyFeeDialog()
        }

        sliderBar.onSlideToEnd = { [weak self] in
            self?.showTransactionProgress()
        }

        addressView.onViewDetailsButtonTap = AddressViewDefaultActions.showDetailsAction(addressComponents: paymentInfo.addressComponents)

        $fee
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.updateFeeButtonText(fee: $0) }
            .store(in: &cancellables)

        transactionFeesManager.$feesStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(feeCalculationStatus: $0) }
            .store(in: &cancellables)

        transactionFeesManager.$lastError
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handle(error: $0) }
            .store(in: &cancellables)
    }

    private func updateTransactionViews(isDataVisible: Bool) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.feeSpinnerView.alpha = isDataVisible ? 0.0 : 1.0
            self?.txStackView.alpha = isDataVisible ? 1.0 : 0.0
        }
    }

    private func showModifyFeeDialog() {

        guard let fees = transactionFeesManager.feesData?.fees else { return }

        let headerSection = PopUpHeaderWithSubtitle()
        let contentSection = PopUpModifyFeeContentView()
        let buttonsSection = PopUpButtonsView()

        headerSection.titleLabel.text = localized("add_amount.pop_up.adjust_fee.title")
        headerSection.subtitleLabel.text = localized("add_amount.pop_up.adjust_fee.description")

        contentSection.segmentedControl.selectedIndex = selectedFeeIndex

        contentSection.segmentedControl.$selectedIndex
            .sink { [weak contentSection] in
                guard let index = $0 else { return }
                contentSection?.estimatedFee = fees.fee(forIndex: index)?.formattedPrecise
            }
            .store(in: &cancellables)

        buttonsSection.addButton(
            model: PopUpDialogButtonModel(
                title: localized("add_amount.pop_up.adjust_fee.button.approve"),
                type: .normal,
                callback: { [weak self] in
                    guard let index = contentSection.segmentedControl.selectedIndex, let fee = fees.fee(forIndex: index) else { return }
                    self?.selectedFeeIndex = index
                    self?.fee = fee
                    PopUpPresenter.dismissPopup()
                }
            )
        )
        buttonsSection.addButton(model: PopUpDialogButtonModel(title: localized("common.cancel"), type: .text, callback: { PopUpPresenter.dismissPopup() }))

        let popUp = TariPopUp(headerSection: headerSection, contentSection: contentSection, buttonsSection: buttonsSection)

        PopUpPresenter.show(popUp: popUp)
    }

    private func updateTransactionViews(networkTraffic: TransactionFeesManager.NetworkTraffic) {

        switch networkTraffic {
        case .low:
            networkTrafficView.variant = .lowTraffic
            networkTrafficView.alpha = 0.0
            modifyFeeButton.alpha = 0.0
        case .medium:
            networkTrafficView.variant = .mediumTraffic
            networkTrafficView.alpha = 1.0
            modifyFeeButton.alpha = 1.0
        case .high:
            networkTrafficView.variant = .highTraffic
            networkTrafficView.alpha = 1.0
            modifyFeeButton.alpha = 1.0
        case .unknown:
            networkTrafficView.alpha = 0.0
            modifyFeeButton.alpha = 0.0
        }
    }

    private func updateFee(selectedIndex: Int) {
        fee = transactionFeesManager.feesData?.fees.fee(forIndex: selectedIndex)
    }

    private func handle(error: Error) {

        switch error {
        case WalletError.notEnoughFunds:
            guard let totalBalance = fetchTotalBalance() else { return }
            balanceExceededLabel.isHidden = false
            balancePendingLabel.isHidden = true
            showBalanceExceeded(balance: totalBalance.formatted)
            walletBalanceStackView.isHidden = false
            updateNextStepElements(isEnabled: false)
        case WalletError.fundsPending:
            guard let totalBalance = fetchTotalBalance() else { return }
            balanceExceededLabel.isHidden = true
            balancePendingLabel.isHidden = false
            showBalanceExceeded(balance: totalBalance.formatted)
            walletBalanceStackView.isHidden = true
            updateNextStepElements(isEnabled: false)
        default:
            let message = ErrorMessageManager.errorModel(forError: error)
            PopUpPresenter.show(message: message)
            updateNextStepElements(isEnabled: false)
        }
    }

    private func handle(feeCalculationStatus: TransactionFeesManager.Status) {

        switch feeCalculationStatus {
        case .calculating:
            updateTransactionViews(isDataVisible: false)
        case let .data(feesData):
            fee = feesData.fees.fee(forIndex: selectedFeeIndex)
            updateTransactionViews(isDataVisible: true)
            updateTransactionViews(networkTraffic: feesData.networkTraffic)
        case .dataUnavailable:
            fee = nil
            updateTransactionViews(isDataVisible: true)
            updateTransactionViews(networkTraffic: .unknown)
        }
    }

    private func fetchTotalBalance() -> MicroTari? {
        let totalBalance = Tari.shared.walletBalance.balance.total
        return MicroTari(totalBalance)
    }
}

extension TransactionFeesManager.FeeOptions {

    func fee(forIndex index: Int) -> MicroTari? {

        switch index {
        case 0:
            return slow
        case 1:
            return medium
        case 2:
            return fast
        default:
            return nil
        }
    }
}
