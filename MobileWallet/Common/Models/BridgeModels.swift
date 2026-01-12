import Foundation

// MARK: - Bridge Transaction Models

enum BridgeTransactionType: String, Codable {
    case wrap
    case unwrap
}

enum BridgeTransactionStatus: String, Codable {
    case pending = "PENDING"
    case processing = "PROCESSING"
    case tokensReceived = "TOKENS_RECEIVED"
    case success = "SUCCESS"
    case timeout = "TIMEOUT"
    case error = "ERROR"
}

struct BridgeTransaction: Codable, Identifiable {
    let id: String
    let paymentId: String
    let destinationAddress: String
    let sourceAddress: String?
    let tokenAmount: String // in microXTM
    let amountAfterFee: String // in microXTM
    let status: BridgeTransactionStatus
    let type: BridgeTransactionType
    let createdAt: String
    let transactionHash: String?
    let minedInBlockHeight: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case paymentId
        case destinationAddress
        case sourceAddress
        case tokenAmount
        case amountAfterFee
        case status
        case type
        case createdAt
        case transactionHash
        case minedInBlockHeight
    }
}

struct BridgeConfig: Codable {
    let coldWalletAddress: String
    let wrapTokenFeePercentageBps: Int
    let unwrapTokenFeePercentageBps: Int
}

struct BridgeFees {
    let feeAmount: Double
    let amountAfterFee: Double
    let feePercentage: Double
    let isOverHighBridgeThreshold: Bool
}

struct CreateWrapTransactionRequest: Codable {
    let to: String // Ethereum address
    let from: String // Tari address
    let tokenAmount: String // in microXTM
    let debug: String?
}

struct CreateWrapTransactionResponse: Codable {
    let paymentId: String
}

struct UpdateTokensSentRequest: Codable {
    let debug: String?
}

struct UpdateTokensSentResponse: Codable {
    let success: Bool
}

struct WrapTokenParamsResponse: Codable {
    let coldWalletAddress: String
    let wrapTokenFeePercentageBps: Int
}

struct UserTransactionsResponse: Codable {
    let transactions: [BridgeTransaction]
}

struct RemainingDailyLimitResponse: Codable {
    let remainingLimit: String // in microXTM
}

// MARK: - Bridge Store State

class BridgeStore: ObservableObject {
    @Published var config: BridgeConfig?
    @Published var wrapTransactions: [BridgeTransaction] = []
    @Published var unwrapTransactions: [BridgeTransaction] = []
    @Published var ongoingTransaction: BridgeTransaction?
    @Published var exceededDailyLimit: Bool = false
    
    var combinedTransactions: [BridgeTransaction] {
        (wrapTransactions + unwrapTransactions)
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    static let shared = BridgeStore()
    
    private init() {}
}
