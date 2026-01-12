import Foundation

final class BridgeAPIService {
    static let shared = BridgeAPIService()
    
    private var baseURL: String {
        // This should be configured from environment settings
        return TariSettings.shared.bridgeAPIURL ?? "https://bridge-api.tari.com"
    }
    
    private init() {}
    
    // MARK: - Wrap Token Operations
    
    func createWrapTransaction(
        to ethAddress: String,
        from tariAddress: String,
        tokenAmount: String,
        debug: String? = nil
    ) async throws -> CreateWrapTransactionResponse {
        let requestBody = CreateWrapTransactionRequest(
            to: ethAddress,
            from: tariAddress,
            tokenAmount: tokenAmount,
            debug: debug
        )
        
        let bodyData = try JSONEncoder().encode(requestBody)
        return try await request(
            endpoint: "/api/wrap-token/transaction",
            method: "POST",
            body: bodyData
        )
    }
    
    func updateTokensSent(
        paymentId: String,
        debug: String? = nil
    ) async throws -> UpdateTokensSentResponse {
        let requestBody = UpdateTokensSentRequest(debug: debug)
        
        let bodyData = try JSONEncoder().encode(requestBody)
        return try await request(
            endpoint: "/api/wrap-token/transaction/\(paymentId)/tokens-sent",
            method: "PUT",
            body: bodyData
        )
    }
    
    func getWrapTokenParams() async throws -> WrapTokenParamsResponse {
        return try await request(
            endpoint: "/api/wrap-token/params",
            method: "GET"
        )
    }
    
    func getUserWrapTransactions(tariAddress: String) async throws -> UserTransactionsResponse {
        return try await request(
            endpoint: "/api/wrap-token/transactions/\(tariAddress)",
            method: "GET"
        )
    }
    
    // MARK: - Unwrap Token Operations
    
    func getUserUnwrapTransactions(tariAddress: String) async throws -> UserTransactionsResponse {
        return try await request(
            endpoint: "/api/tokens-unwrapped/transactions/\(tariAddress)",
            method: "GET"
        )
    }
    
    func getRemainingDailyLimit() async throws -> RemainingDailyLimitResponse {
        return try await request(
            endpoint: "/api/tokens-unwrapped/daily-limit",
            method: "GET"
        )
    }
    
    // MARK: - Network Request
    
    private func request<T: Decodable>(
        endpoint: String,
        method: String,
        body: Data?
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw BridgeAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BridgeAPIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 403 {
                throw BridgeAPIError.dailyLimitExceeded
            }
            throw BridgeAPIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw BridgeAPIError.decodingError(error)
        }
    }
    
    private func request<T: Decodable>(
        endpoint: String,
        method: String
    ) async throws -> T {
        try await request(endpoint: endpoint, method: method, body: nil as Data?)
    }
}

enum BridgeAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case dailyLimitExceeded
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .dailyLimitExceeded:
            return "Daily wrap limit exceeded"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}
