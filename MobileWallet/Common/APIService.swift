import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case refreshTokenExpired
    case unknown
}

final class API {
    static let service = API()
    private let baseURL = "https://airdrop.tari.com/api"

    private init() {}
    
    func minerStats() async -> MinerStats? {
        await request(endpoint: "/miner/stats")
    }
    
    func minerStatus(appId: String) async -> MiningStatus? {
        await request(endpoint: "/miner/status/\(appId)")
    }
    
    func request<T: Decodable>(endpoint: String, method: String = "GET", body: Data? = nil) async -> T? {
        do {
            let request = try urlRequest(endpoint: endpoint, method: method, body: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            try process(data: data, response: response, endpoint: endpoint)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            if case APIError.unauthorized = error {
                do {
                    try await refreshToken()
                    return await request(endpoint: endpoint, method: method, body: body)
                } catch {
                    log(error)
                }
            }
            log(error)
            return nil
        }
    }
    
    // TODO: Remove Publisher once async implementation is finalised
    func request<T: Decodable>(endpoint: String, method: String = "GET", body: Data? = nil) -> AnyPublisher<T, Error> {
        do {
            let request = try urlRequest(endpoint: endpoint, method: method, body: body)
            return URLSession.shared.dataTaskPublisher(for: request).tryMap { data, response in
                try self.process(data: data, response: response, endpoint: endpoint)
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .catch { error -> AnyPublisher<T, Error> in
                if case APIError.unauthorized = error {
                    return self.refreshTokenPublisher()
                        .flatMap { _ in
                            self.request(endpoint: endpoint, method: method, body: body)
                        }
                        .eraseToAnyPublisher()
                }
                return Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
}

private extension API {
    struct TokenResponse: Decodable {
        let accessToken: String
        let refreshToken: String?
    }
    
    func urlRequest(endpoint: String, method: String, body: Data?) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let accessToken = UserManager.shared.accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            request.httpBody = body
        }
        return request
    }
    
    func process(data: Data, response: URLResponse, endpoint: String) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        if let responseString = String(data: data, encoding: .utf8) {
            print("API Response for \(endpoint): \(responseString)")
        }
    }
    
    func refreshToken() async throws {
        guard let refreshToken = UserManager.shared.refreshToken else {
            UserManager.shared.clearTokens()
            throw APIError.refreshTokenExpired
        }
        guard let request = refreshTokenRequest(token: refreshToken) else {
            throw APIError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        try processRefreshToken(data: data, response: response)
    }
    
    // TODO: Remove Publisher once async implementation is finalised
    func refreshTokenPublisher() -> AnyPublisher<Void, Error> {
        guard let refreshToken = UserManager.shared.refreshToken else {
            UserManager.shared.clearTokens()
            return Fail(error: APIError.refreshTokenExpired).eraseToAnyPublisher()
        }
        guard let request = refreshTokenRequest(token: refreshToken) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                try self.processRefreshToken(data: data, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    func refreshTokenRequest(token: String) -> URLRequest? {
        guard let url = URL(string: "\(baseURL)/auth/local/refresh") else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    func processRefreshToken(data: Data, response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        if httpResponse.statusCode == 401 {
            UserManager.shared.clearTokens()
            throw APIError.refreshTokenExpired
        }
        guard httpResponse.statusCode == 200 else {
            throw APIError.unknown
        }
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        UserManager.shared.accessToken = tokenResponse.accessToken
        if let newRefreshToken = tokenResponse.refreshToken {
            UserManager.shared.refreshToken = newRefreshToken
        }
    }
    
    func log(_ error: Error) {
        print("Network error: " + error.localizedDescription)
    }
}
