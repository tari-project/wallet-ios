import SwiftUI

struct Bridge: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var store = BridgeStore.shared
    private let bridgeService = BridgeService.shared
    
    @State private var amount: String = ""
    @State private var ethAddress: String = ""
    @State private var amountError: String?
    @State private var addressError: String?
    @State private var isWrapping = true // true = wrap (Tari -> Ethereum), false = unwrap
    @State private var isProcessing = false
    @State private var showConfirmation = false
    @State private var showHistory = false
    @State private var availableBalance: MicroTari?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    networkToggle
                    Divider()
                    if isWrapping {
                        wrapSection
                    } else {
                        unwrapSection
                    }
                    if store.exceededDailyLimit {
                        dailyLimitWarning
                    }
                }
                .padding(16)
            }
            .sceneBackground(.secondaryBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarTitle("Bridge")
                toolbarBackItem { dismiss() }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showHistory.toggle() }) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                TariButton(
                    isWrapping ? "Bridge to Ethereum" : "Bridge to Tari",
                    style: .primary,
                    size: .large
                ) {
                    confirmBridge()
                }
                .disabled(!isContinueEnabled || isProcessing)
                .padding([.horizontal, .bottom], 16)
            }
            .sheet(isPresented: $showHistory) {
                BridgeHistory()
            }
            .onFirstAppear {
                loadData()
            }
            .onReceive(Tari.mainWallet.walletBalance.$balance) {
                availableBalance = $0.available
            }
        }
    }
    
    private var networkToggle: some View {
        HStack {
            Button(action: { isWrapping = true }) {
                VStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(isWrapping ? .tari.purple : .gray)
                    Text("Tari → Ethereum")
                        .font(.caption)
                        .foregroundColor(isWrapping ? .primary : .secondary)
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button(action: { isWrapping = false }) {
                VStack {
                    Image(systemName: "arrow.left.circle.fill")
                        .foregroundColor(!isWrapping ? .tari.purple : .gray)
                    Text("Ethereum → Tari")
                        .font(.caption)
                        .foregroundColor(!isWrapping ? .primary : .secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.primary.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var wrapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amount (XTM)")
                .font(.headline)
            
            TextField("0.00", text: $amount)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .onChange(of: amount) { validateAmount() }
            
            if let error = amountError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if let fees = bridgeService.calculateFees(amount: amount, isWrap: true), amount.isEmpty == false {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fee: \(String(format: "%.6f", fees.feeAmount)) XTM (\(String(format: "%.2f", fees.feePercentage))%)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("You'll receive: \(String(format: "%.6f", fees.amountAfterFee)) XTM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            Text("Ethereum Address")
                .font(.headline)
            
            TextField("0x...", text: $ethAddress)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .onChange(of: ethAddress) { validateAddress() }
            
            if let error = addressError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var unwrapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amount (wXTM)")
                .font(.headline)
            
            TextField("0.00", text: $amount)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .onChange(of: amount) { validateAmount() }
            
            if let error = amountError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Text("Note: Unwrapping requires connecting an Ethereum wallet")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }
    
    private var dailyLimitWarning: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("Daily wrap limit exceeded. Please try again tomorrow.")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var isContinueEnabled: Bool {
        guard !amount.isEmpty, !ethAddress.isEmpty else { return false }
        guard amountError == nil, addressError == nil else { return false }
        return true
    }
    
    private func loadData() {
        Task {
            do {
                try await bridgeService.fetchBridgeConfig()
                try await bridgeService.refreshTransactions()
            } catch {
                print("Failed to load bridge data: \(error)")
            }
        }
    }
    
    private func validateAmount() {
        guard !amount.isEmpty else {
            amountError = nil
            return
        }
        
        let cleaned = amount.replacingOccurrences(of: ",", with: "")
        guard let amountDouble = Double(cleaned), amountDouble > 0 else {
            amountError = "Invalid amount"
            return
        }
        
        if isWrapping {
            if let balance = availableBalance {
                let amountMicro = UInt64(amountDouble * 1_000_000)
                if amountMicro > balance.rawValue {
                    amountError = "Insufficient balance"
                    return
                }
            }
        }
        
        amountError = nil
    }
    
    private func validateAddress() {
        guard !ethAddress.isEmpty else {
            addressError = nil
            return
        }
        
        if ethAddress.hasPrefix("0x") && ethAddress.count == 42 {
            addressError = nil
        } else {
            addressError = "Invalid Ethereum address"
        }
    }
    
    private func confirmBridge() {
        guard isContinueEnabled else { return }
        
        isProcessing = true
        
        Task {
            do {
                if isWrapping {
                    let fees = bridgeService.calculateFees(amount: amount, isWrap: true)
                    try await bridgeService.bridgeToEthereum(
                        amount: amount,
                        ethAddress: ethAddress,
                        amountAfterFee: String(fees.amountAfterFee)
                    )
                } else {
                    guard let tariAddress = try? Tari.mainWallet.address.components.fullRaw else {
                        throw BridgeError.invalidTariAddress
                    }
                    try await bridgeService.bridgeToTari(
                        amount: amount,
                        ethAddress: ethAddress,
                        tariAddress: tariAddress
                    )
                }
                
                await MainActor.run {
                    isProcessing = false
                    amount = ""
                    ethAddress = ""
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    if case BridgeError.dailyLimitExceeded = error {
                        store.exceededDailyLimit = true
                    }
                }
                print("Bridge error: \(error)")
            }
        }
    }
}
