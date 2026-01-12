import Foundation
import Combine

final class BridgeService {
    static let shared = BridgeService()
    
    private let apiService = BridgeAPIService.shared
    private let store = BridgeStore.shared
    
    private init() {}
    
    // MARK: - Configuration
    
    func fetchBridgeConfig() async throws {
        let params = try await apiService.getWrapTokenParams()
        await MainActor.run {
            store.config = BridgeConfig(
                coldWalletAddress: params.coldWalletAddress,
                wrapTokenFeePercentageBps: params.wrapTokenFeePercentageBps,
                unwrapTokenFeePercentageBps: 50 // Default, should come from API if available
            )
        }
    }
    
    // MARK: - Bridge to Ethereum (Wrap)
    
    func bridgeToEthereum(
        amount: String,
        ethAddress: String,
        amountAfterFee: String
    ) async throws {
        guard let config = store.config else {
            throw BridgeError.configNotLoaded
        }
        
        guard let tariAddress = try? Tari.mainWallet.address.components.fullRaw else {
            throw BridgeError.invalidTariAddress
        }
        
        // Convert amount to microXTM (6 decimals)
        let microXtmAmount = parseAmountToMicroXTM(amount)
        
        // Create transaction on backend
        let createResponse = try await apiService.createWrapTransaction(
            to: ethAddress,
            from: tariAddress,
            tokenAmount: String(microXtmAmount)
        )
        
        // Create ongoing transaction
        let ongoingTx = BridgeTransaction(
            id: UUID().uuidString,
            paymentId: createResponse.paymentId,
            destinationAddress: ethAddress,
            sourceAddress: tariAddress,
            tokenAmount: String(microXtmAmount),
            amountAfterFee: String(parseAmountToMicroXTM(amountAfterFee)),
            status: .pending,
            type: .wrap,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            transactionHash: nil,
            minedInBlockHeight: nil
        )
        
        await MainActor.run {
            store.ongoingTransaction = ongoingTx
        }
        
        // Send Tari transaction to cold wallet
        do {
            let coldWalletAddress = try TariAddress(base58: config.coldWalletAddress)
            let amountUInt64 = UInt64(microXtmAmount)
            let feePerGram = try Tari.mainWallet.feePerGramStats.feePerGram
            
            try Tari.mainWallet.transactions.send(
                toAddress: coldWalletAddress,
                amount: amountUInt64,
                feePerGram: feePerGram,
                paymentID: createResponse.paymentId
            )
            
            // Confirm tokens sent
            _ = try await apiService.updateTokensSent(paymentId: createResponse.paymentId)
            
            // Refresh transactions
            try await refreshTransactions()
            
        } catch {
            await MainActor.run {
                store.ongoingTransaction = nil
            }
            throw BridgeError.transactionFailed(error)
        }
    }
    
    // MARK: - Bridge to Tari (Unwrap)
    
    func bridgeToTari(
        amount: String,
        ethAddress: String,
        tariAddress: String
    ) async throws {
        // Check daily limit
        let limitResponse = try await apiService.getRemainingDailyLimit()
        let limitMicro = UInt64(limitResponse.remainingLimit) ?? 0
        let amountMicro = parseAmountToMicroXTM(amount)
        
        if amountMicro > limitMicro {
            await MainActor.run {
                store.exceededDailyLimit = true
            }
            throw BridgeError.dailyLimitExceeded
        }
        
        // Note: Unwrapping requires Ethereum wallet connection and smart contract interaction
        // This would need Web3 integration or WalletConnect
        // For now, we'll create a placeholder transaction
        let ongoingTx = BridgeTransaction(
            id: UUID().uuidString,
            paymentId: "",
            destinationAddress: tariAddress,
            sourceAddress: ethAddress,
            tokenAmount: String(amountMicro),
            amountAfterFee: String(amountMicro * 995 / 1000), // 0.5% fee
            status: .pending,
            type: .unwrap,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            transactionHash: nil,
            minedInBlockHeight: nil
        )
        
        await MainActor.run {
            store.ongoingTransaction = ongoingTx
        }
        
        // TODO: Implement Ethereum transaction signing and submission
        // This requires Web3 integration or WalletConnect
        throw BridgeError.notImplemented("Unwrap functionality requires Ethereum wallet integration")
    }
    
    // MARK: - Transaction History
    
    func refreshTransactions() async throws {
        guard let tariAddress = try? Tari.mainWallet.address.components.fullRaw else {
            throw BridgeError.invalidTariAddress
        }
        
        async let wrapTxs = apiService.getUserWrapTransactions(tariAddress: tariAddress)
        async let unwrapTxs = apiService.getUserUnwrapTransactions(tariAddress: tariAddress)
        
        let (wrapResult, unwrapResult) = try await (wrapTxs, unwrapTxs)
        
        await MainActor.run {
            store.wrapTransactions = wrapResult.transactions
            store.unwrapTransactions = unwrapResult.transactions
            
            // Update ongoing transaction if exists
            if let ongoing = store.ongoingTransaction {
                let allTxs = wrapResult.transactions + unwrapResult.transactions
                if let updated = allTxs.first(where: { $0.paymentId == ongoing.paymentId }) {
                    store.ongoingTransaction = updated
                }
            }
        }
    }
    
    // MARK: - Fee Calculation
    
    func calculateFees(amount: String, isWrap: Bool) -> BridgeFees {
        guard let config = store.config else {
            return BridgeFees(
                feeAmount: 0,
                amountAfterFee: 0,
                feePercentage: 0,
                isOverHighBridgeThreshold: false
            )
        }
        
        let amountDouble = Double(amount) ?? 0
        let feePercentageBps = isWrap ? config.wrapTokenFeePercentageBps : config.unwrapTokenFeePercentageBps
        let feePercentage = Double(feePercentageBps) / 100.0
        
        let feeAmount = amountDouble * feePercentage / 100.0
        let amountAfterFee = amountDouble - feeAmount
        let isOverHighBridgeThreshold = amountDouble > 100000 // HIGH_BRIDGE_THRESHOLD
        
        return BridgeFees(
            feeAmount: feeAmount,
            amountAfterFee: amountAfterFee,
            feePercentage: feePercentage,
            isOverHighBridgeThreshold: isOverHighBridgeThreshold
        )
    }
    
    // MARK: - Helper Methods
    
    private func parseAmountToMicroXTM(_ amount: String) -> UInt64 {
        let cleaned = amount.replacingOccurrences(of: ",", with: "")
        guard let amountDouble = Double(cleaned) else { return 0 }
        return UInt64(amountDouble * 1_000_000) // Convert to microXTM (6 decimals)
    }
}

enum BridgeError: LocalizedError {
    case configNotLoaded
    case invalidTariAddress
    case transactionFailed(Error)
    case dailyLimitExceeded
    case notImplemented(String)
    
    var errorDescription: String? {
        switch self {
        case .configNotLoaded:
            return "Bridge configuration not loaded"
        case .invalidTariAddress:
            return "Invalid Tari address"
        case .transactionFailed(let error):
            return "Transaction failed: \(error.localizedDescription)"
        case .dailyLimitExceeded:
            return "Daily wrap limit exceeded"
        case .notImplemented(let message):
            return "Not implemented: \(message)"
        }
    }
}
