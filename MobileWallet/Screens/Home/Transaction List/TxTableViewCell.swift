private func updateAmountLabel() {
    if let amount = model.amount {
        amountLabel.text = amount.formattedForTransactionList + " " + NetworkManager.shared.currencySymbol
    }
}
