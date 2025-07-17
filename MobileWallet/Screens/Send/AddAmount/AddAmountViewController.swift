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
    @TariView private var addressView = AddressView()
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

    @TariView var amountKeyboardView: AmountKeyboardView = {
        let view = AmountKeyboardView()
        view.setup(keys: .amountKeyboard)
        return view
    }()

    @TariView private var feeSpinnerView: AddAmountSpinnerView = AddAmountSpinnerView()

    @TariView private var txStackView: UIStackView = {
        let view = UIStackView()
        view.alpha = 0.0
        view.alignment = .center
        view.axis = .vertical
        return view
    }()

    @TariView private var feeButton: TextButton = {
        let view = TextButton()
        view.font = .Poppins.Medium.withSize(14.0)
        view.imageSpacing = 3.0
        view.image = .roundedQuestionMark
        return view
    }()

    var rawInput = ""
    private var txFeeIsVisible = false

    private let transactionFeesManager = TransactionFeesManager()
    private var feePerGram: MicroTari? { transactionFeesManager.feeData?.feePerGram }
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

        setupCallbacks()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        balanceCheckTimer?.invalidate()
        balanceCheckTimer = nil
    }

    private func displayAliasOrEmojiId() {
        do {
            guard let alias = try paymentInfo.alias ?? Tari.shared.wallet(.main).contacts.findContact(components: paymentInfo.addressComponents)?.alias else {
                let addressComponents = paymentInfo.addressComponents
                addressView.update(viewModel: AddressView.ViewModel(prefix: addressComponents.networkAndFeatures, text: .truncated(prefix: addressComponents.coreAddressPrefix, suffix: addressComponents.coreAddressSuffix), isDetailsButtonVisible: false))
                return
            }
            addressView.update(viewModel: AddressView.ViewModel(prefix: nil, text: .single(alias), isDetailsButtonVisible: false))
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

    override func update(theme: AppTheme) {
        super.update(theme: theme)
        mainView.backgroundColor = .Background.secondary
        warningView.layer.borderColor = theme.system.red?.cgColor
        walletBalanceTitleLabel.textColor = .Text.primary
        balanceExceededLabel.textColor = theme.system.red
        balancePendingLabel.textColor = theme.system.red

        updateAmountLabelColor(theme: theme)
        updateWalletBalanceViews(theme: theme)
    }

    private func updateAmountLabelColor(theme: AppTheme) {
        guard let attributedText = amountLabel.attributedText, let color = theme.text.heading else { return }

        let amountText = NSMutableAttributedString(attributedString: attributedText)
        amountText.addAttributes([.foregroundColor: color], range: NSRange(location: 0, length: amountText.length))

        amountLabel.attributedText = amountText
    }

    private func updateWalletBalanceViews(theme: AppTheme) {
        walletBalanceIcon.tintColor = isBalanceExceeded ? theme.system.red : theme.text.heading
        walletBalanceLabel.textColor = isBalanceExceeded ? theme.system.red : theme.text.heading
    }

    private func updateLabelText() {
        let font: UIFont = isSmallScreen ? .Poppins.Black.withSize(60.0) : .Poppins.Black.withSize(90.0)

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
        let model = PopUpDialogModel(
            title: localized("common.fee_info.title"),
            message: localized("common.fee_info.description"),
            buttons: [
                PopUpDialogButtonModel(title: localized("common.close"), type: .text)
            ],
            hapticType: .none
        )
        PopUpPresenter.showPopUp(model: model)
    }

    private func showBalanceExceeded(balance: String) {
        UINotificationFeedbackGenerator().notificationOccurred(.error)

        warningView.layer.borderWidth = 1
        walletBalanceLabel.text = balance
        walletBalanceTitleLabel.isHidden = true

        isBalanceExceeded = true
        updateWalletBalanceViews(theme: theme)
    }

    private func showAvailableBalance() {
        let availableBalance = Tari.shared.wallet(.main).walletBalance.balance.available

        walletBalanceStackView.isHidden = false
        warningView.isHidden = false
        warningView.layer.borderWidth = 0
        walletBalanceLabel.text = MicroTari(availableBalance).formatted
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
            guard let self else { return }
            self.txViewContainer.alpha = 1.0
            self.txViewContainer.layer.add(moveAnimation, forKey: CATransitionType.push.rawValue)
        }
        self.txFeeIsVisible = true
    }

    private func hideTxFee() {
        UIView.animate(withDuration: animationDuration) { [weak self] in
            guard let self else { return }
            self.txViewContainer.alpha = 0.0
        }
        self.txFeeIsVisible = false
    }

    @objc private func continueButtonTapped() {
        guard let fetchedPaymentInfo = updatedPaymentInfo() else { return }
        
        let controller = ConfirmationViewController(paymentInfo: fetchedPaymentInfo)
        self.navigationController?.pushViewController(controller, animated: true)
    }

    private func calculateAmount() -> MicroTari? {
        let availableBalance = Tari.mainWallet.walletBalance.balance.available
        var tariAmount: MicroTari?

        do {
            tariAmount = try MicroTari(tariValue: rawInput)
        } catch {
            showInvalidNumberError(error)
        }

        guard let amount = tariAmount else { return nil }

        let fee: UInt64
        do {
            fee = try Tari.mainWallet.fees.estimateFee(amount: amount.rawValue)
        } catch {
            return nil
        }

        if amount.rawValue + fee > availableBalance {
            PopUpPresenter.show(message: MessageModel(
                title: localized("add_amount.info.wait_completion_previous_tx.title"),
                message: String(format: localized("add_amount.info.wait_completion_previous_tx.description"), NetworkManager.shared.currencySymbol),
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
    }

    private func updateFeeButtonText(fee: MicroTari?) {
        let text = if let fee {
            "+ \(fee.formattedPrecise) \(localized("common.fee"))"
        } else {
            "+ \(localized("common.fee"))"
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
        navigationBar.onBackButtonAction = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }

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

        if paymentInfo.note != nil {
            continueButton.setTitle(localized("common.send.with_param", arguments: NetworkManager.shared.selectedNetwork.tickerSymbol), for: .normal)
        }else {
            continueButton.setTitle(localized("common.continue"), for: .normal)
        }
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
        amountContainer.bottomAnchor.constraint(equalTo: amountKeyboardView.topAnchor, constant: -40).isActive = true

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
        walletBalanceLabel.font = .Poppins.Bold.withSize(14.0)
        walletBalanceLabel.text = "0.0"

        warningStackView.addArrangedSubview(walletBalanceTitleLabel)
        walletBalanceTitleLabel.font = Theme.shared.fonts.amountWarningLabel
        walletBalanceTitleLabel.text = localized("common.available_balance")
        walletBalanceTitleLabel.numberOfLines = 1
        walletBalanceTitleLabel.textAlignment = .center

        warningStackView.addArrangedSubview(balanceExceededLabel)
        balanceExceededLabel.font = Theme.shared.fonts.amountWarningLabel
        balanceExceededLabel.text = String(format: localized("add_amount.warning.not_enough_tari"), NetworkManager.shared.currencySymbol)
        balanceExceededLabel.numberOfLines = 0
        balanceExceededLabel.textAlignment = .center
        balanceExceededLabel.lineBreakMode = .byWordWrapping

        warningStackView.addArrangedSubview(balancePendingLabel)
        balancePendingLabel.font = Theme.shared.fonts.amountWarningLabel
        balancePendingLabel.numberOfLines = 0
        balancePendingLabel.textAlignment = .center
        balancePendingLabel.lineBreakMode = .byWordWrapping
        balancePendingLabel.text = String(format: localized("add_amount.info.wait_completion_previous_tx.description"), NetworkManager.shared.currencySymbol)
        balancePendingLabel.sizeToFit()

        // tx fee
        txViewContainer.alpha = 0.0
        mainView.addSubview(txViewContainer)
        txViewContainer.translatesAutoresizingMaskIntoConstraints = false
        txViewContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        txViewContainer.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: -20).isActive = true

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

        txStackView.addArrangedSubview(feeButton)
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

    private func setupCallbacks() {
        feeButton.onTap = { [weak self] in
            self?.showTransactionFeeInfo()
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
        case let .data(feeData):
            fee = feeData.fee
            updateTransactionViews(isDataVisible: true)
        case .dataUnavailable:
            fee = nil
            updateTransactionViews(isDataVisible: true)
        }
    }

    private func fetchTotalBalance() -> MicroTari? {
        MicroTari(Tari.mainWallet.walletBalance.balance.available)
    }
}
