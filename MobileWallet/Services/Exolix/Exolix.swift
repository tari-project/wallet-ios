
import Foundation

@globalActor actor ExolixActor: GlobalActor {
    static let shared = ExolixActor()
}

final class Exolix {
    private let baseURL = URL(string: "https://exolix.com/api/v2")!
    private let session: URLSession = .shared
    private let apiKey: String?
    
    init() {
        self.apiKey = AppSecret.load()?.exolixApiKey
    }
}

@ExolixActor
extension Exolix {
    func getXtmCurrency() async throws -> ExolixCurrency? {
        try await getCurrencies(page: 1, size: 1, filter: "xtm").currencies.first
    }
    
    func getXtmNetwork() async throws -> ExolixNetwork? {
        try await request("/currencies/xtm/networks", as: [ExolixNetwork].self).first(where: \.isDefault)
    }
    
    func getCurrencies(page: Int, size: Int, filter: String? = nil) async throws -> ExolixCurrencyResponse {
        var query: [String: String] = ["page": "\(page)", "size": "\(size)", "withNetworks": "true"]
        if let filter, !filter.isEmpty { query["search"] = filter }
        return try await request("/currencies", as: ExolixCurrencyResponse.self, query: query)
    }
    
    func getRate(from: String, to: String, amount: String, rateType: ExolixRateType) async throws -> ExolixRate {
        try await request("/rate", as: ExolixRate.self, query: [
            "coinFrom": from, "coinTo": to, "amount": amount, "rateType": rateType.rawValue
        ])
    }
    
    func postTransaction(request: ExolixConfirmation, refundAddress: String?, refundExtraId: String?) async throws -> ExolixTransactionResponse {
        try await postTransaction(
            coinFrom: request.coinFrom.code,
            networkFrom: request.networkFrom.network,
            coinTo: request.coinTo.code,
            networkTo: request.networkTo.network,
            amount: request.amount.double ?? 0,
            withdrawalAmount: request.rate.toAmount,
            withdrawalAddress: request.withdrawalAddress,
            withdrawalExtraId: request.withdrawalExtraId,
            rateType: request.rateType,
            refundAddress: refundAddress,
            refundExtraId: refundExtraId
        )
    }
    
    func postTransaction(
        coinFrom: String,
        networkFrom: String,
        coinTo: String,
        networkTo: String,
        amount: Double,
        withdrawalAmount: Double?,
        withdrawalAddress: String,
        withdrawalExtraId: String?,
        rateType: ExolixRateType?,
        refundAddress: String?,
        refundExtraId: String?
    ) async throws -> ExolixTransactionResponse {
        try await request("/transactions", method: "POST", as: ExolixTransactionResponse.self, body: ExolixTransactionRequest(
            coinFrom: coinFrom,
            networkFrom: networkFrom,
            coinTo: coinTo,
            networkTo: networkTo,
            amount: amount,
            withdrawalAmount: withdrawalAmount,
            withdrawalAddress: withdrawalAddress,
            withdrawalExtraId: withdrawalExtraId,
            rateType: rateType,
            refundAddress: refundAddress,
            refundExtraId: refundExtraId
        ))
    }
    
    func getTransaction(id: String) async throws -> ExolixTransactionResponse {
        try await request("/transactions/\(id)", method: "GET", as: ExolixTransactionResponse.self)
    }
    
    func getActiveTransaction(id: String) async -> ExolixTransactionResponse? {
        let transaction = try? await getTransaction(id: id)
        return transaction?.isProcessed == false ? transaction : nil
    }
}

@ExolixActor
private extension Exolix {
    private func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        as type: T.Type,
        query: [String: String]? = nil,
        body: Encodable? = nil
    ) async throws -> T {
        var url = baseURL.appendingPathComponent(path)
        if let query, !query.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
            url = components?.url ?? url
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw ExolixError.unknown }
            guard (200..<300).contains(http.statusCode) else {
                if let error = try? JSONDecoder().decode(ExolixRateError.self, from: data) {
                    throw ExolixError.rate(error)
                }
                if let error = String(data: data, encoding: .utf8), !error.isEmpty {
                    throw ExolixError.api(error)
                }
                throw ExolixError.requestFailed(http.statusCode)
            }
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw ExolixError.decodingFailed(error)
            }
        } catch {
            if error is ExolixError { throw error }
            throw ExolixError.network(error)
        }
    }
}
